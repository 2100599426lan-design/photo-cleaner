import 'package:flutter/material.dart';

/// 分类维度（可在 UI 中切换的“桶”）。
enum FilterCategory {
  all('全部', Icons.photo_library_outlined),
  screenshots('截图', Icons.screenshot_outlined),
  selfies('自拍', Icons.face_outlined),
  documents('文档', Icons.description_outlined),
  videos('视频', Icons.videocam_outlined),
  bursts('连拍', Icons.burst_mode_outlined),
  duplicates('重复/相似', Icons.copy_outlined),
  blurry('模糊', Icons.blur_on_outlined),
  people('人物', Icons.person_outline),
  landscape('风景', Icons.landscape_outlined),
  food('食物', Icons.restaurant_outlined),
  largeFiles('大文件', Icons.sd_storage_outlined),
  oldPhotos('早期照片', Icons.history_outlined);

  const FilterCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// 时间 + 大小筛选条件。
class TimeSizeFilter {
  const TimeSizeFilter({
    this.fromDate,
    this.toDate,
    this.minBytes,
    this.maxBytes,
    this.minDurationMs,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final int? minBytes;
  final int? maxBytes;
  final int? minDurationMs;

  bool get isActive =>
      fromDate != null ||
      toDate != null ||
      minBytes != null ||
      maxBytes != null ||
      minDurationMs != null;
}
