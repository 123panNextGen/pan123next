<!--# Pan123 Next Release ${{ Version }}-->

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

${{ hasPreviousTag : start }}
> 与上版本比对：[${{ PreviousTag }}...${{ Tag }}](${{ Repository }}/compare/${{ PreviousTag }}...${{ Tag }})
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
| Android | [![Android Download](https://img.shields.io/badge/Android-Any-brightgreen?style=for-the-badge&logo=android)](${{ Repository }}/releases/download/${{ Tag }}/Pan123Next-Android.apk) |
| Windows | [![Windows Download](https://img.shields.io/badge/Windows-x86__64-0078D1?style=for-the-badge&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU%2BV2luZG93czwvdGl0bGU%2BPHBhdGggZmlsbD0iI0ZGRkZGRiIgZD0iTTAsMEgxMS4zNzdWMTEuMzcySDBaTTEyLjYyMywwSDI0VjExLjM3MkgxMi42MjNaTTAsMTIuNjIzSDExLjM3N1YyNEgwWm0xMi42MjMsMEgyNFYyNEgxMi42MjMiLz48L3N2Zz4%3D)](${{ Repository }}/releases/download/${{ Tag }}/Pan123Next-Windows.zip) |
| macOS   | [![MacOS Download](https://img.shields.io/badge/MacOS-Any-white?style=for-the-badge&logo=apple)](${{ Repository }}/releases/download/${{ Tag }}/Pan123Next-macos.zip) |
| Linux   | [![Linux Download](https://img.shields.io/badge/Linux-x86__64-white?style=for-the-badge&logo=linux&logoColor=white)](${{ Repository }}/releases/download/${{ Tag }}/Pan123Next-Linux.zip) |

## 安装与使用

- Windows / Linux：解压压缩包后直接运行可执行文件。
- macOS：解压后将 `.app` 拖入 Applications 目录；若被系统拦截可在「系统设置 → 隐私与安全」中放行。
- Android：直接安装 APK 文件，可能需要在系统设置中允许「安装未知来源应用」。

${{ hasRepository : start }}
## 反馈与支持

如遇问题，欢迎在 [${{ Repository }}/issues](${{ Repository }}/issues) 提交反馈。
${{ end }}
