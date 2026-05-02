import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';

Future<void> showInfoBar(
  BuildContext context,
  String titleText,
  String info,
  InfoBarSeverity severity,
) async {
  await displayInfoBar(
    context,
    builder: (context, close) {
      return InfoBar(
        title: Text(titleText),
        content: SelectableText(info),
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.copy_24_regular),
              onPressed: () async {
                Clipboard.setData(ClipboardData(text: info));
              },
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(WindowsIcons.clear), onPressed: close),
          ],
        ),
        severity: severity,
      );
    },
  );
}
