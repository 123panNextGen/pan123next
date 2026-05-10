# Pan123 Next Release ${{ Version }}

${{ isPreVersion : start }}
> [!WARNING]
> 该版本仍处于预览版本，可能存在不稳定的行为，请谨慎在生产环境使用。
${{ end }}

${{ hasDate : start }}
> 发布日期：`${{ Date }}`
${{ end }}

${{ hasCommit : start }}
> 构建提交：[`${{ ShortCommit }}`](${{ Repository }}/commit/${{ Commit }})
${{ end }}

## 更新内容

${{ hasChangeLog : start }}
${{ ChangeLog }}
${{ end }}

${{ hasMessage : start }}
${{ UpdateMessage }}
${{ end }}

## 下载

| 平台 | 文件 |
| --- | --- |
| Android | [`Pan123Next-Android.apk`](${{ Repository }}/releases/download/v${{ Version }}/Pan123Next-Android.apk) |
| Windows | [`Pan123Next-Windows.zip`](${{ Repository }}/releases/download/v${{ Version }}/Pan123Next-Windows.zip) |
| macOS   | [`Pan123Next-macos.zip`](${{ Repository }}/releases/download/v${{ Version }}/Pan123Next-macos.zip) |
| Linux   | [`Pan123Next-Linux.zip`](${{ Repository }}/releases/download/v${{ Version }}/Pan123Next-Linux.zip) |

## 安装与使用

- Windows / Linux：解压压缩包后直接运行可执行文件。
- macOS：解压后将 `.app` 拖入 Applications 目录；若被系统拦截可在「系统设置 → 隐私与安全」中放行。
- Android：直接安装 APK 文件，可能需要在系统设置中允许「安装未知来源应用」。

${{ hasRepository : start }}
## 反馈与支持

如遇问题，欢迎在 [${{ Repository }}/issues](${{ Repository }}/issues) 提交反馈。
${{ end }}
