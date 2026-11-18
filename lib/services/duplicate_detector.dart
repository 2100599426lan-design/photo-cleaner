import '../models/photo_item.dart';
import 'image_processor.dart';

/// 重复/相似照片检测：基于 dHash 汉明距离的贪心分组。
class DuplicateDetector {
  DuplicateDetector._();

  /// 输入已计算 dHash 的照片，返回相似分组（每组至少 2 张）。
  /// [threshold]：64 位中允许的位差异数，越大越“宽松”，默认 12。
  static List<List<PhotoItem>> groupSimilar(
    List<PhotoItem> items, {
    int threshold = 12,
  }) {
    final withHash = items.where((e) => e.dHash != null).toList();
    final groups = <List<PhotoItem>>[];
    for (final item in withHash) {
      List<PhotoItem>? matched;
      for (final g in groups) {
        if (ImageProcessor.hammingDistance(item.dHash!, g.first.dHash!) <=
            threshold) {
          matched = g;
          break;
        }
      }
      if (matched != null) {
        matched.add(item);
      } else {
        groups.add([item]);
      }
    }
    return groups.where((g) => g.length >= 2).toList();
  }
}
