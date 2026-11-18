import '../models/photo_item.dart';

/// 单张照片的类型启发式分类（截图/自拍/文档/视频）。
/// 连拍、大文件、早期照片这类需要全局视角的分类在 AnalysisService 中处理。
class PhotoClassifier {
  PhotoClassifier._();

  static bool isVideo(PhotoItem p) => p.isVideo;

  /// 截图：来源目录含 screenshot 等关键字，或宽高比接近手机屏幕且尺寸为屏幕分辨率。
  static bool isScreenshot(PhotoItem p) {
    final path = (p.relativePath ?? p.title).toLowerCase();
    if (path.contains('screenshot') ||
        path.contains('screen') ||
        path.contains('截屏') ||
        path.contains('截图') ||
        path.contains('屏幕')) {
      return true;
    }
    final ar = p.aspectRatio;
    if ((ar >= 0.40 && ar <= 0.62) || (ar >= 1.6 && ar <= 2.4)) {
      final px = p.width * p.height;
      if (px >= 1500000 && px <= 20000000) return true;
    }
    return false;
  }

  /// 文档：来源目录含 document，或宽高比接近纸张（A4 约 0.707）。
  static bool isDocument(PhotoItem p) {
    final path = (p.relativePath ?? p.title).toLowerCase();
    if (path.contains('document') || path.contains('doc')) return true;
    final ar = p.aspectRatio;
    return ar >= 0.55 && ar <= 1.1;
  }

  /// 自拍（弱启发式，AI 人脸识别可进一步补充）。
  static bool isSelfie(PhotoItem p) {
    final path = (p.relativePath ?? p.title).toLowerCase();
    return path.contains('selfie') ||
        path.contains('weixin') ||
        path.contains('wechat') ||
        path.contains('weibo') ||
        path.contains('face');
  }
}
