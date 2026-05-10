import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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

  final UserDb userDb = UserDb();

  String? _urlError;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlFocusNode.requestFocus();
    });
    _savePathController.text = userDb.getValue('set.defaultDownloadPath') ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  /// 校验 URL 合法性，返回归一化后的 URL；非法返回 null。
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
      setState(() => _urlError = '请先输入合法的 URL（http/https）');
      return;
    }
    setState(() {
      _picking = true;
      _urlError = null;
    });

    String defaultDownloadPath =
        UserDb().getValue('set.defaultDownloadPath') ??
        await getDownloadsDirectory().then((dir) => dir?.path ?? '');

    try {
      final path = await FilePicker.saveFile(
        dialogTitle: '选择保存路径:',
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
      setState(() => _urlError = '请输入合法的 URL（http/https）');
      return;
    }
    if (_savePathController.text.isEmpty) {
      setState(() => _urlError = '请选择保存路径');
      return;
    }
    if (FileSystemEntity.isDirectorySync(_savePathController.text)) {
      showInfoBar(context, '错误', '请选择文件', InfoBarSeverity.error);
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
      title: const Text('添加新下载'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLabel(
            label: '下载链接',
            child: TextBox(
              controller: _urlController,
              focusNode: _urlFocusNode,
              placeholder: 'https://example.com/file.zip',
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
            label: '保存路径',
            child: Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _savePathController,
                    // readOnly: true,
                    placeholder: '尚未选择',
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
                          children: const [
                            Icon(FluentIcons.folder_open_24_regular),
                            SizedBox(width: 6),
                            Text('选择'),
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
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
        FilledButton(onPressed: _submit, child: const Text('开始下载')),
      ],
    );
  }
}
