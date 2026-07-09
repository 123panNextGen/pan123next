import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:pan123next/widgets/setting_card.dart';

class CloudInfoView extends StatefulWidget {
  const CloudInfoView({super.key});

  @override
  State<CloudInfoView> createState() => _CloudInfoViewState();
}

class _CloudInfoViewState extends State<CloudInfoView> {
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
            children: [Text('用户名')],
          ),
        ),
      ],
    );
  }
}
