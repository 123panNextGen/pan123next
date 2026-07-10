import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/api/extra.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/pages/cloud/control.dart';
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

                          // const SizedBox(width: 8.0),
                          // Text(
                          //   formatPhoneNumber(cloudName.name ?? ''),
                          //   style: TextStyle(fontStyle: FontStyle.italic),
                          // ),
                          const SizedBox(width: 8.0),
                          openInfo?.vip ?? false
                              ? InfoBadge(
                                  source: Text('VIP'),
                                  color: theme.accentColor.defaultBrushFor(
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
                      // Text(
                      //   '${formatSize(openInfo?.spaceUsed ?? 0)} / ${formatSize((openInfo?.spacePermanent ?? 0) + (openInfo?.spaceTemp ?? 0))}',
                      // ),
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
                  Expanded(
                    child: ProgressBar(
                      value: (openInfo?.spaceUsed ?? 0) / spaceAll * 100,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${((openInfo?.spaceUsed ?? 0) / spaceAll * 100).toStringAsFixed(2)}%',
                  ),
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
                  Expanded(child: Text('重新登录')),
                  Button(
                    child: Text('刷新'),
                    onPressed: () async {
                      final userInfo = _session.userInformation;
                      if (userInfo == null) {
                        showInfoBar(
                          context,
                          '错误',
                          '用户信息为空',
                          InfoBarSeverity.error,
                        );
                        return;
                      }

                      final result = await ExtraApiService.to.loginWithUserInfo(
                        userInfo,
                      );

                      if (result.apiCodeEnum == ApiCode.success) {
                        await ExtraApiService.to.updateUserInfoSession(
                          result.data!,
                        );
                        setState(() {});

                        if (!context.mounted) return;
                        showInfoBar(
                          context,
                          '成功',
                          '刷新成功',
                          InfoBarSeverity.success,
                        );
                      } else {
                        if (!context.mounted) return;
                        showInfoBar(
                          context,
                          '刷新失败',
                          result.msg,
                          InfoBarSeverity.error,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
