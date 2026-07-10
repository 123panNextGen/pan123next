# 多用户模式实现记录

## 目标
为 123云盘 Flutter 桌面客户端添加多用户模式：
- 登录页展示已保存用户列表，点击切换
- 云盘页展示其他用户，支持切换
- 使用 NeoDb 替代原 UserDb

## 实现阶段

### Phase 1 — NeoDb 数据层 (`eddb981`)
- 创建 `lib/common/data/neo/neo_user.dart`：NeoUser 数据模型，含 id/userName/password/authorization/uuid/device/openInfo 等字段
- 创建 `lib/common/data/neo/neo_db.dart`：NeoDb 存储类，基于 FlutterSecureStorage
  - 每个用户独立 key：`neo.user.{id}.{field}`
  - 用户索引：`neo.userIds` (JSON 数组)
  - 当前用户：`neo.currentUserId`
  - 方法：CRUD、当前用户管理、lastLogin 按降序排序
- 给 model.dart 补充 VipInfo/DeveloperInfo/OpenUserInfoModel 的 toJson()
- 在 main.dart 注册 NeoDb 到 GetX

### Phase 2-3 — 登录页用户列表 + 登录流程 (`f6afb0a`)
- 创建 `lib/pages/login/user_list_view.dart`：用户列表组件
  - 卡片列表展示所有 NeoDb 用户
  - 点击用户 → loginWithNeoUser() 直接登录
  - 右击菜单 → 删除用户
  - 「添加新用户」按钮 → 切换到登录表单
- 修改 `lib/pages/login/control.dart`：
  - 新增 loginWithNeoUser() 函数
  - login() 成功后同步写入 NeoDb（通过 _saveToNeoDb）
- 修改 `lib/pages/login/view.dart`：LoginInputPage 添加可选 onCancel 回调
- 修改 `lib/screens/login_screen.dart`：
  - 添加 userList/loginForm 双模式
  - 有用户时展示列表，无用户时直接显示表单
  - 「取消」按钮返回用户列表

### Phase 4 — 云盘页展示其他用户 (`21a3c4d`)
- 修改 `lib/common/app_session.dart`：添加 userSwitchSignal（RxInt）
- 修改 `lib/app.dart`：MainScreen 使用 ValueKey 绑定 userSwitchSignal，切换时重建
- 修改 `lib/pages/cloud/control.dart`：新增 switchToUser() 函数
  - 设置 NetSession → 获取 OpenUserInfo → 保存到 NeoDb → 递增信号
- 修改 `lib/pages/cloud/view.dart`：
  - 新增「其他账户」RounderCard，展示非当前用户
  - 点击「切换」→ 确认对话框 → 执行 switchToUser

### Phase 5-6 — 移除 UserDb 依赖 (`85e29bc`)
- `extra.dart`：移除 UserDb 字段，logout 改为仅清除令牌
- `login/control.dart`：完全使用 NeoDb，getUserInfo 改为异步
- `login/view.dart`：适配异步 getUserInfo
- `cloud/view.dart`：移除 UserDb，改用 NeoDb 读取偏好
- `app_session.dart`：clearSession 改为 NeoDb
- `main.dart`：移除 UserDb 注册

### Phase 7 — 删除 UserDb (`9b7a2b1`)
- 删除 `lib/common/data/user.dart`

## 关键架构决策

- **用户 ID**：使用 userName（passport）作为用户标识，天然唯一
- **切换触发**：AppSession.userSwitchSignal 递增 → ValueKey 变化 → MainScreen 重建
- **Token 过期**：loginWithNeoUser 检测空 token 返回错误，用户可重新登录
- **Logout 行为**：只清除当前用户 token，保留用户列表供下次选择

## 数据流

```
启动 → NeoDb.initDb()
     → 有 currentUser?
        → 否 → LoginScreen → userListView(有用户) / loginForm(无用户)
        → 是 → (在登录页) → 点击用户 → loginWithNeoUser

用户列表:
  ├─ 点击保存用户 → loginWithNeoUser → 成功 → MainScreen
  │                                  → 失败 → 显示错误
  └─ 添加新用户 → loginForm → login() → 写入NeoDb → MainScreen

云盘页:
  ├─ 当前用户信息卡片
  └─ 其他账户列表 → 切换 → confirm → switchToUser → 重建MainScreen
```
