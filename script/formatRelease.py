#!/usr/bin/env python3
"""Markdown 格式化工具 - 使用模板引擎处理版本发布信息"""

import re
import sys
from pathlib import Path
from typing import Optional

import click
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

# 初始化 Rich console
console = Console()


def process_template(
    content: str,
    version: str,
    is_pre: bool,
    message: str,
) -> str:
    """处理模板内容，替换占位符"""

    # 替换版本号
    content = content.replace("${{ Version }}", version)

    # 处理预览版本的条件块
    content = process_conditional_blocks(content, is_pre)

    # 替换更新说明
    content = content.replace("${{ UpdateMessage }}", message)

    return content


def process_conditional_blocks(content: str, is_pre: bool) -> str:
    """处理条件块 ${{ isPreVersion : start }} ... ${{ end }}"""

    # 匹配条件块的正则表达式
    pattern = r"\$\{\{\s*isPreVersion\s*:\s*start\s*\}\}(.*?)\$\{\{\s*end\s*\}\}"

    def replace_block(match):
        if is_pre:
            # 如果是预览版本，保留内容（去除缩进）
            return match.group(1).strip()
        else:
            # 如果不是预览版本，移除整个块
            return ""

    # 使用正则替换，支持跨行匹配
    return re.sub(pattern, replace_block, content, flags=re.DOTALL)


def format_output(content: str) -> str:
    """清理输出内容，去除多余的空行"""
    # 去除连续的空行（保留最多一个空行）
    lines = content.split("\n")
    result_lines = []
    prev_empty = False

    for line in lines:
        is_empty = not line.strip()
        if is_empty and prev_empty:
            continue
        result_lines.append(line)
        prev_empty = is_empty

    # 去除开头的空行
    while result_lines and not result_lines[0].strip():
        result_lines.pop(0)

    # 去除结尾的空行
    while result_lines and not result_lines[-1].strip():
        result_lines.pop()

    return "\n".join(result_lines)


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
    help="输入更新说明内容，支持 \\n 换行符",
)
def main(file: Optional[Path], version: str, pre: bool, message: str):
    """格式化 Markdown 发布说明模板

    支持处理以下占位符：
    - ${{ Version }} - 版本号
    - ${{ UpdateMessage }} - 更新说明
    - ${{ isPreVersion : start }}...${{ end }} - 条件块
    """

    # 读取模板文件或使用直接输入的 message
    if file:
        try:
            template_content = file.read_text(encoding="utf-8")
        except Exception as e:
            console.print(f"[red]错误：无法读取文件 {file} - {e}[/red]")
            sys.exit(1)
    else:
        # 如果没有指定文件，使用 message 作为模板内容
        # 这种情况下，message 应该包含完整的模板
        if not message.strip():
            console.print(
                "[yellow]警告：未指定 --file 且 --message 为空，将使用默认模板[/yellow]"
            )
            template_content = "# Pan123 Next Release ${{ Version }}\n\n## 更新说明\n\n${{ UpdateMessage }}"
        else:
            template_content = message

    # 处理消息中的转义换行符
    # 如果 message 是作为单独参数传入的，需要处理其中的 \n
    actual_message = (
        message.replace("\\n", "\n")
        if not file
        else message.replace(
            "\\n",
            "\n",
        )
    )

    # 处理模板
    try:
        output_content = process_template(
            template_content, version, pre, actual_message
        )
        formatted_output = format_output(output_content)
    except Exception as e:
        console.print(f"[red]处理模板时出错：{e}[/red]")
        sys.exit(1)

    # 使用 Rich 显示输出
    # console.print("\n[bold cyan]📝 生成的 Markdown 内容：[/bold cyan]\n")

    # 使用 Syntax 高亮显示 Markdown
    syntax = Syntax(
        formatted_output,
        "markdown",
        theme="monokai",
        line_numbers=False,
    )
    # console.print(Panel(syntax, border_style="green", title="输出结果"))

    # 同时打印原始文本（方便复制）
    # console.print("\n[bold cyan]📋 纯文本输出（可直接复制）：[/bold cyan]\n")
    print(formatted_output)

    # 输出详细信息
    console.print("\n[dim]---[/dim]")
    console.print(f"[dim]版本：{version}[/dim]")
    console.print(f"[dim]预览版：{'是' if pre else '否'}[/dim]")
    if file:
        console.print(f"[dim]模板文件：{file}[/dim]")


if __name__ == "__main__":
    main()
