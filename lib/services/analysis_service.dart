import 'dart:async';

import 'package:photo_manager/photo_manager.dart';

import '../models/filter_category.dart';
import '../models/photo_item.dart';
import '../state/gallery_state.dart';
import 'blur_detector.dart';
import 'duplicate_detector.dart';
import 'image_processor.dart';
import 'photo_classifier.dart';

/// 分析聚合服务：遍历照片、计算特征，并填充各分类缓存。
class AnalysisService {
  AnalysisService._();

  /// 完整分析。AI 内容识别较重，单独通过 AiLabeler 触发，不在此处执行。
  static Future<void> analyzeAll(
    GalleryState state, {
    void Function(double progress, String message)? onProgress,
  }) async {
    final photos = state.photos;
    final total = photos.length;
    if (total == 0) return;

    final screenshots = <PhotoItem>[];
    final selfies = <PhotoItem>[];
    final documents = <PhotoItem>[];
    final videos = <PhotoItem>[];
    final blurry = <PhotoItem>[];
    final large = <PhotoItem>[];
    final old = <PhotoItem>[];

    // 1) 类型 + 元数据（快，无需解码）。
    for (final p in photos) {
      if (PhotoClassifier.isVideo(p)) videos.add(p);
      if (PhotoClassifier.isScreenshot(p)) screenshots.add(p);
      if (PhotoClassifier.isSelfie(p)) selfies.add(p);
      if (PhotoClassifier.isDocument(p)) documents.add(p);
      if ((p.sizeBytes ?? 0) >= 50 * 1024 * 1024) large.add(p);
      if (p.created != null &&
          p.created!.isBefore(
            DateTime.now().subtract(const Duration(days: 365)),
          )) {
        old.add(p);
      }
    }

    // 2) 连拍：按拍摄时间聚类。
    final bursts = detectBursts(photos);

    // 3) 逐张取缩略图，计算 dHash + 清晰度。
    for (var i = 0; i < total; i++) {
      final p = photos[i];
      onProgress?.call((i + 1) / total, '分析照片 ${i + 1}/$total');
      final thumb = await p.asset.thumbnailDataWithSize(
        const ThumbnailSize.square(256),
      );
      if (thumb != null) {
        final f = ImageProcessor.fromBytes(thumb);
        if (f != null) {
          p.dHash = f.dHash;
          p.blurScore = f.blurVariance;
        }
      }
      // 每 20 张让出事件循环，保持 UI 流畅。
      if (i % 20 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    // 4) 模糊标记。
    for (final p in photos) {
      if (BlurDetector.isBlurry(p)) blurry.add(p);
    }

    // 5) 重复/相似分组（拍平为列表供网格展示）。
    final dupGroups = DuplicateDetector.groupSimilar(photos);
    final duplicates = dupGroups.expand((g) => g).toList();

    // 6) 统一排序：模糊最前、大文件最前、早期照片最前。
    blurry.sort((a, b) => (a.blurScore ?? 0).compareTo(b.blurScore ?? 0));
    large.sort((a, b) => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));
    old.sort((a, b) => (a.created ?? DateTime(0)).compareTo(b.created ?? DateTime(0)));
    screenshots.sort(byCreatedAsc);
    selfies.sort(byCreatedAsc);
    documents.sort(byCreatedAsc);
    videos.sort(byCreatedAsc);
    bursts.sort(byCreatedAsc);
    duplicates.sort(byCreatedAsc);

    // 7) 写入缓存。
    state.categoryCache
      ..[FilterCategory.screenshots] = screenshots
      ..[FilterCategory.selfies] = selfies
      ..[FilterCategory.documents] = documents
      ..[FilterCategory.videos] = videos
      ..[FilterCategory.bursts] = bursts
      ..[FilterCategory.blurry] = blurry
      ..[FilterCategory.duplicates] = duplicates
      ..[FilterCategory.largeFiles] = large
      ..[FilterCategory.oldPhotos] = old;
  }

  /// 时间 + 大小筛选。
  static List<PhotoItem> applyTimeSizeFilter(
    List<PhotoItem> items,
    TimeSizeFilter filter,
  ) {
    return items.where((p) {
      if (filter.fromDate != null &&
          (p.created == null || p.created!.isBefore(filter.fromDate!))) {
        return false;
      }
      if (filter.toDate != null &&
          (p.created == null || p.created!.isAfter(filter.toDate!))) {
        return false;
      }
      if (filter.minBytes != null && (p.sizeBytes ?? 0) < filter.minBytes!) {
        return false;
      }
      if (filter.maxBytes != null && (p.sizeBytes ?? 0) > filter.maxBytes!) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 连拍检测：同一时间段内相邻拍摄间隔 <= gap 且数量 >= minCount。
  static List<PhotoItem> detectBursts(
    List<PhotoItem> photos, {
    Duration gap = const Duration(seconds: 2),
    int minCount = 3,
  }) {
    final sorted = photos.where((e) => e.created != null).toList()
      ..sort((a, b) => a.created!.compareTo(b.created!));
    final result = <PhotoItem>[];
    var run = <PhotoItem>[];
    for (final p in sorted) {
      if (run.isEmpty || p.created!.difference(run.last.created!) <= gap) {
        run.add(p);
      } else {
        if (run.length >= minCount) result.addAll(run);
        run = [p];
      }
    }
    if (run.length >= minCount) result.addAll(run);
    return result;
  }

  static int byCreatedAsc(PhotoItem a, PhotoItem b) =>
      (a.created ?? DateTime(0)).compareTo(b.created ?? DateTime(0));
}
