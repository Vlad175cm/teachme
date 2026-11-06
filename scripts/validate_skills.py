#!/usr/bin/env python3
"""Validate every skill in skills/ so a broken SKILL.md cannot ship."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

errors: list[str] = []


def error(path: Path, message: str) -> None:
    try:
        shown = path.relative_to(ROOT)
    except ValueError:
        shown = path
    errors.append(f"{shown}: {message}")


def parse_frontmatter(text: str) -> dict[str, str] | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end == -1:
        return None
    fields: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if not line.strip() or line.lstrip().startswith("#") or ":" not in line:
            continue
        key, value = line.split(":", 1)
        fields[key.strip()] = value.strip().strip('"').strip("'")
    return fields


def validate(skill: Path) -> None:
    skill_id = skill.name
    if not ID_RE.match(skill_id):
        error(skill, f"id '{skill_id}' must be lowercase kebab-case")

    path = skill / "SKILL.md"
    if not path.is_file():
        error(skill, "missing SKILL.md")
        return

    text = path.read_text(encoding="utf-8")
    frontmatter = parse_frontmatter(text)
    if frontmatter is None:
        error(path, "missing or malformed YAML frontmatter")
        return

    name = frontmatter.get("name", "")
    description = frontmatter.get("description", "")

    if not name:
        error(path, "frontmatter: name is required")
    elif name != skill_id:
        error(path, f"frontmatter: name '{name}' must match directory '{skill_id}'")

    if not description:
        error(path, "frontmatter: description is required")
    elif not description.lower().startswith(("use when", "используй")):
        error(path, "frontmatter: description must start with 'Use when'")

    body_start = text.find("\n---\n", 4) + len("\n---\n")
    if len(text[body_start:].strip()) < 200:
        error(path, "body is too short to be useful")


def main() -> int:
    if not SKILLS.is_dir():
        print("error: skills/ directory not found", file=sys.stderr)
        return 1

    skills = sorted(path for path in SKILLS.iterdir() if path.is_dir())
    if not skills:
        print("error: no skills found", file=sys.stderr)
        return 1

    for skill in skills:
        validate(skill)

    if errors:
        print("validation failed:", file=sys.stderr)
        for message in errors:
            print(f"  - {message}", file=sys.stderr)
        return 1

    print(f"ok: {len(skills)} skill(s) validated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
