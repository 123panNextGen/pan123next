import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/api/extra.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/format.dart';
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
    // 缓存 getter 结果，避免重复调用和多次 showInfoBar
    final info = openInfo;

    if (info == null) {
      return CloudNameModel(name: '', nickName: '空用户名');
    }

    late String nickName;
    late String name;

    if (info.nickname.isNotEmpty) {
      nickName = info.nickname;
      if (info.passport.isNotEmpty) {
        name = formatPhoneNumber(info.passport); // nickName 为用户名, name 为手机号
      } else if (info.mail.isNotEmpty) {
        name = info.mail; // nickName 为用户名, name 为邮箱
      } else {
        name = ''; // nickName 为用户名, name 为空
      }
    } else if (info.passport.isNotEmpty) {
      nickName = formatPhoneNumber(info.passport);
      if (info.mail.isNotEmpty) {
        name = info.mail; // nickName 为手机号, name 为邮箱
      } else {
        name = ''; // nickName 为手机号, name 为空
      }
    } else if (info.mail.isNotEmpty) {
      nickName = info.mail;
      name = ''; // nickName 为邮箱, name 为空
    } else {
      nickName = '空用户名';
      name = '';
    }

    return CloudNameModel(name: name, nickName: nickName);
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
                          Text(
                            formatPhoneNumber(cloudName.name ?? ''),
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
