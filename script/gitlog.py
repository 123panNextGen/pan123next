#!/usr/bin/env python3
"""从 Git 历史中提取 commit 差异，生成可直接用于 ChangeLog 的格式化输出。"""

import re
import subprocess
import sys
from enum import Enum
from typing import List, Optional, Tuple

import click

# ---------------------------------------------------------------------------
# 类型分组枚举（conventional commit type -> changelog section）
# ---------------------------------------------------------------------------


class ChangeType(Enum):
    ADDED = ("新增", ["feat", "feature"])
    FIXED = ("修复", ["fix", "bugfix", "hotfix"])
    CHANGED = ("更改", ["refactor", "perf", "performance", "style"])
    DOCS = ("文档", ["docs", "doc", "documentation"])
    BUILD = ("构建", ["build", "chore", "ci"])
    TEST = ("测试", ["test", "tests"])
    REMOVED = ("删除", ["revert", "remove", "delete", "deprecate"])

    def __new__(cls, label: str, keywords: list[str]):
        obj = object.__new__(cls)
        obj._value_ = label
        return obj

    def __init__(self, label: str, keywords: list[str]):
        self.label = label
        self.keywords = keywords

    @classmethod
    def classify(cls, commit_type: str) -> str:
        for member in cls:
            if commit_type in member.keywords:
                return member.label
        return "其他"


# ---------------------------------------------------------------------------
# Git 操作
# ---------------------------------------------------------------------------


def _git(*args: str) -> str:
    result = subprocess.run(
        ("git", *args),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.exit(1)
    return result.stdout


def get_latest_tag() -> Optional[str]:
    result = subprocess.run(
        ("git", "describe", "--tags", "--abbrev=0"),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    tag = result.stdout.strip()
    return tag if tag else None


_SEP = "\x1f"


def get_commits_between(
    from_ref: str, to_ref: str
) -> List[Tuple[str, str, str]]:
    raw = _git(
        "log",
        f"--format=%h{_SEP}%an{_SEP}%s",
        "--no-merges",
        f"{from_ref}..{to_ref}",
    )
    result: List[Tuple[str, str, str]] = []
    for line in raw.strip().split("\n"):
        line = line.strip()
        if not line:
            continue
        parts = line.split(_SEP, 2)
        if len(parts) == 3:
            result.append((parts[0], parts[1], parts[2]))
    return result


# ---------------------------------------------------------------------------
# 解析 commit 标题
# ---------------------------------------------------------------------------


_CONVENTIONAL_RE = re.compile(
    r"^(?P<type>[a-zA-Z_-]+)" r"(?:\((?P<scope>[^)]*)\))?" r":\s*(?P<desc>.+)$"
)


def author_initials(name: str) -> str:
    parts = name.split()
    return "".join(p[0].upper() for p in parts[:2] if p)


def classify_message(message: str) -> Tuple[str, str]:
    """返回 (section_label, changelog_entry)"""
    m = _CONVENTIONAL_RE.match(message)
    if m:
        raw_type = m.group("type").lower()
        desc = m.group("desc").strip()
        return ChangeType.classify(raw_type), desc
    return "其他", message


# ---------------------------------------------------------------------------
# 格式化
# ---------------------------------------------------------------------------


def _format_item(desc: str, initials: str) -> str:
    return f"- {desc} ({initials})" if initials else f"- {desc}"


def format_grouped(entries: List[Tuple[str, str, str]]) -> str:
    groups: dict[str, List[str]] = {}
    order: list[str] = []

    for section, desc, initials in entries:
        if section not in groups:
            groups[section] = []
            order.append(section)
        groups[section].append(_format_item(desc, initials))

    lines: List[str] = []
    for section in order:
        items = groups[section]
        lines.append(f"### {section}")
        if items:
            for item in items:
                lines.append(item)
        lines.append("")

    while lines and not lines[-1].strip():
        lines.pop()
    lines.append("")
    return "\n".join(lines)


def format_plain(entries: List[Tuple[str, str, str]]) -> str:
    lines = [_format_item(desc, initials) for _, desc, initials in entries]
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


@click.command(
    help=(
        "比较两个 git 引用之间的 commit 差异，输出可直接放入 ChangeLog 的格式。\n\n"
        "FROM_REF 和 TO_REF 可以是 tag、分支名或 commit hash。\n"
        "只给 FROM_REF 时比较 FROM_REF..HEAD。\n"
        "不给参数时比较最新 tag..HEAD。\n"
        "如 --no-group，则以平铺列表输出。"
    ),
)
@click.argument(
    "from_ref",
    required=False,
    default=None,
)
@click.argument(
    "to_ref",
    required=False,
    default=None,
)
@click.option(
    "--no-group",
    is_flag=True,
    default=False,
    help="不按类型分组，以平铺列表输出",
)
def main(
    from_ref: Optional[str],
    to_ref: Optional[str],
    no_group: bool,
) -> None:
    # 解析引用
    if from_ref is None:
        latest = get_latest_tag()
        if latest is None:
            print("错误：当前仓库不存在任何 tag，请手动指定 FROM_REF", file=sys.stderr)
            sys.exit(1)
        from_ref = latest

    if to_ref is None:
        to_ref = "HEAD"

    commits = get_commits_between(from_ref, to_ref)

    if not commits:
        print(
            f"错误：{from_ref}..{to_ref} 之间没有 commit 差异",
            file=sys.stderr,
        )
        sys.exit(1)

    entries: List[Tuple[str, str, str]] = []
    for sha, author, message in commits:
        section, desc = classify_message(message)
        initials = author_initials(author)
        entries.append((section, desc, initials))

    output = format_plain(entries) if no_group else format_grouped(entries)
    print(output, end="")


if __name__ == "__main__":
    main()
