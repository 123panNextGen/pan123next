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
      showInfoBar(
        context,
        '错误',
        '请输入文件夹名称',
        InfoBarSeverity.error,
      );
      return;
    }
    Navigator.pop(context, fileName);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('新建文件夹'),
      content: InfoLabel(
        label: '请输入新文件夹的名称：',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextBox(
              controller: _fileNameController,
              placeholder: '文件夹名称',
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
        Button(
          onPressed: _createFile,
          child: const Text('创建'),
        ),
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
      title: const Text('确认删除文件'),
      content: const Text('确定要将所选文件移至回收站吗？'),
      actions: [
        FilledButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context, false),
        ),
        Button(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确定'),
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
      title: const Text('确认删除目录'),
      content: const Text('确定要将当前目录及其内容移至回收站吗？'),
      actions: [
        FilledButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context, false),
        ),
        Button(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class RenameFileDialog extends StatefulWidget {
  const RenameFileDialog({super.key, required this.fileName});

  final String fileName;

  @override
  State<RenameFileDialog> createState() => _RenameFileDialogState();
}

class _RenameFileDialogState extends State<RenameFileDialog> {
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _renameFile() async {
    final fileName = _fileNameController.text;
    if (fileName.isEmpty) {
      showInfoBar(
        context,
        '错误',
        '请输入新文件名',
        InfoBarSeverity.error,
      );
      return;
    }
    if (fileName == widget.fileName) {
      showInfoBar(
        context,
        '错误',
        '新文件名不能与原文件名相同',
        InfoBarSeverity.error,
      );
      return;
    }

    Navigator.pop(context, fileName);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('重命名文件'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('请输入新文件名：'),
          const SizedBox(height: 16),
          TextBox(
            controller: _fileNameController,
            placeholder: '新文件名',
          ),
        ],
      ),
      actions: [
        FilledButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context, null),
        ),
        Button(
          onPressed: _renameFile,
          child: const Text('确定'),
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
      title: const Text('下载链接'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('文件名：', style: const TextStyle(fontSize: 16)),
                Card(
                  padding: const EdgeInsets.symmetric(
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
                label: '下载链接：',
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
                                  Icon(FluentIcons.copy_24_regular),
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
                      style: const TextStyle(fontFamily: 'JetBrainsMono'),
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
          child: const Text('关闭'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
