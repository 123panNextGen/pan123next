# AGENTS.md - 项目笔记

## 项目概述

Flutter 桌面端 123云盘客户端，使用 Fluent UI + GetX。

## 关键文件

| 文件                                         | 用途                                                                                                                    |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `lib/common/api/session.dart`                | `NetSession` — Dio 封装，所有 API 调用、token 管理、请求/响应拦截器                                                     |
| `lib/common/api/model.dart`                  | 数据模型：`UserInfoModel`, `ApiReturnModel<T>`, `FileItemModel`, `FileListResponse`, `OpenUserInfoModel`, `VipInfo` 等  |
| `lib/common/api/extra.dart`                  | 工具函数：`loginWithUserInfo()`, `updateUserInfoSession()`, `logout()`                                                  |
| `lib/common/const.dart`                      | 常量：`apiBaseUrl`, `openApiBaseUrl`                                                                                    |
| `lib/common/data/neo/neo_db.dart`            | `NeoDb` — 多用户凭据持久化，基于 `FlutterSecureStorage`，`neo.*` 键前缀，替代原 `UserDb`                                |
| `lib/common/data/neo/neo_user.dart`          | `NeoUser` — 多用户数据模型（id/userName/password/authorization/uuid/device/openInfo 等）                                |
| `lib/common/data/base_db.dart`               | `BaseDb` — `SharedPreferences` 抽象数据库基类（仅 `AppDb` 使用）                                                        |
| `lib/common/app_session.dart`                | `AppSession` — 响应式主题/语言/登录状态，新增 `userSwitchSignal` 用于触发用户切换时重建                                 |
| `lib/pages/login/user_list_view.dart`        | 登录页用户列表组件，展示 NeoDb 中已保存用户，支持点击登录/右键删除                                                      |
| `lib/pages/login/view.dart`                  | 登录表单页面                                                                                                            |
| `lib/pages/login/control.dart`               | 登录控制逻辑：`getUserInfo()`, `login()`, `loginWithNeoUser()`                                                          |
| `lib/screens/login_screen.dart`              | 登录屏幕，根据 NeoDb 是否有用户决定展示用户列表或登录表单                                                               |
| `lib/pages/cloud/view.dart`                  | 云盘信息页（用户信息、空间、客户端信息），新增「其他账户」展示和切换                                                     |
| `lib/pages/cloud/control.dart`               | 云盘控制逻辑：`getCloudName()`, `switchToUser()`                                                                        |
| `lib/pages/file_list/file_list.dart`         | 文件列表页面，所有文件操作入口                                                                                          |

## 多用户模式

- `NeoDb` 管理多个用户凭据，每个用户以 `neo.user.{id}.xxx` 键独立存储
- 登录页：有已保存用户时展示用户列表 → 点击用户直接登录 or 添加新用户
- 云盘页：展示当前用户信息 +「其他账户」列表，点击切换
- 切换用户时递增 `AppSession.userSwitchSignal` → `MainScreen` 重建 → 子组件刷新数据

## API 架构

- **主 API**：`https://www.123pan.cn` (apiBaseUrl)
- **Open API**：`https://open-api.123pan.com` (openApiBaseUrl)
- 所有请求经过 Dio 拦截器链：请求拦截器添加 headers → 401响应拦截器 → LogInterceptor
- 401 时只显示 "登录会话已过期，请刷新"，不自动重试

## 关键模式

- `NetSession` 单例（GetX → `Get.find<NetSession>()`）
- `NeoDb` 单例（GetX → `Get.find<NeoDb>()`）
- API 方法统一返回 `ApiReturnModel<T>`，含 `apiCode`/`apiCodeEnum`/`msg`/`data`
- `ApiCode` 枚举：`success`, `fail`

## 遵循

以下内容必须遵循！！！！！！

自己润色、丰富提示词
自己拆分多个任务，分成不同目标逐个修改
并自己规划行动，仔细拆分，多次提前验证方案是否可行
如果有任何不确定的实现方案一定要进行询问
每次完成后自己头脑风暴，自己想象是否按照预期进行过程
每做完一次就进行一次提交，并且完善 AGENTS.md
隔一段时间进行上下文压缩，并且再次读取 AGENTS.md
最开始实现时单独将所有过程写到一个md文件中 (存到 doc/plan 中)

## 编译命令

```bash
flutter analyze
flutter build windows
```
