#!/usr/bin/env python3
"""Markdown 格式化工具 - 使用模板引擎处理版本发布信息"""

import re
import sys
from pathlib import Path
from typing import Dict, Optional

import click
from rich.console import Console

# 初始化 Rich console
console = Console()


# ---------------------------------------------------------------------------
# 模板处理
# ---------------------------------------------------------------------------


def process_conditional_blocks(content: str, flags: Dict[str, bool]) -> str:
    """处理条件块 ${{ <name> : start }} ... ${{ end }}

    支持的条件名由 flags 字典提供。每个 key 对应一个布尔值，True 表示
    保留块内的内容，False 则整段移除。

    示例：
        ${{ isPreVersion : start }} ... ${{ end }}
        ${{ hasChangeLog : start }} ... ${{ end }}
    """

    pattern = re.compile(
        r"\$\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*start\s*\}\}"
        r"(.*?)"
        r"\$\{\{\s*end\s*\}\}",
        flags=re.DOTALL,
    )

    def replace_block(match: re.Match) -> str:
        name = match.group(1)
        body = match.group(2)
        # 未注册的条件名按"始终移除"处理，避免模板出现未替换占位符
        if not flags.get(name, False):
            return ""
        # 去除块两端首尾的纯空白行（保留内部缩进）
        return body.strip("\n")

    # 反复处理以支持简单嵌套（最多 5 次足够）
    for _ in range(5):
        new_content, n = pattern.subn(replace_block, content)
        content = new_content
        if n == 0:
            break
    return content


def process_template(
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
    """处理模板内容，替换占位符与条件块"""

    # tag 为空时回退到 v<Version>，确保下载/对比链接始终可拼接
    actual_tag = tag.strip() or f"v{version}"

    # 条件块在替换占位符之前处理：被裁掉的块里包含的占位符无需替换
    flags = {
        "isPreVersion": is_pre,
        "hasMessage": bool(message.strip()),
        "hasChangeLog": bool(changelog.strip()),
        "hasCommit": bool(commit.strip()),
        "hasRepository": bool(repository.strip()),
        "hasDate": bool(date.strip()),
        # 比对链接同时依赖上一个 tag 与仓库地址，否则链接无意义
        "hasPreviousTag": bool(previous_tag.strip()) and bool(repository.strip()),
    }
    content = process_conditional_blocks(content, flags)

    # 简单字符串占位符
    replacements = {
        "${{ Version }}": version,
        "${{ Tag }}": actual_tag,
        "${{ UpdateMessage }}": message,
        "${{ ChangeLog }}": changelog,
        "${{ Commit }}": commit,
        "${{ ShortCommit }}": commit[:7] if commit else "",
        "${{ Repository }}": repository,
        "${{ Date }}": date,
        "${{ PreviousTag }}": previous_tag,
    }
    for key, value in replacements.items():
        content = content.replace(key, value)

    return content


def format_output(content: str) -> str:
    """清理输出内容：折叠多余空行，去除首尾空行"""
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


def _read_text(path: Path, label: str) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception as exc:  # pragma: no cover - 直接报错退出
        console.print(f"[red]错误：无法读取{label} {path} - {exc}[/red]")
        sys.exit(1)


# ---------------------------------------------------------------------------
# CLI 入口
# ---------------------------------------------------------------------------


@click.command()
@click.option(
    "--file",
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
    required=False,
    help="指定输入的 Markdown 模板文件路径",
)
@click.option(
    "--version",
    required=True,
    help="指定版本号，例如 0.1.0",
)
@click.option(
    "--pre/--no-pre",
    default=False,
    help="指定是否为预览版本（默认为 --no-pre）",
)
@click.option(
    "--message",
    default="",
    help="更新说明内容，支持 \\n 换行符；与 --changelog-file 同时存在时被覆盖",
)
@click.option(
    "--changelog-file",
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
    required=False,
    help="ChangeLog 文件路径，整段内容会注入 ${{ ChangeLog }} 与 ${{ UpdateMessage }}",
)
@click.option(
    "--commit",
    default="",
    help="构建对应的 commit SHA，用于 ${{ Commit }} / ${{ ShortCommit }}",
)
@click.option(
    "--repository",
    default="",
    help="仓库地址（如 https://github.com/owner/repo），用于 ${{ Repository }}",
)
@click.option(
    "--date",
    default="",
    help="发布日期字符串，用于 ${{ Date }}",
)
@click.option(
    "--previous-tag",
    default="",
    help="上一个版本 tag（如 v0.1.9），用于渲染比对链接 ${{ PreviousTag }}",
)
@click.option(
    "--tag",
    default="",
    help="当前 tag 字面量（如 v1.0.4(pre)）；为空时回退到 v<Version>",
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
):
    """格式化 Markdown 发布说明模板。

    支持的占位符：
      ${{ Version }}        版本号（如 1.0.4）
      ${{ Tag }}            tag 字面量（如 v1.0.4(pre)，缺省回退到 v<Version>）
      ${{ UpdateMessage }}  更新说明（优先 --changelog-file，其次 --message）
      ${{ ChangeLog }}      ChangeLog 文件原始内容
      ${{ Commit }}         构建 commit
      ${{ ShortCommit }}    构建 commit 前 7 位
      ${{ Repository }}     仓库地址
      ${{ Date }}           发布日期
      ${{ PreviousTag }}    上一个 tag（用于比对链接）

    支持的条件块（${{ <name> : start }}...${{ end }}）：
      isPreVersion / hasMessage / hasChangeLog / hasCommit / hasRepository / hasDate / hasPreviousTag
    """

    # 1. 加载模板
    if file:
        template_content = _read_text(file, "模板文件")
    elif message.strip():
        template_content = message
    else:
        console.print(
            "[yellow]警告：未指定 --file 且 --message 为空，将使用默认模板[/yellow]"
        )
        template_content = (
            "# Pan123 Next Release ${{ Version }}\n\n## 更新说明\n\n${{ UpdateMessage }}"
        )

    # 2. 加载 ChangeLog 内容
    changelog_text = ""
    if changelog_file:
        changelog_text = _read_text(changelog_file, "ChangeLog 文件").strip()

    # 3. UpdateMessage 与 ChangeLog 互不替代：模板内通过条件块选用其一
    actual_message = message.replace("\\n", "\n")

    # 4. 处理模板
    try:
        output_content = process_template(
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
        console.print(f"[red]处理模板时出错：{exc}[/red]")
        sys.exit(1)

    print(formatted_output)


if __name__ == "__main__":
    main()
