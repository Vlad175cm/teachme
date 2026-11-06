# teachme

[![validate](https://github.com/Vlad175cm/teachme/actions/workflows/validate.yml/badge.svg)](https://github.com/Vlad175cm/teachme/actions/workflows/validate.yml)

An [OpenCode](https://opencode.ai) skill that turns the end of every coding task into a lesson.

Most agents finish with "Done. Fixed the bug in `slug.py`." That tells you nothing about why the bug existed, what else you could have done, or how to check the fix yourself. **teachme** makes the agent explain the work: the decisions, the rejected alternatives, the risks, and what to try next.

> Русская версия: [README.ru.md](README.ru.md)

## What you get

At the end of any task that changed files or ran commands, the agent prints a report with nine fixed sections:

| # | Section | What it answers |
|---|---------|-----------------|
| 1 | Задача и результат | What was asked, what works now |
| 2 | Что сделано | Every change, file by file, with a reason |
| 3 | Как я это делал | The actual process, including dead ends |
| 4 | Почему так, а не иначе | Alternatives and why they lost |
| 5 | Куда смотреть в коде | Map: file → role → key functions |
| 6 | Новые понятия | Terms and APIs met in this task |
| 7 | Как проверить самому | Copy-paste commands and expected output |
| 8 | Риски и ограничения | What can break, what is not covered |
| 9 | Что изучить дальше | Concrete next steps |

The same text is saved to `$HOME/ai-devlog/YYYY-MM-DD_HHMM_<project>.txt`, so you keep a searchable learning log next to your projects.

Reports are written in Russian by default: the point is to be read, not skimmed. One line in `SKILL.md` switches the language.

## Install

```bash
git clone https://github.com/Vlad175cm/teachme.git
cd teachme
./install.sh
```

The installer:

1. copies `skills/learning-report/` to `~/.config/opencode/skills/`;
2. appends a marked block to `~/.config/opencode/AGENTS.md` — with a timestamped backup, and without duplicating the block on re-runs.

Use `./install.sh --no-agents` to install the skill only. OpenCode reloads skills and `AGENTS.md` automatically, no restart needed.

### Manual install

Copy `skills/learning-report/` into `~/.config/opencode/skills/` and add this to `~/.config/opencode/AGENTS.md`:

```markdown
## Обучающий отчёт в конце задачи

Пользователь учится на работе агента. Поэтому перед финальным сообщением в любой задаче,
где ты менял файлы, конфиги или запускал команды:

1. Загрузи скил `learning-report` инструментом `skill` и следуй ему.
2. Отчёт — по-русски, в чат.
3. Сохрани копию в `.txt`-файл в `$HOME/ai-devlog/` и укажи путь последней строкой.

Отчёт не сокращай и блоки не пропускай, даже если задача кажется простой.
```

## Why AGENTS.md is required

OpenCode skills are lazy-loaded. The model sees only the skill's name and description and may never open the body. `AGENTS.md` is in context on every request, so it acts as the trigger: *finish every task by loading this skill*.

The skill alone is a suggestion. The skill plus `AGENTS.md` is the default.

## Customize

| What | Where | How |
|------|-------|-----|
| Report language | `SKILL.md`, `AGENTS.md` | replace "по-русски" with your language |
| Log directory | `SKILL.md` → `Файл` | change `$HOME/ai-devlog/` |
| Report sections | `SKILL.md` → `Обязательные блоки` | add or remove blocks, then update the checklist in `Перед отправкой` |
| Scope | `AGENTS.md` block | add a condition, e.g. only inside git repositories |

Keep the skill and the `AGENTS.md` block in sync: the block only triggers, the skill defines the format.

## Verify

```bash
ls ~/.config/opencode/skills/learning-report/SKILL.md
grep -c '<!-- teachme:begin -->' ~/.config/opencode/AGENTS.md   # must print 1
```

Then ask the agent for a small change in any project. Expected: nine headings `### 1.` … `### 9.`, and the last line is a path to a new `.txt` file in `~/ai-devlog/`.

## Uninstall

```bash
rm -rf ~/.config/opencode/skills/learning-report
```

Then delete the lines between `<!-- teachme:begin -->` and `<!-- teachme:end -->` in `~/.config/opencode/AGENTS.md`.

## Repo layout

```text
teachme/
├── install.sh                     # copies the skill, wires AGENTS.md
├── skills/learning-report/SKILL.md
├── scripts/validate_skills.py     # frontmatter and structure checks
├── .github/workflows/validate.yml # CI: runs the validator on every push
├── docs/plans/                    # design notes
├── README.md
├── README.ru.md
└── LICENSE
```

## License

MIT — see [LICENSE](LICENSE).
