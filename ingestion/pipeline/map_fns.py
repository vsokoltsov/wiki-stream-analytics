from ingestion.pipeline.deduplicate import key_for_dedup


def to_dedup_kv(e):
    return (key_for_dedup(e), e)


def to_completeness_kv(e):
    return (f'{e["bucket"]}|{e["prefix"]}', e)
