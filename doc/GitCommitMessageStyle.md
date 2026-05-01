# Git Commit Message 规范

在您使用 `git commit` 时,
 需确保您的提交信息符合标准规范.

在本项目中, 规范的格式为:

```plain
TYPE[(target)] [(#ISSUE/PR/BUG ID)]: TITLE

[
SUBTITLE

FILE_NAME:
DESC
- Fix 1
- Feat 2
] || [
SUBTITLE ...
]
```

注解:

- `[]`: 可选内容
- `||`: 或者
- `TYPE`: 类别, 包含 `feat, fix, to, doc, chore, style, refactor, test, version`
- `target`: 解决的内容
