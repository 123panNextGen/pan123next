import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/widgets/show_info_bar.dart';

class AddFolderDialog extends StatefulWidget {
  const AddFolderDialog({super.key});

  @override
  State<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<AddFolderDialog> {
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
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
            TextBox(controller: _fileNameController, placeholder: '请输入文件夹名'),
          ],
        ),
      ),

      actions: [
        FilledButton(
          child: Text('取消'),
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
