import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import '../models/record.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class SharingService {
  final List<MedicalRecord> records;
  HttpServer? _server;

  SharingService({required this.records});

  Future<String> start() async {
    final ip = await NetworkInfo().getWifiIP() ?? '127.0.0.1';
    final router = Router();

    router.get('/', (Request req) => _handleIndex(req));
    router.get('/files/<filename>', (Request req, String filename) => _handleFile(req, filename));

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, AppConstants.localServerPort);
    return 'http://$ip:${AppConstants.localServerPort}';
  }

  void stop() {
    _server?.close(force: true);
    _server = null;
  }

  Response _handleIndex(Request req) {
    final html = _buildHtml();
    return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
  }

  Future<Response> _handleFile(Request req, String filename) async {
    for (final record in records) {
      for (final path in record.attachments) {
        if (p.basename(path) == filename) {
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final mime = lookupMimeType(path) ?? 'application/octet-stream';
            return Response.ok(bytes, headers: {'content-type': mime});
          }
        }
      }
    }
    return Response.notFound('Файл не найден');
  }

  String _buildHtml() {
    final recordsHtml = records.map((r) {
      final extraRows = r.extraData.entries.map((e) {
        return '<tr><td class="label">${_extraLabel(r.category, e.key)}</td><td>${_escape(e.value.toString())}</td></tr>';
      }).join();

      final attachmentsHtml = r.attachments.isNotEmpty
          ? '''<div class="attachments">
              ${r.attachments.map((path) {
                final name = p.basename(path);
                final isImg = ['.jpg', '.jpeg', '.png', '.webp'].any((e) => path.toLowerCase().endsWith(e));
                if (isImg) {
                  return '<a href="/files/$name" target="_blank"><img src="/files/$name" alt="$name"></a>';
                }
                return '<a href="/files/$name" target="_blank" class="file-link">📎 $name</a>';
              }).join('')}
            </div>'''
          : '';

      return '''
        <div class="record">
          <div class="record-header">
            <span class="category">${_escape(r.category.displayName)}</span>
            <span class="date">${AppFormatters.formatDate(r.date)}</span>
          </div>
          <h3>${_escape(r.title)}</h3>
          <table>
            $extraRows
          </table>
          ${r.notes != null && r.notes!.isNotEmpty ? '<p class="notes">${_escape(r.notes!)}</p>' : ''}
          $attachmentsHtml
        </div>
      ''';
    }).join('\n');

    return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>МоёЗдоровье — медицинские записи</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f0f9f8; color: #212121; }
    header { background: linear-gradient(135deg, #00897B, #00695C); color: white; padding: 20px; text-align: center; }
    header h1 { font-size: 22px; }
    header p { font-size: 13px; opacity: 0.8; margin-top: 4px; }
    .container { max-width: 800px; margin: 20px auto; padding: 0 16px; }
    .record { background: white; border-radius: 12px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    .record-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
    .category { background: #E0F2F1; color: #00695C; font-size: 12px; padding: 3px 10px; border-radius: 20px; font-weight: 600; }
    .date { font-size: 13px; color: #757575; }
    h3 { font-size: 18px; margin-bottom: 12px; color: #212121; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    td { padding: 4px 0; vertical-align: top; }
    td.label { color: #757575; width: 40%; padding-right: 8px; }
    .notes { margin-top: 10px; font-size: 13px; color: #424242; line-height: 1.6; background: #f9f9f9; padding: 10px; border-radius: 8px; }
    .attachments { margin-top: 12px; display: flex; flex-wrap: wrap; gap: 8px; }
    .attachments img { width: 80px; height: 80px; object-fit: cover; border-radius: 8px; border: 1px solid #e0e0e0; }
    .file-link { font-size: 13px; color: #00897B; text-decoration: none; background: #E0F2F1; padding: 4px 10px; border-radius: 6px; display: inline-block; }
    footer { text-align: center; padding: 20px; font-size: 12px; color: #9e9e9e; }
  </style>
</head>
<body>
  <header>
    <h1>МоёЗдоровье</h1>
    <p>Медицинские записи пациента · ${records.length} ${_recordWord(records.length)}</p>
  </header>
  <div class="container">
    $recordsHtml
  </div>
  <footer>Только для просмотра · Сгенерировано приложением МоёЗдоровье</footer>
</body>
</html>''';
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _recordWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'запись';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'записи';
    return 'записей';
  }

  String _extraLabel(dynamic category, String key) {
    final map = <String, String>{
      'lab': 'Лаборатория',
      'type': 'Тип',
      'body_area': 'Область тела',
      'clinic': 'Клиника',
      'doctor_name': 'Врач',
      'specialty': 'Специальность',
      'medications': 'Назначения',
      'vaccine': 'Вакцина',
      'dose': 'Доза',
      'next_dose': 'Следующая доза',
      'severity': 'Тяжесть',
    };
    return map[key] ?? key;
  }
}
