import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileService {
  static const _uuid = Uuid();

  static Future<String> saveAttachment(File file) async {
    final dir = await _attachmentsDir();
    final ext = p.extension(file.path);
    final name = '${_uuid.v4()}$ext';
    final dest = File(p.join(dir.path, name));
    await file.copy(dest.path);
    return dest.path;
  }

  static Future<void> deleteAttachment(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<Directory> _attachmentsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'attachments'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static bool isImage(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  static bool isPdf(String path) => p.extension(path).toLowerCase() == '.pdf';

  static String fileName(String path) => p.basename(path);
}
