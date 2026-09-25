#!/usr/bin/env python3
"""Discover completed Claude Code and Codex turns for Dream."""

import argparse
import json
import os
import re
import time
from pathlib import Path

MAX_TRANSCRIPT_BYTES = 50 * 1024 * 1024
MAX_MESSAGES = 12
MAX_MESSAGE_CHARS = 1200
MAX_PENDING = 20
MAX_PENDING_PER_SOURCE = MAX_PENDING // 2
TOKEN_PATTERNS = [
    (re.compile(r"(?:AKIA|ASIA|AROA|AIDA)[0-9A-Z]{16}"), "[REDACTED-AWS]"),
    (re.compile(r"github_pat_[A-Za-z0-9_]{20,}|gh[psou]_[A-Za-z0-9]{20,}"), "[REDACTED-GH]"),
    (re.compile(r"sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9_-]{20,}"), "[REDACTED-API-KEY]"),
    (re.compile(r"xox[bpars]-[A-Za-z0-9-]{10,}"), "[REDACTED-SLACK]"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"), "[REDACTED-PRIVKEY]"),
]


def redact(value):
    for pattern, replacement in TOKEN_PATTERNS:
        value = pattern.sub(replacement, value)
    return value


def bounded_message(role, parts):
    value = redact(" ".join(parts).strip())[:MAX_MESSAGE_CHARS]
    return (role, value) if value else None


def codex_message(payload):
    if payload.get("type") != "message":
        return None
    role = payload.get("role")
    if role != "user" and not (role == "assistant" and payload.get("phase") == "final_answer"):
        return None
    parts = [part.get("text", "") for part in payload.get("content", [])
             if isinstance(part, dict) and part.get("type") in ("input_text", "output_text")]
    return bounded_message(role, parts)


def claude_message(record):
    if record.get("isSidechain") or record.get("isMeta") or record.get("isSynthetic"):
        return None
    role = record.get("type")
    message = record.get("message") or {}
    if not isinstance(message, dict):
        return None
    if role not in ("user", "assistant") or message.get("role") != role:
        return None
    if role == "assistant" and message.get("stop_reason") != "end_turn":
        return None
    content = message.get("content")
    if isinstance(content, str):
        parts = [content]
    elif isinstance(content, list):
        if role == "user" and any(part.get("type") == "tool_result" for part in content if isinstance(part, dict)):
            return None
        parts = [part.get("text", "") for part in content
                 if isinstance(part, dict) and part.get("type") == "text"]
    else:
        return None
    return bounded_message(role, parts)


def read_turns(path, source):
    """Yield only fully answered turns; ignore an unfinished JSONL tail."""
    records = read_records(path)
    if source == "codex":
        yield from read_codex_turns(records)
    else:
        yield from read_claude_turns(records, path.stem)


def read_records(path):
    with path.open(encoding="utf-8", errors="replace") as transcript:
        for line in transcript:
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                return


def read_codex_turns(records):
    session_id = None
    messages = []
    completed = 0
    for record in records:
        payload = record.get("payload") or {}
        if record.get("type") == "session_meta":
            session_id = payload.get("id") or payload.get("session_id")
        elif record.get("type") == "response_item":
            item = codex_message(payload)
            if item:
                messages.append(item)
        elif record.get("type") == "event_msg" and payload.get("type") == "task_complete":
            completed += 1
            if session_id and re.fullmatch(r"[A-Za-z0-9-]{8,80}", session_id):
                yield session_id, completed, messages[-MAX_MESSAGES:]
            messages = []


def read_claude_turns(records, session_id):
    messages = []
    completed = 0
    for record in records:
        item = claude_message(record)
        if item:
            messages.append(item)
        message = record.get("message") or {}
        is_complete = (record.get("type") == "assistant" and isinstance(message, dict)
                       and message.get("stop_reason") == "end_turn"
                       and not any(record.get(flag) for flag in ("isSidechain", "isMeta", "isSynthetic")))
        if is_complete:
            completed += 1
            if re.fullmatch(r"[A-Za-z0-9-]{8,80}", session_id):
                yield session_id, completed, messages[-MAX_MESSAGES:]
            messages = []


def capture(source, session_id, turn, messages, path):
    lines = ["---", f'title: "{source.title()} session {session_id} turn {turn}"',
             f"tags: [session-capture, {source}, transcript]", "---", "",
             f"Raw {source.title()} session signal for Dream synthesis.", "",
             f"Session ID: {session_id}", f"Turn: {turn}",
             f"Transcript path: {path}", "", "## User requests and final responses"]
    for role, content in messages:
        lines.extend(("", f"**{role.title()}:** {content}"))
    return "\n".join(lines) + "\n"


def load_state(path):
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    return value if isinstance(value, dict) else {}


def since_time(state_file):
    logs = list(state_file.parent.glob("????-??-??.log"))
    latest = max((path.stat().st_mtime for path in logs), default=time.time() - 48 * 3600)
    return latest - 24 * 3600


def pending(sources, state_file):
    state = load_state(state_file)
    since = state.get("_since", since_time(state_file))
    for source, directory in sources:
        if not directory.is_dir():
            continue
        count = 0
        for path in sorted(directory.rglob("*.jsonl")):
            try:
                stat = path.stat()
                if stat.st_mtime < since or stat.st_size > MAX_TRANSCRIPT_BYTES:
                    continue
                for item in pending_path(path, source, stat.st_mtime, state):
                    yield item
                    count += 1
                    if count >= MAX_PENDING_PER_SOURCE:
                        break
            except OSError:
                continue
            if count >= MAX_PENDING_PER_SOURCE:
                break


def pending_path(path, source, modified, state):
    date = time.strftime("%Y-%m-%d", time.gmtime(modified))
    for session_id, turn, messages in read_turns(path, source):
        if turn <= state.get(f"{source}:{session_id}", 0):
            continue
        yield {"source": source, "session_id": session_id, "turn": turn,
               "inbox_path": f"memory/inbox/{date}-{source}-{session_id}-{turn}.md",
               "capture": capture(source, session_id, turn, messages, path)}


def mark(state_file, source, session_id, turn):
    state = load_state(state_file)
    state.setdefault("_since", since_time(state_file))
    key = f"{source}:{session_id}"
    state[key] = max(int(state.get(key, 0)), turn)
    state_file.parent.mkdir(parents=True, exist_ok=True)
    temporary = state_file.with_suffix(".tmp")
    temporary.write_text(json.dumps(state, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(temporary, state_file)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("pending", "mark"))
    parser.add_argument("--codex-dir", type=Path,
                        default=Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")) / "sessions")
    parser.add_argument("--claude-dir", type=Path, default=Path.home() / ".claude/projects")
    parser.add_argument("--state-file", type=Path,
                        default=Path.home() / ".dots/sys/dream-runs/sessions-processed.json")
    parser.add_argument("--source", choices=("claude", "codex"))
    parser.add_argument("--session-id")
    parser.add_argument("--turn", type=int)
    args = parser.parse_args()
    if args.action == "pending":
        for item in pending((("claude", args.claude_dir), ("codex", args.codex_dir)), args.state_file):
            print(json.dumps(item, ensure_ascii=False))
    else:
        if not args.source or not args.session_id or not re.fullmatch(r"[A-Za-z0-9-]{8,80}", args.session_id):
            parser.error("mark requires --source and a valid --session-id")
        if not args.turn or args.turn < 1:
            parser.error("mark requires a positive --turn")
        mark(args.state_file, args.source, args.session_id, args.turn)


if __name__ == "__main__":
    main()
