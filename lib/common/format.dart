import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:pan123next/common/api/model.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

String formatSize(int size) {
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  if (size < 1024 * 1024 * 1024) {
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return dateString;
  }
}

Widget getFileIcon(FileItemModel item) {
  if (item.isFolder) {
    return Icon(FluentIcons.folder_24_regular, size: 24);
  }

  final ext = item.fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
      return Icon(FluentIcons.document_pdf_24_regular, size: 24);
    case 'txt':
      return Icon(WindowsIcons.document, size: 24);
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
      return Icon(FluentIcons.image_24_regular, size: 24);
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'flv':
      return Icon(FluentIcons.video_24_regular, size: 24);
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return Icon(FluentIcons.folder_zip_24_regular, size: 24);
    case 'doc':
    case 'docx':
    case 'md':
      return Icon(FluentIcons.document_text_24_regular, size: 24);
    case 'xls':
    case 'xlsx':
      return Icon(FluentIcons.document_table_24_regular, size: 24);
    case 'ppt':
    case 'pptx':
      return Icon(FluentIcons.document_queue_24_regular, size: 24);
    default:
      return Icon(FluentIcons.document_24_regular, size: 24);
  }
}
