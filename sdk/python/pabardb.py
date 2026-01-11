#!/usr/bin/env python3
# PABAR DB Python SDK (CLI-backed)
# - No external dependencies
# - Works on macOS/Linux
# - Requires `pabardb` binary in PATH

from __future__ import annotations

import json
import os
import shlex
import subprocess
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Union


Json = Union[Dict[str, Any], List[Any]]


class PabarDBError(RuntimeError):
    """Raised when pabardb CLI fails or returns invalid output."""


@dataclass
class ExecResult:
    stdout: str
    stderr: str
    returncode: int


def _run_cmd(cmd: List[str]) -> ExecResult:
    """Run a command safely without shell=True."""
    p = subprocess.run(cmd, capture_output=True, text=True)
    return ExecResult(stdout=p.stdout.strip(), stderr=p.stderr.strip(), returncode=p.returncode)


def _json_dumps(obj: Any) -> str:
    # Stable JSON output for reproducibility
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"), sort_keys=True)


def _expect_ok(out: str, action: str) -> None:
    if out.strip() != "OK":
        raise PabarDBError(f"{action} failed: expected 'OK', got: {out!r}")


class PabarDB:
    """
    Python SDK for PABAR DB using the `pabardb` CLI.

    Usage:
      db = PabarDB("mydb.pbr")
      db.recover()
      db.put("record", "R-1", {"name":"Barri"})
      print(db.get("record", "R-1"))
    """

    def __init__(self, db_path: str, pabardb_bin: str = "pabardb") -> None:
        self.db_path = db_path
        self.pabardb_bin = pabardb_bin

    # -------- core runner --------
    def _exec(self, command: str) -> str:
        cmd = [self.pabardb_bin, self.db_path, command]
        r = _run_cmd(cmd)
        if r.returncode != 0:
            msg = r.stderr or r.stdout or "unknown error"
            raise PabarDBError(f"pabardb failed (code={r.returncode}): {msg}")
        return r.stdout

    # -------- lifecycle --------
    def recover(self) -> None:
        out = self._exec("RECOVER")
        _expect_ok(out, "RECOVER")

    # -------- CRUD --------
    def put(self, typ: str, _id: str, payload: Dict[str, Any], actor: Optional[str] = None) -> None:
        """
        Insert/Update a record.
        actor is optional metadata (kept for forward-compat); currently embedded in payload only if provided.
        """
        if actor:
            payload = dict(payload)
            payload["_actor"] = actor
        j = _json_dumps(payload)
        out = self._exec(f"PUT {typ} {_id} '{j}'")
        _expect_ok(out, f"PUT {typ} {_id}")

    def get(self, typ: str, _id: str) -> Dict[str, Any]:
        out = self._exec(f"GET {typ} {_id}")
        try:
            return json.loads(out)
        except Exception as e:
            raise PabarDBError(f"GET returned non-JSON: {out!r}") from e

    def delete(self, typ: str, _id: str) -> None:
        out = self._exec(f"DEL {typ} {_id}")
        _expect_ok(out, f"DEL {typ} {_id}")

    # -------- scanning --------
    def list(self, typ: str) -> List[Dict[str, Any]]:
        out = self._exec(f"LIST {typ}")
        try:
            data = json.loads(out)
            if not isinstance(data, list):
                raise ValueError("LIST must return JSON array")
            return data
        except Exception as e:
            raise PabarDBError(f"LIST returned invalid JSON: {out!r}") from e

    def find(self, typ: str, filter_obj: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Filter query. Requires engine support for FIND.
        Example filter: {"age":{"$gte":30}}
        """
        filt = _json_dumps(filter_obj)
        out = self._exec(f"FIND {typ} '{filt}'")
        try:
            data = json.loads(out)
            if not isinstance(data, list):
                raise ValueError("FIND must return JSON array")
            return data
        except Exception as e:
            raise PabarDBError(f"FIND returned invalid JSON: {out!r}") from e

    # -------- schema & index metadata --------
    def put_schema(self, typ: str, schema: Dict[str, Any]) -> None:
        j = _json_dumps(schema)
        out = self._exec(f"PUT _schema {typ} '{j}'")
        _expect_ok(out, f"PUT _schema {typ}")

    def get_schema(self, typ: str) -> Dict[str, Any]:
        out = self._exec(f"GET _schema {typ}")
        try:
            return json.loads(out)
        except Exception as e:
            raise PabarDBError(f"GET _schema returned non-JSON: {out!r}") from e

    def put_index(self, typ: str, index: Dict[str, Any]) -> None:
        j = _json_dumps(index)
        out = self._exec(f"PUT _index {typ} '{j}'")
        _expect_ok(out, f"PUT _index {typ}")

    def get_index(self, typ: str) -> Dict[str, Any]:
        out = self._exec(f"GET _index {typ}")
        try:
            return json.loads(out)
        except Exception as e:
            raise PabarDBError(f"GET _index returned non-JSON: {out!r}") from e

    # -------- audit log --------
    def log(self, typ: str, _id: str) -> List[Dict[str, Any]]:
        out = self._exec(f"LOG {typ} {_id}")
        try:
            data = json.loads(out)
            if not isinstance(data, list):
                raise ValueError("LOG must return JSON array")
            return data
        except Exception as e:
            raise PabarDBError(f"LOG returned invalid JSON: {out!r}") from e

    # -------- dump/import --------
    def dump_json(self, typ: Optional[str] = None) -> str:
        """
        Returns JSON dump (string). Use save_to_file(...) if needed.
        """
        cmd = f"DUMP {typ} JSON" if typ else "DUMP JSON"
        return self._exec(cmd)

    def dump_csv(self, typ: str) -> str:
        return self._exec(f"DUMP {typ} CSV")

    def import_json(self, typ: str, json_path: str) -> None:
        out = self._exec(f"IMPORT JSON {typ} {shlex.quote(json_path)}")
        _expect_ok(out, f"IMPORT JSON {typ}")

    def import_csv(self, typ: str, csv_path: str) -> None:
        out = self._exec(f"IMPORT CSV {typ} {shlex.quote(csv_path)}")
        _expect_ok(out, f"IMPORT CSV {typ}")


# -------------------- tiny CLI for SDK testing --------------------

def _usage() -> str:
    return """Usage:
  python -m pabardb <db.pbr> recover
  python -m pabardb <db.pbr> put <type> <id> '{"k":"v"}'
  python -m pabardb <db.pbr> get <type> <id>
  python -m pabardb <db.pbr> del <type> <id>
  python -m pabardb <db.pbr> list <type>
  python -m pabardb <db.pbr> find <type> '{"field":{"$gte":1}}'
"""


def main(argv: Optional[List[str]] = None) -> int:
    import sys

    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 2:
        print(_usage())
        return 2

    db_path = argv.pop(0)
    action = argv.pop(0).lower()

    db = PabarDB(db_path)

    try:
        if action == "recover":
            db.recover()
            print("OK")
            return 0

        if action == "put":
            if len(argv) < 3:
                print(_usage())
                return 2
            typ, _id, payload_json = argv[0], argv[1], argv[2]
            payload = json.loads(payload_json)
            db.put(typ, _id, payload)
            print("OK")
            return 0

        if action == "get":
            if len(argv) < 2:
                print(_usage())
                return 2
            typ, _id = argv[0], argv[1]
            print(json.dumps(db.get(typ, _id), ensure_ascii=False))
            return 0

        if action in ("del", "delete"):
            if len(argv) < 2:
                print(_usage())
                return 2
            typ, _id = argv[0], argv[1]
            db.delete(typ, _id)
            print("OK")
            return 0

        if action == "list":
            if len(argv) < 1:
                print(_usage())
                return 2
            typ = argv[0]
            print(json.dumps(db.list(typ), ensure_ascii=False))
            return 0

        if action == "find":
            if len(argv) < 2:
                print(_usage())
                return 2
            typ, filt_json = argv[0], argv[1]
            filt = json.loads(filt_json)
            print(json.dumps(db.find(typ, filt), ensure_ascii=False))
            return 0

        print(_usage())
        return 2

    except PabarDBError as e:
        print(f"ERROR: {e}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

