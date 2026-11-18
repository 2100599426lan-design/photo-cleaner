import 'package:photo_manager/photo_manager.dart';

import '../models/photo_item.dart';

/// 删除结果。
class DeleteResult {
  const DeleteResult({
    required this.successIds,
    required this.failed,
    required this.total,
  });

  final List<String> successIds;
  final int failed;
  final int total;

  int get success => successIds.length;
}

/// 删除服务：调用系统编辑器删除，Android 11+ 会自动移入回收站。
class DeleteService {
  DeleteService._();

  static Future<DeleteResult> deleteItems(List<PhotoItem> items) async {
    final ids = items.map((e) => e.id).toList();
    List<String> deleted;
    try {
      // Android 11 (API 30)+ 会自动移入系统回收站；更低版本为直接删除。
      deleted = await PhotoManager.editor.deleteWithIds(ids);
    } catch (_) {
      deleted = const [];
    }
    return DeleteResult(
      successIds: deleted,
      failed: items.length - deleted.length,
      total: items.length,
    );
  }
}
