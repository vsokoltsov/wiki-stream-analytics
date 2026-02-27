import apache_beam as beam
from typing import Dict, Any
from apache_beam.transforms.userstate import ReadModifyWriteStateSpec
from apache_beam.coders import StrUtf8Coder

class DeduplicateDoFn(beam.DoFn):
    seen_state = ReadModifyWriteStateSpec("seen", StrUtf8Coder())

    def process(self, kv, seen=beam.DoFn.StateParam(seen_state)): # type: ignore[override]
        key, event = kv
        res = seen.read()
        print(f"DeduplicateDoFn event was seen {res}")
        if res == "1":
            return
        seen.write("1")
        
        yield event

def key_for_dedup(e: Dict[str, Any]) -> str:
    return f'{e["bucket"]}|{e["object"]}|{e.get("generation","")}'