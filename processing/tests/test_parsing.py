import json
import pytest

from processing.app import parse_curated_row, _dt_hour_from_ts_seconds


@pytest.mark.unit
@pytest.mark.parametrize(
    "ts_seconds, expected_dt, expected_hour",
    [
        (0, "1970-01-01", "00"),
        (3600, "1970-01-01", "01"),
        (86400, "1970-01-02", "00"),
    ],
)
def test_dt_hour_from_ts_seconds(ts_seconds, expected_dt, expected_hour):
    dt, hour = _dt_hour_from_ts_seconds(ts_seconds)
    assert dt == expected_dt
    assert hour == expected_hour


@pytest.mark.unit
def test_parse_curated_row_ok():
    raw = json.dumps({
        "timestamp": 0,
        "wiki": "enwiki",
        "type": "edit",
        "user": "Alice",
        "bot": False,
        "title": "Main Page",
        "namespace": 0,
    })

    row = parse_curated_row(raw)
    assert row is not None

    assert tuple(row) == (
        0,
        "enwiki",
        "edit",
        "Alice",
        False,
        "Main Page",
        0,
        "1970-01-01",
        "00",
    )

@pytest.mark.unit
@pytest.mark.parametrize(
    "raw",
    [
        "{not-json",
        json.dumps({"timestamp": 1, "wiki": "enwiki"}),  # missing type
        json.dumps({"timestamp": "not-int", "wiki": "enwiki", "type": "edit"}),  # bad timestamp
    ],
)
def test_parse_curated_row_invalid_cases(raw):
    assert parse_curated_row(raw) is None