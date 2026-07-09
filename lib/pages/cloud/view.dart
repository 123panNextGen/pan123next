import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/api/extra.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/widgets/setting_card.dart';
import 'package:pan123next/widgets/show_info_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '云盘',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16.0),
        SettingCard(
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
                            openInfo?.nickname != null
                                ? openInfo!.nickname
                                : '空用户名',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 8.0),
                          Text(
                            formatPhoneNumber(openInfo?.passport ?? ''),
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      Text('123网盘用户 (其实这段还没来得及写..)'),
                    ],
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
                      final result = await ExtraApiService.to.loginWithUserInfo(
                        _session.userInformation!,
                      );

                      if (result.apiCodeEnum == ApiCode.success) {
                        await ExtraApiService.to.updateUserInfoSession(
                          result.data!,
                        );
                        setState(() {});

                        if (!mounted) return;
                        showInfoBar(
                          context,
                          '成功',
                          '刷新成功',
                          InfoBarSeverity.success,
                        );
                      } else {
                        if (!mounted) return;
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
