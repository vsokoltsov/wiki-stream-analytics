from unittest.mock import MagicMock, patch

import pytest
import apache_beam as beam
from apache_beam.testing.util import assert_that, equal_to
from google.api_core.exceptions import BadRequest

from ingestion.pipeline.load import LoadFolderToBQDoFn

@pytest.mark.unit
class TestLoadUnit:
    """Unit tests for LoadFolderToBQDoFn (mocked BigQuery)."""

    def test_process_skips_when_folder_uri_missing(self):
        dofn = LoadFolderToBQDoFn(project_id="test")
        dofn._bq = MagicMock()
        e = {"bucket": "b", "prefix": "p/", "bq_table": "p.d.t"}
        out = list(dofn.process(e))
        assert out == []

    def test_process_skips_when_folder_uri_empty(self):
        dofn = LoadFolderToBQDoFn(project_id="test")
        dofn._bq = MagicMock()
        e = {"folder_uri": "", "bq_table": "p.d.t"}
        out = list(dofn.process(e))
        assert out == []

    def test_process_skips_when_folder_uri_does_not_end_with_wildcard(self):
        dofn = LoadFolderToBQDoFn(project_id="test")
        dofn._bq = MagicMock()
        e = {"folder_uri": "gs://bucket/prefix", "bq_table": "p.d.t"}
        out = list(dofn.process(e))
        assert out == []

    def test_process_raises_when_bq_not_initialized(self):
        dofn = LoadFolderToBQDoFn(project_id="test")
        dofn._bq = None
        e = {"folder_uri": "gs://b/p*", "bq_table": "p.d.t"}
        with pytest.raises(ValueError, match="not initialized"):
            list(dofn.process(e))

    def test_process_yields_success_record_when_load_succeeds(self):
        mock_job = MagicMock()
        mock_job.output_rows = 10
        mock_client = MagicMock()
        mock_client.load_table_from_uri.return_value = mock_job

        dofn = LoadFolderToBQDoFn(project_id="test")
        dofn._bq = mock_client
        e = {
            "folder_uri": "gs://bucket/stream/dt=2026-02-24/hour=1/*",
            "bq_table": "project.dataset.table",
            "dt": "2026-02-24",
            "hour": 1,
        }
        out = list(dofn.process(e))
        assert len(out) == 1
        assert out[0]["loaded_uri"] == "gs://bucket/stream/dt=2026-02-24/hour=1/*"
        assert out[0]["table"] == "project.dataset.table"
        assert out[0]["output_rows"] == 10
        assert out[0]["dt"] == "2026-02-24"
        assert out[0]["hour"] == 1
        mock_client.load_table_from_uri.assert_called_once()
        call_kw = mock_client.load_table_from_uri.call_args[1]
        assert call_kw["job_config"].write_disposition == "WRITE_APPEND"
        assert call_kw["job_config"].source_format == "PARQUET"

    def test_process_yields_failed_record_on_bad_request(self):
        mock_job = MagicMock()
        mock_job.result.side_effect = BadRequest("invalid schema")
        mock_client = MagicMock()
        mock_client.load_table_from_uri.return_value = mock_job

        dofn = LoadFolderToBQDoFn(project_id="test")
        dofn._bq = mock_client
        e = {
            "folder_uri": "gs://bucket/p*",
            "bq_table": "p.d.t",
        }
        out = list(dofn.process(e))
        assert len(out) == 1
        assert out[0]["failed_uri"] == "gs://bucket/p*"
        assert out[0]["table"] == "p.d.t"
        assert "error" in out[0] and "invalid schema" in out[0]["error"]