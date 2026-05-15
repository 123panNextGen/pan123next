import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/i18n/i18n.dart';
import 'package:pan123next/common/data/user.dart';
import 'package:pan123next/widgets/show_info_bar.dart';
import 'package:path_provider/path_provider.dart';

class AddDownloadResult {
  final String url;
  final String savePath;

  const AddDownloadResult({required this.url, required this.savePath});
}

class AddDownloadDialog extends StatefulWidget {
  const AddDownloadDialog({super.key});

  @override
  State<AddDownloadDialog> createState() => _AddDownloadDialogState();
}

class _AddDownloadDialogState extends State<AddDownloadDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _savePathController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  String? _urlError;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlFocusNode.requestFocus();
    });
    _savePathController.text =
        Get.find<UserDb>().getValue('set.defaultDownloadPath') ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  String? _validatedUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }
    if (uri.host.isEmpty) return null;
    return trimmed;
  }

  String _suggestedFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.last.isNotEmpty) {
        return Uri.decodeComponent(segments.last);
      }
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _pickSavePath() async {
    final url = _validatedUrl(_urlController.text);
    if (url == null) {
      setState(() => _urlError = 'add.download.invalid.url'.i);
      return;
    }
    setState(() {
      _picking = true;
      _urlError = null;
    });

    String defaultDownloadPath =
        Get.find<UserDb>().getValue('set.defaultDownloadPath') ??
        await getDownloadsDirectory().then((dir) => dir?.path ?? '');

    try {
      final path = await FilePicker.saveFile(
        dialogTitle: 'file.list.save.path.title'.i,
        fileName: _suggestedFileName(url),
        initialDirectory: defaultDownloadPath,
      );
      if (path != null && path.isNotEmpty) {
        setState(() => _savePathController.text = path);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _submit() {
    final url = _validatedUrl(_urlController.text);
    if (url == null) {
      setState(() => _urlError = 'add.download.invalid.url'.i);
      return;
    }
    if (_savePathController.text.isEmpty) {
      setState(() => _urlError = 'add.download.select.path'.i);
      return;
    }
    if (FileSystemEntity.isDirectorySync(_savePathController.text)) {
      showInfoBar(context, 'file.list.error'.i, 'add.download.select.file'.i, InfoBarSeverity.error);
      return;
    }

    Navigator.pop(
      context,
      AddDownloadResult(url: url, savePath: _savePathController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text('add.download.title'.i),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLabel(
            label: 'add.download.url.label'.i,
            child: TextBox(
              controller: _urlController,
              focusNode: _urlFocusNode,
              placeholder: 'add.download.url.placeholder'.i,
              maxLines: 1,
              onChanged: (_) {
                if (_urlError != null) setState(() => _urlError = null);
              },
              onSubmitted: (_) {
                if (_savePathController.text.isEmpty) {
                  _pickSavePath();
                } else {
                  _submit();
                }
              },
            ),
          ),
          if (_urlError != null) ...[
            const SizedBox(height: 4),
            Text(
              _urlError!,
              style: TextStyle(
                color: theme.resources.systemFillColorCritical,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          InfoLabel(
            label: 'add.download.path.label'.i,
            child: Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _savePathController,
                    placeholder: 'add.download.path.placeholder'.i,
                  ),
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: _picking ? null : _pickSavePath,
                  child: _picking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: ProgressRing(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(FluentIcons.folder_open_24_regular),
                            const SizedBox(width: 6),
                            Text('add.download.choose'.i),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Button(
          child: Text('add.download.cancel'.i),
          onPressed: () => Navigator.pop(context),
        ),
        FilledButton(onPressed: _submit, child: Text('add.download.start'.i)),
      ],
    );
  }
}
