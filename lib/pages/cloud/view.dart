import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/api/extra.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/data/neo/neo_db.dart';
import 'package:pan123next/common/data/neo/neo_user.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/pages/cloud/control.dart';
import 'package:pan123next/pages/cloud/dialog.dart';
import 'package:pan123next/widgets/card.dart';
import 'package:pan123next/widgets/show_info_bar.dart';
import 'model.dart';

class CloudInfoView extends StatefulWidget {
  const CloudInfoView({super.key});

  @override
  State<CloudInfoView> createState() => _CloudInfoViewState();
}

class _CloudInfoViewState extends State<CloudInfoView> {
  final NetSession _session = Get.find();
  final NeoDb _neoDb = Get.find();
  List<NeoUser> _otherUsers = [];
  bool _rememberPassword = false;

  @override
  void initState() {
    super.initState();
    _loadOtherUsers();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final current = await _neoDb.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _rememberPassword = current?.rememberPassword ?? false;
    });
  }

  Future<void> _loadOtherUsers() async {
    final currentId = _neoDb.currentUserId;
    final all = await _neoDb.getAllUsers();
    if (!mounted) return;
    setState(() {
      _otherUsers = all.where((u) => u.id != currentId).toList();
    });
  }

  OpenUserInfoModel? get openInfo {
    if (_session.userInformation == null) {
      showInfoBar(context, '警告', '用户信息为空', InfoBarSeverity.warning);
      return null;
    }

    return _session.userInformation!.openInfo;
  }

  CloudNameModel get cloudName {
    return getCloudName(openInfo);
  }

  int get spaceAll {
    return (openInfo?.spacePermanent ?? 0) + (openInfo?.spaceTemp ?? 0);
  }

  double get spaceValue {
    if (spaceAll != 0) {
      return (openInfo?.spaceUsed ?? 0) / spaceAll * 100;
    } else {
      return 0;
    }
  }

  Future<void> refreshUser() async {
    final userInfo = _session.userInformation;
    if (userInfo == null) {
      showInfoBar(context, '错误', '用户信息为空', InfoBarSeverity.error);
      return;
    }

    final result = await ExtraApiService.to.loginWithUserInfo(userInfo);

    if (result.apiCodeEnum == ApiCode.success) {
      await ExtraApiService.to.updateUserInfoSession(result.data!);
      setState(() {});

      if (!mounted) return;
      showInfoBar(context, '成功', '刷新成功', InfoBarSeverity.success);
    } else {
      if (!mounted) return;
      showInfoBar(context, '刷新失败', result.msg, InfoBarSeverity.error);
    }
  }

  Future<void> _onSwitchToUser(NeoUser target) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('切换账户'),
        content: Text('确定切换到账户「${target.userName}」吗？'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('切换'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await switchToUser(target);
    if (!mounted) return;
    if (result.apiCodeEnum == ApiCode.success) {
      showInfoBar(context, '成功', result.msg, InfoBarSeverity.success);
    } else {
      showInfoBar(context, '切换失败', result.msg, InfoBarSeverity.error);
    }
  }

  Future<void> logout() async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutContentDialog(),
    );

    if (!mounted || !(result ?? false)) return;

    await ExtraApiService.to.logout();
    setState(() {});

    if (!mounted) return;
    showInfoBar(context, '成功', '已退出登录', InfoBarSeverity.success);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '云盘',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16.0),
                RounderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(FluentIcons.person_note_24_regular),
                          const SizedBox(width: 8.0),
                          Text('用户信息', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          openInfo?.headImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Image.network(
                                    openInfo!.headImage,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(FluentIcons.person_24_regular, size: 64),

                          const SizedBox(width: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cloudName.nickName ?? '空用户名',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(width: 8.0),
                                  openInfo?.vip ?? false
                                      ? InfoBadge(
                                          source: Text('VIP'),
                                          color: theme.accentColor
                                              .defaultBrushFor(
                                                theme.brightness,
                                              ),
                                        )
                                      : Container(),
                                ],
                              ),
                              Text(
                                formatPhoneNumber(cloudName.name ?? ''),
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16.0),
                RounderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(FluentIcons.arrow_autofit_width_24_regular),
                          const SizedBox(width: 8.0),
                          Text('空间信息', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: ProgressBar(value: spaceValue)),
                          const SizedBox(width: 8),
                          Text('${spaceValue.toStringAsFixed(2)}%'),
                          const SizedBox(width: 8),
                          Text(
                            '${formatSize((openInfo?.spaceUsed ?? 0))} / ${formatSize(spaceAll)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16.0),
                RounderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(FluentIcons.apps_24_regular),
                          const SizedBox(width: 8.0),
                          Text('客户端信息', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('记住密码:'),
                          const SizedBox(width: 8.0),
                          InfoBadge(
                            source: Text(_rememberPassword ? '开启' : '关闭'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_otherUsers.isNotEmpty) ...[
                  const SizedBox(height: 16.0),
                  RounderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(FluentIcons.people_24_regular),
                            const SizedBox(width: 8.0),
                            Text('其他账户', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._otherUsers.map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  FluentIcons.person_24_regular,
                                  size: 28,
                                  color: theme.accentColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    obfuscatePhoneNumber(user.userName),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Button(
                                  onPressed: () => _onSwitchToUser(user),
                                  child: const Text('切换'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16.0),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(FluentIcons.settings_24_regular),
                          const SizedBox(width: 8.0),
                          Text('用户操作', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Icon(FluentIcons.arrow_clockwise_24_regular),
                          const SizedBox(width: 8.0),
                          Expanded(child: Text('刷新 Token (重新登录)')),
                          Button(onPressed: refreshUser, child: Text('刷新')),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Icon(FluentIcons.dismiss_circle_24_regular),
                          const SizedBox(width: 8.0),
                          Expanded(child: Text('退出登录')),
                          FilledButton(onPressed: logout, child: Text('退出')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
