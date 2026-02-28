import re

DT_RE = re.compile(r"dt=(\d{4}-\d{2}-\d{2})")
HR_RE = re.compile(r"hour=(\d{1,2})")


def add_partition_info(e, table_id: str):
    prefix = e["prefix"]
    m_dt = DT_RE.search(prefix)
    m_hr = HR_RE.search(prefix)
    if m_dt:
        e["dt"] = m_dt.group(1)
    if m_hr:
        e["hour"] = int(m_hr.group(1))
    e["bq_table"] = table_id
    return e
