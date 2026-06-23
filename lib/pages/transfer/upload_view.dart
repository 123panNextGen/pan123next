import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class UploadView extends StatelessWidget {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.arrow_upload_24_regular,
            size: 48,
            color: FluentTheme.of(context).inactiveColor,
          ),
          const SizedBox(height: 16),
          Text(
            '上传功能开发中...',
            style: FluentTheme.of(context).typography.subtitle,
          ),
        ],
      ),
    );
  }
}
