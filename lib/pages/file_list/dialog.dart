import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:pan123next/widgets/show_info_bar.dart';

class AddFolderDialog extends StatefulWidget {
  const AddFolderDialog({super.key});

  @override
  State<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<AddFolderDialog> {
  final TextEditingController _fileNameController = TextEditingController();
  final FocusNode _fileNameFocusNode = FocusNode();

  @override
  void dispose() {
    _fileNameController.dispose();
    _fileNameFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fileNameFocusNode.requestFocus();
    });
  }

  void _createFile() async {
    final fileName = _fileNameController.text;
    if (fileName.isEmpty) {
      showInfoBar(context, '错误', '请输入文件夹名', InfoBarSeverity.error);
      return;
    }
    Navigator.pop(context, fileName);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('新建文件夹'),
      content: InfoLabel(
        label: '在当前目录下新建文件夹',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextBox(
              controller: _fileNameController,
              placeholder: '请输入文件夹名',
              focusNode: _fileNameFocusNode,
              onSubmitted: (_) => _createFile(),
            ),
          ],
        ),
      ),

      actions: [
        FilledButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
        Button(onPressed: _createFile, child: Text('新建')),
      ],
    );
  }
}

class TrashContentDialog extends StatefulWidget {
  const TrashContentDialog({super.key});

  @override
  State<TrashContentDialog> createState() => _TrashContentDialogState();
}

class _TrashContentDialogState extends State<TrashContentDialog> {
  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('删除'),
      content: const Text('确认删除选中文件吗?\n删除后的文件将会放入回收站中'),
      actions: [
        FilledButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context, false),
        ),
        Button(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
        ),
      ],
    );
  }
}

class TrashCurrentDialog extends StatefulWidget {
  const TrashCurrentDialog({super.key});

  @override
  State<TrashCurrentDialog> createState() => _TrashCurrentDialogState();
}

class _TrashCurrentDialogState extends State<TrashCurrentDialog> {
  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('删除'),
      content: const Text('确认删除当前目录吗?\n删除后的文件将会放入回收站中'),
      actions: [
        FilledButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context, false),
        ),
        Button(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
        ),
      ],
    );
  }
}

class ShowDownloadLinkDialog extends StatefulWidget {
  const ShowDownloadLinkDialog({
    super.key,
    required this.fileName,
    required this.link,
  });

  final String fileName;
  final String link;

  @override
  State<ShowDownloadLinkDialog> createState() => _ShowDownloadLinkDialogState();
}

class _ShowDownloadLinkDialogState extends State<ShowDownloadLinkDialog> {
  bool isCopying = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      title: const Text('获取下载链接结果'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('获取文件名: ', style: TextStyle(fontSize: 16)),
                Card(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(widget.fileName),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: InfoLabel(
                label: '结果',
                child: Column(
                  children: [
                    Button(
                      style: ButtonStyle(
                        backgroundColor: isCopying
                            ? WidgetStatePropertyAll(
                                theme.accentColor.defaultBrushFor(
                                  theme.brightness,
                                ),
                              )
                            : null,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isCopying
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FluentIcons.checkmark_24_regular,
                                    color: theme
                                        .resources
                                        .textOnAccentFillColorPrimary,
                                    size: 18,
                                  ),
                                ],
                              )
                            : const Row(
                                children: [
                                  WindowsIcon(FluentIcons.copy_24_regular),
                                  SizedBox(width: 6),
                                  Text('复制'),
                                ],
                              ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.link));
                        setState(() => isCopying = true);
                        Future<void>.delayed(
                          const Duration(milliseconds: 1500),
                          () {
                            isCopying = false;
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.link,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono Nerd Font Mono',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          child: const Text('确定'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
