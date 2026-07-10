import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/neo/neo_db.dart';
import 'package:pan123next/common/data/neo/neo_user.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/pages/login/control.dart' as control;
import 'package:pan123next/widgets/show_info_bar.dart';

class UserListView extends StatefulWidget {
  const UserListView({
    super.key,
    required this.onLoginSuccess,
    required this.onAddNewUser,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback onAddNewUser;

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  List<NeoUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final neoDb = Get.find<NeoDb>();
    final users = await neoDb.getAllUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _onUserTap(NeoUser user) async {
    setState(() => _loading = true);
    try {
      final result = await control.loginWithNeoUser(user);
      if (!mounted) return;
      if (result.apiCodeEnum == ApiCode.success) {
        widget.onLoginSuccess();
      } else {
        showInfoBar(context, '登录失败', result.msg, InfoBarSeverity.error);
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      showInfoBar(context, '登录失败', e.toString(), InfoBarSeverity.error);
      setState(() => _loading = false);
    }
  }

  Future<void> _onDeleteUser(NeoUser user) async {
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('删除账户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('删除账户「${obfuscatePhoneNumber(user.userName)}」需要验证密码：'),
            const SizedBox(height: 8),
            PasswordBox(placeholder: '请输入密码', controller: passwordController),
          ],
        ),
        actions: [
          Button(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty || !mounted) return;

    setState(() => _loading = true);

    final verified = await control.verifyPassword(user, password);
    if (!mounted) return;

    if (!verified) {
      showInfoBar(context, '验证失败', '密码错误，无法删除', InfoBarSeverity.error);
      setState(() => _loading = false);
      return;
    }

    final neoDb = Get.find<NeoDb>();
    await neoDb.deleteUser(user.id);
    if (!mounted) return;
    showInfoBar(context, '成功', '已删除账户', InfoBarSeverity.success);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: ProgressRing());
    }

    return Center(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择账户',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _users.isEmpty
                  ? GestureDetector(
                      onTap: widget.onAddNewUser,
                      child: const Center(
                        child: Text('暂无保存的账户，点击添加'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _UserCard(
                          user: user,
                          onTap: () => _onUserTap(user),
                          onDelete: () => _onDeleteUser(user),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: widget.onAddNewUser,
                  child: const Text('添加新用户'),
                ),
                const SizedBox(width: 8),
                Button(onPressed: control.exitProgram, child: const Text('退出')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatefulWidget {
  final NeoUser user;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  final _flyoutController = FlyoutController();
  final _targetKey = GlobalKey();

  void _showMenu(Offset position) {
    _flyoutController.showFlyout<void>(
      position: position,
      builder: (context) {
        return MenuFlyout(
          items: [
            MenuFlyoutItem(
              onPressed: () {
                Flyout.of(context).close();
                widget.onDelete();
              },
              leading: const Icon(FluentIcons.dismiss_24_regular),
              text: const Text('删除账户'),
            ),
          ],
        );
      },
    );
  }

  void _onMoreTap() {
    final targetContext = _targetKey.currentContext;
    if (targetContext == null) return;
    final box = targetContext.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(
      Offset(box.size.width, 0),
      ancestor: Navigator.of(context).context.findRenderObject(),
    );
    _showMenu(pos);
  }

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final openInfo = widget.user.openInfo;
    final displayName = openInfo?.nickname.isNotEmpty == true
        ? openInfo!.nickname
        : widget.user.userName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  FluentIcons.person_24_regular,
                  size: 40,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        obfuscatePhoneNumber(widget.user.userName),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (openInfo?.vip == true)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InfoBadge(
                      source: const Text('VIP'),
                      color: theme.accentColor.defaultBrushFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                FlyoutTarget(
                  key: _targetKey,
                  controller: _flyoutController,
                  child: IconButton(
                    icon: const Icon(FluentIcons.more_vertical_24_regular),
                    onPressed: _onMoreTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
