from __future__ import annotations

import apache_beam as beam
from typing import Dict, Tuple, Any, cast
from apache_beam.transforms.userstate import ReadModifyWriteStateSpec
from apache_beam.coders import StrUtf8Coder
from typing import Protocol, TypeVar

T = TypeVar("T")


class ReadWriteState(Protocol[T]):
    def read(self) -> T | None: ...
    def write(self, value: T) -> None: ...


class DeduplicateDoFn(beam.DoFn):
    seen_state = ReadModifyWriteStateSpec("seen", StrUtf8Coder())

    def process(
        self, kv: Tuple[str, Dict[str, Any]], seen=beam.DoFn.StateParam(seen_state)
    ):  # type: ignore[override]
        key, event = kv
        seen = cast(ReadWriteState[str], seen)
        res = seen.read()
        if res == "1":
            return
        seen.write("1")

        yield event


def key_for_dedup(e: Dict[str, Any]) -> str:
    return f'{e["bucket"]}|{e["object"]}|{e.get("generation","")}'
