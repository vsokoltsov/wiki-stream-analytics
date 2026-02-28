import pytest
import apache_beam as beam
from apache_beam.io.gcp.pubsub import PubsubMessage
from apache_beam.testing.util import assert_that, equal_to
from unittest.mock import MagicMock, patch

from ingestion.pipeline.definition import create_ingestion_pipeline

# Valid GCP project ID: 6–63 chars, [a-z][-a-z0-9:.]{4,61}[a-z0-9]
_VALID_PROJECT = "myproj"
_VALID_SUBSCRIPTION = f"projects/{_VALID_PROJECT}/subscriptions/mysub"


@pytest.mark.unit
class TestDefinitionUnit:
    """Unit tests: create_ingestion_pipeline contract and args."""

    def test_create_ingestion_pipeline_returns_same_pipeline(self):
        p = beam.Pipeline()
        args = {
            "subscription": _VALID_SUBSCRIPTION,
            "project": _VALID_PROJECT,
            "table_id": "my-proj.dataset.table",
        }
        result = create_ingestion_pipeline(p, args)
        assert result is p

    def test_create_ingestion_pipeline_requires_subscription(self):
        p = beam.Pipeline()
        args = {"project": _VALID_PROJECT, "table_id": "p.d.t"}
        with pytest.raises(KeyError):
            create_ingestion_pipeline(p, args)

    def test_create_ingestion_pipeline_requires_project(self):
        p = beam.Pipeline()
        args = {"subscription": _VALID_SUBSCRIPTION, "table_id": "p.d.t"}
        with pytest.raises(KeyError):
            create_ingestion_pipeline(p, args)

    def test_create_ingestion_pipeline_requires_table_id(self):
        p = beam.Pipeline()
        args = {"subscription": _VALID_SUBSCRIPTION, "project": _VALID_PROJECT}
        with pytest.raises(KeyError):
            create_ingestion_pipeline(p, args)

    def test_create_ingestion_pipeline_builds_with_valid_args(self):
        """Pipeline builds without error when all required args are present."""
        p = beam.Pipeline()
        args = {
            "subscription": _VALID_SUBSCRIPTION,
            "project": _VALID_PROJECT,
            "table_id": "myproj.ds.raw",
        }
        create_ingestion_pipeline(p, args)
        assert p is not None