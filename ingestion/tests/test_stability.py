from unittest.mock import MagicMock

import pytest

from ingestion.pipeline.stability import WaitForFileStabilityDoFn


@pytest.mark.unit
class TestStabilityUnit:
    """Unit tests for WaitForFileStabilityDoFn helpers (no GCS, no timer execution)."""

    @pytest.mark.parametrize(
        "name, expected",
        [
            ("stream/dt=2026-02-24/hour=1/part-0000", True),
            ("part-1", True),
            ("part-1.parquet", True),
            ("stream/", False),
            ("path/to/folder/", False),
            ("stream/dt=2026-02-24/hour=1/_SUCCESS", False),
            ("_SUCCESS", False),
            ("prefix/_metadata", False),
            ("prefix/_common_metadata", False),
            ("_metadata", False),
            ("_common_metadata", False),
        ],
    )
    def test_is_data_blob_name(self, name, expected):
        assert WaitForFileStabilityDoFn._is_data_blob_name(name) is expected

    def test_folder_stats_returns_count_and_size_with_mock_client(self):
        """_folder_stats counts only data blobs and sums size; excludes _SUCCESS and dirs."""

        def mock_blob(blob_name, blob_size):
            m = MagicMock()
            m.name = blob_name
            m.size = blob_size
            return m

        mock_blobs = [
            mock_blob("stream/dt=2026-02-24/hour=1/part-0", 100),
            mock_blob("stream/dt=2026-02-24/hour=1/part-1", 50),
            mock_blob("stream/dt=2026-02-24/hour=1/_SUCCESS", 0),
            mock_blob("stream/dt=2026-02-24/hour=1/", None),
        ]
        mock_bucket = MagicMock()
        mock_client = MagicMock()
        mock_client.bucket.return_value = mock_bucket
        mock_client.list_blobs.return_value = mock_blobs

        dofn = WaitForFileStabilityDoFn(
            project_id="test-project", poll_every_sec=30, stable_needed=2
        )
        dofn._storage_client = mock_client

        count, total_size = dofn._folder_stats(
            "my-bucket", "stream/dt=2026-02-24/hour=1/"
        )

        assert count == 2
        assert total_size == 150
        mock_client.list_blobs.assert_called_once_with(
            mock_bucket, prefix="stream/dt=2026-02-24/hour=1/"
        )

    def test_folder_stats_empty_prefix_returns_zero_with_mock(self):
        mock_client = MagicMock()
        mock_client.bucket.return_value = MagicMock()
        mock_client.list_blobs.return_value = []

        dofn = WaitForFileStabilityDoFn(
            project_id="test", poll_every_sec=30, stable_needed=2
        )
        dofn._storage_client = mock_client

        count, total_size = dofn._folder_stats("b", "empty/")

        assert count == 0
        assert total_size == 0
