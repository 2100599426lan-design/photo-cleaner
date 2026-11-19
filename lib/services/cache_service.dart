import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 分析结果本地缓存：把 dHash / 清晰度 / AI 标签持久化到磁盘，
/// 下次打开直接复用，避免重复分析。
class CacheService {
  CacheService._();

  static const _fileName = 'analysis_cache.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<void> save(Map<String, dynamic> data) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(data));
    } catch (_) {
      // 缓存写入失败不影响主流程。
    }
  }

  static Future<Map<String, dynamic>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return <String, dynamic>{};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
