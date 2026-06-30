import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class DownloadListView extends StatelessWidget {
  const DownloadListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.arrow_download_24_regular,
            size: 48,
            color: FluentTheme.of(context).inactiveColor,
          ),
          const SizedBox(height: 16),
          Text(
            '下载已改为调用浏览器打开',
            style: FluentTheme.of(context).typography.subtitle,
          ),
        ],
      ),
    );
  }
}
