import 'package:fluent_ui/fluent_ui.dart';

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
        content: Text(info),
        action: IconButton(
          icon: const WindowsIcon(WindowsIcons.clear),
          onPressed: close,
        ),
        severity: severity,
      );
    },
  );
}
