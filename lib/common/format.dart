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

IconData getFileIconDataBySuffix(String suffix) {
  switch (suffix.toLowerCase()) {
    case 'pdf':
      return FluentIcons.document_pdf_24_regular;
    case 'txt':
      return WindowsIcons.document;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
      return FluentIcons.image_24_regular;
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'flv':
      return FluentIcons.video_24_regular;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return FluentIcons.folder_zip_24_regular;
    case 'doc':
    case 'docx':
    case 'md':
      return FluentIcons.document_text_24_regular;
    case 'xls':
    case 'xlsx':
      return FluentIcons.document_table_24_regular;
    case 'ppt':
    case 'pptx':
      return FluentIcons.document_queue_24_regular;
    default:
      return FluentIcons.document_24_regular;
  }
}

Widget getFileIconBySuffix(String suffix) {
  return Icon(getFileIconDataBySuffix(suffix), size: 24);
}

Widget getFileIcon(FileItemModel item) {
  if (item.isFolder) {
    return Icon(FluentIcons.folder_24_regular, size: 24);
  }

  final ext = item.fileName.split('.').last;
  return getFileIconBySuffix(ext);
}
