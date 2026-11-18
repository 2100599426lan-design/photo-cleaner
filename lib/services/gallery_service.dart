import 'package:photo_manager/photo_manager.dart';

/// 相册读取与权限服务。
class GalleryService {
  GalleryService._();

  /// 请求相册权限。
  static Future<PermissionState> requestPermission() {
    return PhotoManager.requestPermissionExtend();
  }

  /// 加载“全部照片/视频”资产，带进度回调。
  static Future<List<AssetEntity>> loadAllAssets({
    void Function(int done, int total)? onProgress,
  }) async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common, // 照片 + 视频
      onlyAll: true, // 仅“所有媒体”这个汇总相册
    );
    if (paths.isEmpty) return <AssetEntity>[];

    final album = paths.first;
    final total = await album.assetCountAsync;

    final assets = <AssetEntity>[];
    const pageSize = 300;
    var page = 0;
    while (true) {
      final chunk = await album.getAssetListPaged(page: page, size: pageSize);
      assets.addAll(chunk);
      onProgress?.call(assets.length, total);
      if (chunk.length < pageSize) break;
      page++;
    }
    return assets;
  }
}
