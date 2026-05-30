#!/usr/bin/env python3
"""Markdown Release Notes Formatter - Template engine for version release information"""

import re
import sys
from pathlib import Path
from typing import Dict, Optional

import click
from rich.console import Console
from rich.markdown import Markdown

console = Console()

DEFAULT_MESSAGES = {
    "en": {
        "template_engine": "Markdown Template Engine",
        "error_read": "Error: Cannot read {label} {path} - {exc}",
        "warning_no_input": "Warning: No --file specified and --message is empty, using default template",
        "error_template": "Error processing template: {exc}",
        "pre_release": "Pre-release",
        "full_release": "Full release",
        "update_message": "Update Message",
        "default_template_title": "Pan123 Next Release {version}",
        "default_template_section": "## Update Notes\n\n{update_message}",
        "conditional_key_error": "Error: Invalid conditional key '{key}' in template",
    },
    "zh": {
        "template_engine": "Markdown 格式化工具",
        "error_read": "错误：无法读取{label} {path} - {exc}",
        "warning_no_input": "警告：未指定 --file 且 --message 为空，将使用默认模板",
        "error_template": "处理模板时出错：{exc}",
        "pre_release": "预发布版本",
        "full_release": "正式版本",
        "update_message": "更新说明",
        "default_template_title": "Pan123 Next Release {version}",
        "default_template_section": "## 更新说明\n\n{update_message}",
        "conditional_key_error": "错误：模板中存在无效的条件键 '{key}'",
    },
}

NESTED_BLOCK_MAX_ITERATIONS = 5

PLACEHOLDERS = [
    "Version",
    "Tag",
    "UpdateMessage",
    "ChangeLog",
    "Commit",
    "ShortCommit",
    "Repository",
    "Date",
    "PreviousTag",
]

CONDITIONAL_KEYS = [
    "isPreVersion",
    "hasMessage",
    "hasChangeLog",
    "hasCommit",
    "hasRepository",
    "hasDate",
    "hasPreviousTag",
]


def get_message(key: str, lang: str = "en", **kwargs) -> str:
    """Get localized message with optional format parameters."""
    messages = DEFAULT_MESSAGES.get(lang, DEFAULT_MESSAGES["en"])
    template = messages.get(key, DEFAULT_MESSAGES["en"].get(key, key))
    if kwargs:
        try:
            return template.format(**kwargs)
        except (KeyError, ValueError):
            return template
    return template


class MarkdownFormatter:
    """Markdown template formatter with i18n support."""

    def __init__(self, lang: str = "en"):
        self.lang = lang
        self._validate_lang()

    def _validate_lang(self):
        """Ensure language is supported."""
        if self.lang not in DEFAULT_MESSAGES:
            available = ", ".join(DEFAULT_MESSAGES.keys())
            console.print(
                f"[yellow]Warning: Language '{self.lang}' not supported, falling back to 'en'[/yellow]"
            )
            self.lang = "en"

    def get_default_template(self, version: str) -> str:
        """Generate default template with version."""
        title = get_message("default_template_title", self.lang, version=version)
        section = get_message(
            "default_template_section", self.lang, update_message="${{ UpdateMessage }}"
        )
        return f"# {title}\n\n{section}"

    def process_conditional_blocks(self, content: str, flags: Dict[str, bool]) -> str:
        """Process conditional blocks ${{ <name> : start }} ... ${{ end }}"""
        pattern = re.compile(
            r"\$\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*start\s*\}\}"
            r"(.*?)"
            r"\$\{\{\s*end\s*\}\}",
            flags=re.DOTALL,
        )

        def replace_block(match: re.Match) -> str:
            name = match.group(1)
            body = match.group(2)

            if name not in CONDITIONAL_KEYS:
                console.print(
                    f"[yellow]{get_message('conditional_key_error', self.lang, key=name)}[/yellow]"
                )
                return ""

            if not flags.get(name, False):
                return ""
            return body.strip("\n")

        for _ in range(NESTED_BLOCK_MAX_ITERATIONS):
            new_content, n = pattern.subn(replace_block, content)
            content = new_content
            if n == 0:
                break
        return content

    def process_placeholders(self, content: str, data: Dict[str, str]) -> str:
        """Replace placeholder variables in content."""
        replacements = {
            "${{ Version }}": data.get("Version", ""),
            "${{ Tag }}": data.get("Tag", ""),
            "${{ UpdateMessage }}": data.get("UpdateMessage", ""),
            "${{ ChangeLog }}": data.get("ChangeLog", ""),
            "${{ Commit }}": data.get("Commit", ""),
            "${{ ShortCommit }}": (
                data.get("Commit", "")[:7] if data.get("Commit") else ""
            ),
            "${{ Repository }}": data.get("Repository", ""),
            "${{ Date }}": data.get("Date", ""),
            "${{ PreviousTag }}": data.get("PreviousTag", ""),
        }

        for placeholder, value in replacements.items():
            content = content.replace(placeholder, value)

        return content

    def process_template(
        self,
        content: str,
        *,
        version: str,
        is_pre: bool,
        message: str,
        changelog: str,
        commit: str,
        repository: str,
        date: str,
        previous_tag: str,
        tag: str,
    ) -> str:
        """Process template content, replace placeholders and conditional blocks."""
        actual_tag = tag.strip() or f"v{version}"

        flags = {
            "isPreVersion": is_pre,
            "hasMessage": bool(message.strip()),
            "hasChangeLog": bool(changelog.strip()),
            "hasCommit": bool(commit.strip()),
            "hasRepository": bool(repository.strip()),
            "hasDate": bool(date.strip()),
            "hasPreviousTag": bool(previous_tag.strip()) and bool(repository.strip()),
        }
        content = self.process_conditional_blocks(content, flags)

        data = {
            "Version": version,
            "Tag": actual_tag,
            "UpdateMessage": message,
            "ChangeLog": changelog,
            "Commit": commit,
            "Repository": repository,
            "Date": date,
            "PreviousTag": previous_tag,
        }
        content = self.process_placeholders(content, data)

        return content


def format_output(content: str) -> str:
    """Clean output content: collapse multiple empty lines, remove leading/trailing whitespace."""
    lines = content.split("\n")
    result_lines: list[str] = []
    prev_empty = False

    for line in lines:
        is_empty = not line.strip()
        if is_empty and prev_empty:
            continue
        result_lines.append(line)
        prev_empty = is_empty

    while result_lines and not result_lines[0].strip():
        result_lines.pop(0)
    while result_lines and not result_lines[-1].strip():
        result_lines.pop()

    return "\n".join(result_lines)


def _read_text(path: Path, label: str, lang: str = "en") -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception as exc:
        console.print(
            f"[red]{get_message('error_read', lang, label=label, path=path, exc=exc)}[/red]"
        )
        sys.exit(1)


@click.command()
@click.option(
    "--file",
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
    required=False,
    help="Path to input Markdown template file",
)
@click.option(
    "--version",
    required=True,
    help="Version number, e.g., 0.1.0",
)
@click.option(
    "--pre/--no-pre",
    default=False,
    help="Specify if this is a pre-release version (default: --no-pre)",
)
@click.option(
    "--message",
    default="",
    help="Update message content, supports \\n for newlines; overridden by --changelog-file if both provided",
)
@click.option(
    "--changelog-file",
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
    required=False,
    help="ChangeLog file path, content will be injected into ${{ ChangeLog }} and ${{ UpdateMessage }}",
)
@click.option(
    "--commit",
    default="",
    help="Commit SHA for ${{ Commit }} / ${{ ShortCommit }}",
)
@click.option(
    "--repository",
    default="",
    help="Repository URL (e.g., https://github.com/owner/repo) for ${{ Repository }}",
)
@click.option(
    "--date",
    default="",
    help="Release date string for ${{ Date }}",
)
@click.option(
    "--previous-tag",
    default="",
    help="Previous version tag (e.g., v0.1.9) for comparison links using ${{ PreviousTag }}",
)
@click.option(
    "--tag",
    default="",
    help="Current tag literal (e.g., v1.0.4(pre)); falls back to v<Version> if empty",
)
@click.option(
    "--lang",
    default="en",
    type=click.Choice(["en", "zh"], case_sensitive=False),
    help="Language for output messages (default: en)",
)
def main(
    file: Optional[Path],
    version: str,
    pre: bool,
    message: str,
    changelog_file: Optional[Path],
    commit: str,
    repository: str,
    date: str,
    previous_tag: str,
    tag: str,
    lang: str,
):
    """Format Markdown release notes template.

    Supported placeholders:
      ${{ Version }}        Version number (e.g., 1.0.4)
      ${{ Tag }}            Tag literal (e.g., v1.0.4(pre), falls back to v<Version> if empty)
      ${{ UpdateMessage }}  Update message (priority: --changelog-file > --message)
      ${{ ChangeLog }}      ChangeLog file raw content
      ${{ Commit }}         Build commit
      ${{ ShortCommit }}     First 7 characters of build commit
      ${{ Repository }}     Repository URL
      ${{ Date }}           Release date
      ${{ PreviousTag }}    Previous tag (for comparison links)

    Supported conditional blocks (${{ <name> : start }}...${{ end }}):
      isPreVersion / hasMessage / hasChangeLog / hasCommit / hasRepository / hasDate / hasPreviousTag
    """

    formatter = MarkdownFormatter(lang)

    if file:
        template_content = _read_text(file, "template file", lang)
    elif message.strip():
        template_content = message
    else:
        console.print(f"[yellow]{get_message('warning_no_input', lang)}[/yellow]")
        template_content = formatter.get_default_template(version)

    changelog_text = ""
    if changelog_file:
        changelog_text = _read_text(changelog_file, "ChangeLog file", lang).strip()

    actual_message = message.replace("\\n", "\n")

    try:
        output_content = formatter.process_template(
            template_content,
            version=version,
            is_pre=pre,
            message=actual_message,
            changelog=changelog_text,
            commit=commit,
            repository=repository,
            date=date,
            previous_tag=previous_tag,
            tag=tag,
        )
        formatted_output = format_output(output_content)
    except Exception as exc:
        console.print(f"[red]{get_message('error_template', lang, exc=exc)}[/red]")
        sys.exit(1)

    print(formatted_output)


if __name__ == "__main__":
    main()
