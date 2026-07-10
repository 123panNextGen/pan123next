# AGENTS.md - 项目笔记

## 项目概述

Flutter 桌面端 123云盘客户端，使用 Fluent UI + GetX。

## 关键文件

| 文件 | 用途 |
|---|---|
| `lib/common/api/session.dart` | `NetSession` — Dio 封装，所有 API 调用、token 管理、请求/响应拦截器 |
| `lib/common/api/model.dart` | 数据模型：`UserInfoModel`, `ApiReturnModel<T>`, `FileItemModel`, `FileListResponse`, `OpenUserInfoModel`, `VipInfo`, `DeveloperInfo` |
| `lib/common/api/extra.dart` | 工具函数：`loginWithUserInfo()`, `updateUserInfoSession()` |
| `lib/common/const.dart` | 常量：`apiBaseUrl`, `openApiBaseUrl` |
| `lib/common/data/user.dart` | `UserDb` — `FlutterSecureStorage` 持久化用户凭据 |
| `lib/common/data/base_db.dart` | `BaseDb` — `SharedPreferences` 抽象数据库基类 |
| `lib/pages/file_list/file_list.dart` | 文件列表页面，所有文件操作入口 |
| `lib/pages/login/control.dart` | 登录控制逻辑 |

## API 架构

- **主 API**：`https://www.123pan.cn` (apiBaseUrl)
- **Open API**：`https://open-api.123pan.com` (openApiBaseUrl)
- 所有请求经过 Dio 拦截器链：请求拦截器添加 headers → 401响应拦截器 → LogInterceptor
- 401 时只显示 "登录会话已过期，请刷新"，不自动重试

## 关键模式

- `NetSession` 单例（GetX → `Get.find<NetSession>()`）
- `UserDb` 单例（GetX → `Get.find<UserDb>()`）
- API 方法统一返回 `ApiReturnModel<T>`，含 `apiCode`/`apiCodeEnum`/`msg`/`data`
- `ApiCode` 枚举：`success`, `fail`

## 编译命令

```bash
flutter analyze
flutter build windows
```
