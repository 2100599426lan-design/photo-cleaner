import 'package:photo_manager/photo_manager.dart';

/// 媒体类型。
enum MediaType { photo, video }

/// 一张照片/视频的封装，附带后续计算得到的属性。
class PhotoItem {
  PhotoItem({
    required this.id,
    required this.asset,
    required this.type,
    required this.title,
    required this.created,
    required this.width,
    required this.height,
    this.relativePath,
    this.sizeBytes,
  });

  final String id;
  final AssetEntity asset;
  final MediaType type;
  final String title;
  final DateTime? created;
  final int width;
  final int height;

  /// 相对存储路径（如 DCIM/Screenshots），类型分类的启发式来源。
  final String? relativePath;

  /// 文件大小（字节），异步从 fileSize 填充；null 表示尚未获取。
  int? sizeBytes;

  /// 差异哈希（dHash，64 位二进制字符串），重复/相似检测用，懒加载后赋值。
  String? dHash;

  /// 清晰度评分（拉普拉斯方差），越大越清晰；空表示未计算。
  double? blurScore;

  /// AI 识别得到的标签（英文，如 people / landscape / food）。
  Set<String> labels = {};

  /// 是否为视频。
  bool get isVideo => type == MediaType.video;

  /// 宽高比（width / height），用于类型启发式判断。
  double get aspectRatio => height == 0 ? 1.0 : width / height;

  factory PhotoItem.fromAsset(AssetEntity a) {
    return PhotoItem(
      id: a.id,
      asset: a,
      type: a.type == AssetType.video ? MediaType.video : MediaType.photo,
      title: a.title ?? '',
      created: a.createDateTime,
      width: a.width,
      height: a.height,
      relativePath: a.relativePath,
    );
  }
}
