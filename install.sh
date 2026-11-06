#!/usr/bin/env bash
# teachme installer: copies the learning-report skill and wires it into AGENTS.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/skills"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
SKILLS_DIR="$CONFIG_DIR/skills"
AGENTS="$CONFIG_DIR/AGENTS.md"
WITH_AGENTS=1

MARK_BEGIN="<!-- teachme:begin -->"
MARK_END="<!-- teachme:end -->"

usage() {
	cat <<'EOF'
Usage: ./install.sh [--no-agents]

  --no-agents   copy the skill only, leave AGENTS.md untouched
  -h, --help    show this help
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--no-agents) WITH_AGENTS=0 ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
	shift
done

[[ -d "$SRC" ]] || {
	echo "error: skills/ not found next to install.sh" >&2
	exit 1
}

mkdir -p "$SKILLS_DIR"
for skill in "$SRC"/*/; do
	id="$(basename "$skill")"
	rm -rf "${SKILLS_DIR:?}/$id"
	cp -R "$skill" "$SKILLS_DIR/$id"
	echo "installed skill: $id -> $SKILLS_DIR/$id"
done

agents_block() {
	cat <<'EOF'
<!-- teachme:begin -->
## Обучающий отчёт в конце задачи

Пользователь учится на работе агента. Поэтому перед финальным сообщением в любой задаче,
где ты менял файлы, конфиги или запускал команды:

1. Загрузи скил `learning-report` инструментом `skill` и следуй ему.
2. Отчёт — по-русски, в чат.
3. Сохрани копию в `.txt`-файл в `$HOME/ai-devlog/` и укажи путь последней строкой.

Отчёт не сокращай и блоки не пропускай, даже если задача кажется простой.
<!-- teachme:end -->
EOF
}

if [[ "$WITH_AGENTS" -eq 1 ]]; then
	mkdir -p "$CONFIG_DIR"
	block="$(mktemp)"
	trap 'rm -f "$block"' EXIT
	agents_block >"$block"

	if [[ ! -f "$AGENTS" ]]; then
		{
			echo "# Глобальные правила"
			echo
			agents_block
		} >"$AGENTS"
		echo "created $AGENTS with the teachme block"
	elif grep -qF "$MARK_BEGIN" "$AGENTS"; then
		cp "$AGENTS" "$AGENTS.bak.$(date +%Y%m%d-%H%M%S)"
		awk -v b="$MARK_BEGIN" -v e="$MARK_END" -v bf="$block" '
			$0 == b { while ((getline line < bf) > 0) print line; close(bf); skip = 1; next }
			$0 == e { skip = 0; next }
			!skip { print }
		' "$AGENTS" >"$AGENTS.tmp"
		mv "$AGENTS.tmp" "$AGENTS"
		echo "updated the teachme block in $AGENTS"
	else
		cp "$AGENTS" "$AGENTS.bak.$(date +%Y%m%d-%H%M%S)"
		{
			echo
			agents_block
		} >>"$AGENTS"
		echo "added the teachme block to $AGENTS"
	fi
else
	echo "skipped AGENTS.md (--no-agents)"
fi

cat <<'EOF'

Done. OpenCode reloads skills and AGENTS.md automatically; no restart needed.
Verify: ask the agent for a small change and look for the nine sections at the end.
Reports are saved to: $HOME/ai-devlog/
EOF
