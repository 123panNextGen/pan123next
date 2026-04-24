import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/get_platform.dart';
import 'package:window_manager/window_manager.dart';

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(final BuildContext context) {
    final theme = FluentTheme.of(context);

    return isDesktop()
        ? SizedBox(
            width: 138,
            height: 50,
            child: WindowCaption(
              brightness: theme.brightness,
              backgroundColor: Colors.transparent,
            ),
          )
        : const SizedBox.shrink();
  }
}
