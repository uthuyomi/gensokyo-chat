import argparse
import json
import os
import sys
from dataclasses import dataclass
from typing import Any, Dict, List, Optional


@dataclass
class JobArgs:
    input: str
    output: str


def parse_job_args() -> JobArgs:
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
    else:
        argv = []

    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--input", required=True)
    p.add_argument("--output", required=True)
    ns = p.parse_args(argv)
    return JobArgs(input=str(ns.input), output=str(ns.output))


def write_json(path: str, data: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def die(msg: str) -> None:
    raise RuntimeError(msg)

