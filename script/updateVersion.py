#!/usr/bin/env python3
"""快速更新项目版本号并同步依赖"""

import re
import subprocess
import sys
from pathlib import Path

import click

# 设置控制台编码为 UTF-8
if sys.platform == "win32":
    import codecs

    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.buffer, "strict")
    sys.stderr = codecs.getwriter("utf-8")(sys.stderr.buffer, "strict")


def update_pyproject_toml(version: str, project_dir: Path) -> None:
    """更新 pyproject.toml 中的版本号"""
    pyproject_path = project_dir / "pyproject.toml"
    content = pyproject_path.read_text(encoding="utf-8")

    # 匹配 version = "x.x.x" 格式
    pattern = r'version\s*=\s*"([^"]+)"'
    match = re.search(pattern, content)

    if match:
        old_version = match.group(1)
        content = content.replace(
            f'version = "{old_version}"', f'version = "{version}"'
        )
        pyproject_path.write_text(content, encoding="utf-8")
        click.echo(f"✓ 更新 pyproject.toml: {old_version} -> {version}")
    else:
        click.echo("✗ 未找到 pyproject.toml 中的版本号", err=True)
        sys.exit(1)


def update_pubspec_yaml(version: str, project_dir: Path) -> None:
    """更新 pubspec.yaml 中的版本号"""
    pubspec_path = project_dir / "pubspec.yaml"
    content = pubspec_path.read_text(encoding="utf-8")

    # 匹配 version: x.x.x+x 格式
    pattern = r"version:\s*(\d+\.\d+\.\d+)(\+\d+)?"
    match = re.search(pattern, content)

    if match:
        base_version = match.group(1)
        build_number = match.group(2)

        # 保留原有的构建号，如果没有则添加+0
        if build_number:
            new_version = f"{version}{build_number}"
        else:
            new_version = f"{version}+0"

        old_version = match.group(0)
        content = content.replace(old_version, f"version: {new_version}")
        pubspec_path.write_text(content, encoding="utf-8")
        click.echo(f"✓ 更新 pubspec.yaml: {old_version} -> {new_version}")
    else:
        click.echo("✗ 未找到 pubspec.yaml 中的版本号", err=True)
        sys.exit(1)


def run_uv_sync(project_dir: Path) -> None:
    """执行 uv sync 同步依赖"""
    click.echo("执行 uv sync 同步依赖...")
    result = subprocess.run(
        ["uv", "sync"],
        cwd=project_dir,
        shell=True,
    )

    if result.returncode != 0:
        click.echo("✗ uv sync 执行失败", err=True)
        sys.exit(1)

    click.echo("✓ uv sync 执行成功")


def run_flutter_pub_get(project_dir: Path) -> None:
    """执行 flutter pub get 同步依赖"""
    click.echo("执行 flutter pub get 同步依赖...")
    result = subprocess.run(
        ["flutter", "pub", "get"],
        cwd=project_dir,
        shell=True,
    )

    if result.returncode != 0:
        click.echo("✗ flutter pub get 执行失败", err=True)
        sys.exit(1)

    click.echo("✓ flutter pub get 执行成功")


def get_current_version(project_dir: Path) -> str | None:
    """获取当前版本号（优先从 pubspec.yaml 读取）"""
    pubspec_path = project_dir / "pubspec.yaml"
    if pubspec_path.exists():
        content = pubspec_path.read_text(encoding="utf-8")
        match = re.search(r"version:\s*(\d+\.\d+\.\d+)", content)
        if match:
            return match.group(1)

    pyproject_path = project_dir / "pyproject.toml"
    if pyproject_path.exists():
        content = pyproject_path.read_text(encoding="utf-8")
        match = re.search(r'version\s*=\s*"(\d+\.\d+\.\d+)"', content)
        if match:
            return match.group(1)

    return None


@click.command(
    help="快速更新项目版本号并同步依赖\n\n"
    "VERSION: 新版本号，格式为 x.x.x (例如: 0.1.7)"
)
@click.argument(
    "version",
    required=False,
    default=None,
)
@click.option(
    "--get",
    "get_version",
    is_flag=True,
    default=False,
    help="仅获取当前版本号（不执行更新）",
)
@click.option(
    "--no-sync",
    is_flag=True,
    default=False,
    help="跳过依赖同步（不执行 uv sync 和 flutter pub get）",
)
@click.option(
    "--project-dir",
    type=click.Path(exists=True, file_okay=False, dir_okay=True, path_type=Path),
    default=None,
    help="项目根目录，默认为当前目录",
)
def main(
    version: str | None,
    get_version: bool,
    no_sync: bool,
    project_dir: Path | None,
) -> None:
    """更新项目版本号并同步依赖"""

    # 确定项目目录
    if project_dir is None:
        project_dir = Path.cwd()

    # --get 模式：仅获取并输出版本号
    if get_version:
        current = get_current_version(project_dir)
        if current:
            click.echo(current)
        else:
            click.echo("✗ 未找到版本号", err=True)
            sys.exit(1)
        return

    # 更新模式需要 version 参数
    if version is None:
        click.echo("✗ 请指定版本号，或使用 --get 获取当前版本", err=True)
        sys.exit(1)

    # 验证版本号格式
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        click.echo("✗ 版本号格式错误，应为 x.x.x (例如: 0.1.7)", err=True)
        sys.exit(1)

    click.echo(f"项目目录: {project_dir}")
    click.echo(f"新版本号: {version}")
    click.echo()

    # 更新版本号
    update_pyproject_toml(version, project_dir)
    update_pubspec_yaml(version, project_dir)

    # 同步依赖
    if not no_sync:
        click.echo()
        run_uv_sync(project_dir)
        run_flutter_pub_get(project_dir)
    else:
        click.echo()
        click.echo("跳过依赖同步 (--no-sync)")

    click.echo()
    click.echo("✓ 版本更新完成！")


if __name__ == "__main__":
    main()
