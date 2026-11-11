#!/usr/bin/env bash
set -euo pipefail

# Static instruction-contract checks, not a simulation of an LLM following a skill.
# Mutation checks prove that each required guard and old prerequisite is detected.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
python3 - "$ROOT" <<'PY'
import pathlib
import re
import sys
import unittest

ROOT = pathlib.Path(sys.argv[1])

REQUIRED = {
    'native delegation': r'permitted native subagent tool',
    'inline execution': r'perform every phase sequentially|implement the ordered work items',
    'no setup prompt': r'Do not request experimental Teams enablement',
    'default model': r'use the (?:supported|available) session/default model',
    'context fallback': r'If the harness does not expand dynamic context',
    'approval': r'(?:Wait for user approval|satisfy project plan/spec approval gates)',
    'partial edits': r'inspect returned results, git diff,',
    'writer safety': r'cancel them and wait for confirmation',
    'unfinished only': r'continue only unfinished',
    'verification': r'(?:project test suite|full required project verification suite)',
    'review honesty': r'(?:do not claim independent review|Do not claim independent review)',
    'repair bounds': r'(?:at most 3 repair rounds|exactly one targeted fix round)',
    'no automatic commits': r'Do not commit or push unless requested',
}
FORBIDDEN = [
    r'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\s*=\s*1',
    r'Agent teams required',
    r'You do NOT write code yourself',
    r'do NOT implement the tasks yourself',
    r'Team(?:Create|Delete)\(',
    r'Every implementation agent sets .model. explicitly',
    r'Team creation fails.*stop',
    r'~/.claude/skills/',
]


def violations(source):
    errors = [label for label, pattern in REQUIRED.items()
              if not re.search(pattern, source)]
    errors += [pattern for pattern in FORBIDDEN
               if re.search(pattern, source, re.I)]
    return errors


class BackendPortability(unittest.TestCase):
    def test_skill_contracts(self):
        for name in ('dev', 'orchestrate'):
            with self.subTest(skill=name):
                source = (ROOT / 'agents/skills' / name / 'SKILL.md').read_text()
                self.assertEqual(violations(source), [])

    def test_required_guards_are_not_vacuous(self):
        for name in ('dev', 'orchestrate'):
            source = (ROOT / 'agents/skills' / name / 'SKILL.md').read_text()
            for label, pattern in REQUIRED.items():
                with self.subTest(skill=name, removed=label):
                    mutated = re.sub(pattern, 'REMOVED', source)
                    self.assertIn(label, violations(mutated))

    def test_legacy_prerequisites_are_rejected(self):
        source = (ROOT / 'agents/skills/dev/SKILL.md').read_text()
        for instruction in (
            'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1',
            'Agent teams required',
            'You do NOT write code yourself.',
            'TeamCreate(team_name: "dev-session")',
            'Team creation fails: report prerequisite and stop.',
            'Read ~/.claude/skills/_shared/resources/phase-protocol.md',
        ):
            with self.subTest(instruction=instruction):
                self.assertTrue(violations(source + '\n' + instruction))

    def test_workflow_is_optional_and_failures_do_not_unblock_dependents(self):
        source = (ROOT / 'agents/skills/orchestrate/SKILL.md').read_text()
        self.assertIn('Otherwise, use a permitted native subagent tool', source)
        self.assertIn('If neither is available', source)
        self.assertIn('Do not treat a null result as success or unblock its dependents', source)
        self.assertIn('Resume with the supported run identifier and the same arguments', source)

    def test_briefings_do_not_restore_team_prerequisites(self):
        source = (ROOT / 'agents/skills/dev/references/BRIEFINGS.md').read_text()
        self.assertIn('In single-agent mode', source)
        self.assertIn('return results to the invoking session', source)
        for pattern in FORBIDDEN + [r'TaskUpdate', r'SendMessage']:
            with self.subTest(pattern=pattern):
                self.assertIsNone(re.search(pattern, source, re.I))

    def test_review_reference_exists(self):
        self.assertTrue((ROOT / 'agents/skills/dev/references/CODE_REVIEW.md').is_file())


unittest.main(argv=[sys.argv[0]])
PY
