import time
import json
from typing import Any, Protocol, cast
import apache_beam as beam
from apache_beam.transforms.userstate import (
    ReadModifyWriteStateSpec,
    TimerSpec,
    on_timer,
    TimeDomain,
)
from apache_beam.coders import VarIntCoder, StrUtf8Coder
from google.cloud import storage


class _ReadWriteState(Protocol):
    def read(self) -> Any: ...
    def write(self, value: Any) -> None: ...


class _TimerParam(Protocol):
    def set(self, timestamp: float) -> None: ...


class WaitForFileStabilityDoFn(beam.DoFn):
    """
    Waits for files in a GCS prefix to become stable after _SUCCESS arrives.
    Works even if data files have no extension.
    """

    # state
    last_count = ReadModifyWriteStateSpec("last_count", VarIntCoder())
    last_size = ReadModifyWriteStateSpec("last_size", VarIntCoder())
    stable_rounds = ReadModifyWriteStateSpec("stable_rounds", VarIntCoder())
    saved_event = ReadModifyWriteStateSpec("saved_event_json", StrUtf8Coder())

    # processing-time timer (REAL_TIME)
    check_timer = TimerSpec("check_timer", TimeDomain.REAL_TIME)

    # names to ignore inside a partition folder
    _EXCLUDE_SUFFIXES = ("_SUCCESS", "_metadata", "_common_metadata")

    def __init__(
        self, project_id: str, poll_every_sec: int = 30, stable_needed: int = 2
    ):
        self.project_id = project_id
        self.poll_every_sec = poll_every_sec
        self.stable_needed = stable_needed
        self._storage_client: storage.Client

    def setup(self):
        self._storage_client = storage.Client(project=self.project_id)

    @classmethod
    def _is_data_blob_name(cls, name: str) -> bool:
        # ignore pseudo-directories
        if name.endswith("/"):
            return False
        # ignore marker/metadata files
        if name.endswith(cls._EXCLUDE_SUFFIXES):
            return False
        return True

    def _folder_stats(self, bucket: str, prefix: str) -> tuple[int, int]:
        """
        Count total number of data files and their total size in bytes under prefix.
        """
        b = self._storage_client.bucket(bucket)
        count = 0
        total_size = 0

        for blob in self._storage_client.list_blobs(b, prefix=prefix):
            if self._is_data_blob_name(blob.name):
                count += 1
                total_size += int(blob.size or 0)

        return count, total_size

    def process(
        self,
        kv,
        timer=beam.DoFn.TimerParam(check_timer),
        last_count_state=beam.DoFn.StateParam(last_count),
        last_size_state=beam.DoFn.StateParam(last_size),
        stable_state=beam.DoFn.StateParam(stable_rounds),
        saved_event_state=beam.DoFn.StateParam(saved_event),
    ):  # type: ignore[override]
        key, event = kv
        obj = event["object"]

        # Proceed only with completed data files
        if not obj.endswith("_SUCCESS"):
            return

        saved_event_state = cast(_ReadWriteState, saved_event_state)
        stable_state = cast(_ReadWriteState, stable_state)
        last_count_state = cast(_ReadWriteState, last_count_state)
        last_size_state = cast(_ReadWriteState, last_size_state)
        timer = cast(_TimerParam, timer)

        # _SUCCESS: store event + start periodic checks
        saved_event_state.write(json.dumps(event))

        stable_state.write(0)
        last_count_state.write(-1)
        last_size_state.write(-1)

        timer.set(time.time() + self.poll_every_sec)

    @on_timer(check_timer)
    def on_check(
        self,
        timer=beam.DoFn.TimerParam(check_timer),
        last_count_state=beam.DoFn.StateParam(last_count),
        last_size_state=beam.DoFn.StateParam(last_size),
        stable_state=beam.DoFn.StateParam(stable_rounds),
        saved_event_state=beam.DoFn.StateParam(saved_event),
    ):

        saved_event_state = cast(_ReadWriteState, saved_event_state)
        stable_state = cast(_ReadWriteState, stable_state)
        last_count_state = cast(_ReadWriteState, last_count_state)
        last_size_state = cast(_ReadWriteState, last_size_state)
        timer = cast(_TimerParam, timer)

        saved = saved_event_state.read()
        if not saved:
            return
        event = json.loads(saved)

        bucket = event["bucket"]
        prefix = event["prefix"]

        count, total_size = self._folder_stats(bucket, prefix)
        prev_count = last_count_state.read()
        prev_size = last_size_state.read()

        # stable if count and size repeat and there is at least one data file
        if count == prev_count and total_size == prev_size and count > 0:
            stable_state.write(stable_state.read() + 1)
        else:
            stable_state.write(0)

        last_count_state.write(count)
        last_size_state.write(total_size)

        if stable_state.read() >= self.stable_needed:
            # folder is ready: wildcard without extension
            event["folder_uri"] = f"gs://{bucket}/{prefix}*"
            event["ready_count"] = count
            event["ready_total_size"] = total_size
            yield event
            return

        # schedule next check
        timer.set(time.time() + self.poll_every_sec)
