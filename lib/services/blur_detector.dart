import '../models/photo_item.dart';

/// 模糊/低质量照片检测：基于拉普拉斯方差阈值。
class BlurDetector {
  BlurDetector._();

  /// 判断是否模糊。[threshold] 为拉普拉斯方差阈值，越小越模糊，需按机型微调。
  static bool isBlurry(PhotoItem p, {double threshold = 120.0}) {
    final v = p.blurScore;
    if (v == null) return false;
    return v < threshold;
  }
}
