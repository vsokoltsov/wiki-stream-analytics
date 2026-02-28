import pytest

from ingestion.pipeline.routing import add_partition_info


@pytest.mark.unit
class TestRoutingUnit:
    def test_add_partition_info_sets_dt_hour_and_bq_table(self):
        e = {
            "prefix": "stream/dt=2026-02-24/hour=21/",
            "bucket": "b",
            "object": "stream/dt=2026-02-24/hour=21/part-0",
        }
        table_id = "project.dataset.table"

        result = add_partition_info(e, table_id)

        assert result is e
        assert e["dt"] == "2026-02-24"
        assert e["hour"] == 21
        assert e["bq_table"] == "project.dataset.table"

    def test_add_partition_info_only_dt(self):
        e = {"prefix": "stream/dt=2020-01-15/", "bucket": "b"}
        add_partition_info(e, "p.d.t")

        assert e["dt"] == "2020-01-15"
        assert e["bq_table"] == "p.d.t"
        assert "hour" not in e

    def test_add_partition_info_only_hour(self):
        e = {"prefix": "data/hour=3/"}
        add_partition_info(e, "proj.ds.tbl")

        assert e["hour"] == 3
        assert e["bq_table"] == "proj.ds.tbl"
        assert "dt" not in e

    def test_add_partition_info_no_dt_no_hour(self):
        e = {"prefix": "other/path/"}
        add_partition_info(e, "a.b.c")

        assert e["bq_table"] == "a.b.c"
        assert "dt" not in e
        assert "hour" not in e

    def test_add_partition_info_hour_single_digit(self):
        e = {"prefix": "stream/dt=2026-01-01/hour=2/"}
        add_partition_info(e, "p.d.t")

        assert e["dt"] == "2026-01-01"
        assert e["hour"] == 2

    def test_add_partition_info_mutates_and_returns_same_dict(self):
        e = {"prefix": "x/dt=2025-12-31/hour=23/"}
        out = add_partition_info(e, "p.d.t")

        assert out is e
        assert e["bq_table"] == "p.d.t"

    def test_add_partition_info_raises_keyerror_when_prefix_missing(self):
        e = {"bucket": "b"}
        with pytest.raises(KeyError):
            add_partition_info(e, "p.d.t")

    @pytest.mark.parametrize(
        "prefix, expected_dt, expected_hour",
        [
            ("stream/dt=2024-06-15/hour=0/", "2024-06-15", 0),
            ("stream/dt=2024-06-15/hour=12/", "2024-06-15", 12),
            ("prefix/dt=2000-01-01/hour=23/suffix", "2000-01-01", 23),
        ],
    )
    def test_add_partition_info_parametrized(self, prefix, expected_dt, expected_hour):
        e = {"prefix": prefix}
        add_partition_info(e, "p.d.t")
        assert e["dt"] == expected_dt
        assert e["hour"] == expected_hour
