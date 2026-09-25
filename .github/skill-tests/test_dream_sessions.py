#!/usr/bin/env python3
"""Fixture tests for Dream's local JSONL session extractor."""

import importlib.util
import json
import tempfile
import time
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[2] / "agents/skills/dream/scripts/sessions.py"
spec = importlib.util.spec_from_file_location("dream_sessions", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def write_jsonl(path, records):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(json.dumps(record) for record in records) + "\n", encoding="utf-8")


def codex_message(role, value, phase=None):
    return {"type": "response_item", "payload": {"type": "message", "role": role,
            "phase": phase, "content": [{"type": "input_text" if role == "user" else "output_text",
                                    "text": value}]}}


def claude_message(role, value, stop_reason=None, **extra):
    return {"type": role, "message": {"role": role, "content": value,
            "stop_reason": stop_reason}, **extra}


def run():
    with tempfile.TemporaryDirectory() as root:
        root = Path(root)
        claude = root / "claude"
        codex = root / "codex"
        state = root / "runs/state.json"
        codex_id = "codex-session-1234"
        claude_id = "claude-session-1234"
        codex_file = codex / "2026/09/24" / f"rollout-{codex_id}.jsonl"
        claude_file = claude / "project" / f"{claude_id}.jsonl"
        secret = "sk-" + "A" * 25
        extra_secrets = ["SG." + "A" * 16 + "." + "B" * 16,
                         "ntn_" + "A" * 20, "sntrys_" + "A" * 20,
                         "dda" + "a" * 20, "pdkey_" + "A" * 16]
        write_jsonl(codex_file, [
            {"type": "session_meta", "payload": {"id": codex_id, "cwd": str(root / "work")}},
            codex_message("user", f"Choose SQLite. {secret} {' '.join(extra_secrets)}"),
            {"type": "response_item", "payload": {"type": "reasoning", "content": "private reasoning"}},
            codex_message("assistant", "Use SQLite for the cache.", "final_answer"),
            {"type": "event_msg", "payload": {"type": "task_complete"}},
            codex_message("user", "unfinished Codex turn"),
        ])
        write_jsonl(claude_file, [
            {**claude_message("user", "Choose Postgres."), "cwd": str(root / "work")},
            claude_message("assistant", [{"type": "tool_use", "name": "Bash"}], "tool_use"),
            claude_message("user", [{"type": "tool_result", "content": "private tool output"}]),
            claude_message("assistant", [{"type": "text", "text": "Use Postgres for storage."}], "end_turn"),
            claude_message("user", "ignore this", isSidechain=True),
            claude_message("user", "unfinished Claude turn"),
        ])
        sources = (("claude", claude), ("codex", codex))
        found = list(module.pending(sources, state))
        assert len(found) == 2, found
        assert {item["source"] for item in found} == {"claude", "codex"}
        assert not state.exists(), "discovery and dry-run must not write state"
        captures = "\n".join(item["capture"] for item in found)
        assert "session-capture, claude, transcript" in captures
        assert "session-capture, codex, transcript" in captures
        assert "no-commit" not in captures
        assert "Use SQLite for the cache." in captures
        assert "Use Postgres for storage." in captures
        assert "[REDACTED-API-KEY]" in captures and secret not in captures
        assert all(secret_value not in captures for secret_value in extra_secrets)
        assert "private reasoning" not in captures and "private tool output" not in captures
        assert "unfinished" not in captures
        for item in found:
            module.mark(state, item["source"], item["session_id"], item["turn"],
                        item["transcript_path"], item["last_turn"], item["mtime_ns"])
        assert list(module.pending(sources, state)) == []
        with codex_file.open("a", encoding="utf-8") as transcript:
            transcript.write(json.dumps(codex_message("assistant", "New answer.", "final_answer")) + "\n")
            transcript.write(json.dumps({"type": "event_msg", "payload": {"type": "task_complete"}}) + "\n")
            transcript.write("{unfinished json")
        found = list(module.pending(sources, state))
        assert len(found) == 1 and found[0]["turn"] == 2, found
        assert "New answer." in found[0]["capture"]
        gap_state = root / "runs/gap.json"
        module.mark(gap_state, "codex", codex_id, 2, codex_file, 2, found[0]["mtime_ns"])
        assert [item["turn"] for item in module.pending((("codex", codex),), gap_state)] == [1]
        with claude_file.open("a", encoding="utf-8") as transcript:
            for turn in range(11):
                transcript.write(json.dumps(claude_message("user", f"Request {turn}")) + "\n")
                transcript.write(json.dumps(claude_message("assistant", f"Answer {turn}", "end_turn")) + "\n")
        found = list(module.pending(sources, state))
        assert len(found) == 11, "Claude backlog must leave room for Codex"
        assert sum(item["source"] == "claude" for item in found) == 10
        assert sum(item["source"] == "codex" for item in found) == 1
        assert list(module.pending((("claude", root / "missing"),), state)) == []
        old = time.time() - 7 * 86400
        import os
        os.utime(codex_file, (old, old))
        assert len(list(module.pending((("codex", codex),), state))) == 1, "old Codex turns remain eligible"
        exclude_file = root / "excluded.txt"
        exclude_file.write_text("work\n", encoding="utf-8")
        assert list(module.pending(sources, state, exclude_file)) == []
        empty_final = claude / "project" / "empty-final-1234.jsonl"
        write_jsonl(empty_final, [
            claude_message("user", "First request"),
            claude_message("assistant", [], "end_turn"),
            claude_message("user", "Second request"),
            claude_message("assistant", "Second answer", "end_turn"),
        ])
        turns = list(module.read_turns(empty_final, "claude"))
        assert [turn for _, turn, _ in turns] == [1, 2]
    print("dream session extractor: passed")


if __name__ == "__main__":
    run()
