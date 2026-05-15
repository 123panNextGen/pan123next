import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:pan123next/common/i18n/i18n.dart';
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
      showInfoBar(context, 'file.list.error'.i, 'dialog.new.folder.placeholder'.i, InfoBarSeverity.error);
      return;
    }
    Navigator.pop(context, fileName);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text('dialog.new.folder.title'.i),
      content: InfoLabel(
        label: 'dialog.new.folder.label'.i,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextBox(
              controller: _fileNameController,
              placeholder: 'dialog.new.folder.placeholder'.i,
              focusNode: _fileNameFocusNode,
              onSubmitted: (_) => _createFile(),
            ),
          ],
        ),
      ),

      actions: [
        FilledButton(
          child: Text('dialog.new.folder.cancel'.i),
          onPressed: () => Navigator.pop(context),
        ),
        Button(onPressed: _createFile, child: Text('dialog.new.folder.create'.i)),
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
      title: Text('dialog.trash.file.title'.i),
      content: Text('dialog.trash.file.content'.i),
      actions: [
        FilledButton(
          child: Text('dialog.trash.file.cancel'.i),
          onPressed: () => Navigator.pop(context, false),
        ),
        Button(
          onPressed: () => Navigator.pop(context, true),
          child: Text('dialog.trash.file.confirm'.i),
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
      title: Text('dialog.trash.current.title'.i),
      content: Text('dialog.trash.current.content'.i),
      actions: [
        FilledButton(
          child: Text('dialog.trash.current.cancel'.i),
          onPressed: () => Navigator.pop(context, false),
        ),
        Button(
          onPressed: () => Navigator.pop(context, true),
          child: Text('dialog.trash.current.confirm'.i),
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
      title: Text('dialog.link.title'.i),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('dialog.link.file.name'.i, style: TextStyle(fontSize: 16)),
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
                label: 'dialog.link.result'.i,
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
                            : Row(
                                children: [
                                  Icon(FluentIcons.copy_24_regular),
                                  SizedBox(width: 6),
                                  Text('dialog.link.copy'.i),
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
                      style: TextStyle(fontFamily: 'JetBrainsMono'),
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
          child: Text('dialog.link.confirm'.i),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
