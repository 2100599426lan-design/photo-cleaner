import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 从单张缩略图计算出的图像特征。
class ImageFeatures {
  const ImageFeatures({required this.dHash, required this.blurVariance});

  /// 差异哈希，64 位二进制字符串。
  final String dHash;

  /// 清晰度评分（拉普拉斯方差），越大越清晰。
  final double blurVariance;
}

/// 纯图像算法：差异哈希 + 拉普拉斯清晰度。
class ImageProcessor {
  ImageProcessor._();

  /// 从缩略图字节解码并计算特征；失败返回 null。
  static ImageFeatures? fromBytes(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return ImageFeatures(
        dHash: computeDHash(decoded),
        blurVariance: computeBlurVariance(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  /// 差异哈希（dHash）：灰度缩放到 9x8，比较水平相邻像素生成 64 bit。
  static String computeDHash(img.Image src) {
    final g = img.grayscale(
      img.copyResize(
        src,
        width: 9,
        height: 8,
        interpolation: img.Interpolation.average,
      ),
    );
    final sb = StringBuffer();
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final left = g.getPixel(x, y).r.toInt();
        final right = g.getPixel(x + 1, y).r.toInt();
        sb.write(left > right ? '1' : '0');
      }
    }
    return sb.toString();
  }

  /// 拉普拉斯方差：对 256x256 灰度图做拉普拉斯卷积并求方差，值越小越模糊。
  static double computeBlurVariance(img.Image src) {
    final g = img.grayscale(
      img.copyResize(
        src,
        width: 256,
        height: 256,
        interpolation: img.Interpolation.average,
      ),
    );
    final w = g.width;
    final h = g.height;
    var sum = 0.0;
    var sumSq = 0.0;
    var n = 0;
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final lap = g.getPixel(x, y).r.toInt() * -4 +
            g.getPixel(x - 1, y).r.toInt() +
            g.getPixel(x + 1, y).r.toInt() +
            g.getPixel(x, y - 1).r.toInt() +
            g.getPixel(x, y + 1).r.toInt();
        sum += lap;
        sumSq += lap * lap;
        n++;
      }
    }
    if (n == 0) return 0.0;
    final mean = sum / n;
    final variance = sumSq / n - mean * mean;
    return variance < 0 ? 0.0 : variance;
  }

  /// 汉明距离（逐字符比较两个等长哈希）。
  static int hammingDistance(String a, String b) {
    final len = a.length < b.length ? a.length : b.length;
    var d = 0;
    for (var i = 0; i < len; i++) {
      if (a.codeUnitAt(i) != b.codeUnitAt(i)) d++;
    }
    return d;
  }
}
