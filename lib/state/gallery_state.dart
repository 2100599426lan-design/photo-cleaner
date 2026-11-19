import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/filter_category.dart';
import '../models/photo_item.dart';
import '../services/ai_labeler.dart';
import '../services/cache_service.dart';
import '../services/analysis_service.dart';
import '../services/delete_service.dart';
import '../services/gallery_service.dart';

/// 全局照片状态：加载、选择、分析、分类缓存、删除。
class GalleryState extends ChangeNotifier {
  final List<PhotoItem> photos = [];
  final Set<String> selectedIds = {};

  PermissionState permission = PermissionState.notDetermined;
  bool loading = false;
  bool loaded = false;
  bool errorVisible = false;
  double progress = 0.0;
  String loadingMessage = '正在读取相册';
  String? error;

  /// 分析（重复/模糊/类型）状态。
  bool analyzing = false;
  double analysisProgress = 0.0;
  String analysisMessage = '';

  /// AI 识别状态。
  bool aiRunning = false;

  /// 是否已完成常规分析 / AI 分析。
  bool analyzed = false;
  bool aiAnalyzed = false;

  /// 时间 + 大小筛选条件。
  TimeSizeFilter timeSizeFilter = const TimeSizeFilter();

  /// 分类结果缓存：进入某分类时才计算并缓存。
  final Map<FilterCategory, List<PhotoItem>> categoryCache = {};

  int get totalCount => photos.length;
  int get selectedCount => selectedIds.length;
  bool get isSelectionMode => selectedIds.isNotEmpty;

  bool isSelected(String id) => selectedIds.contains(id);

  void toggleSelect(String id) {
    if (!selectedIds.add(id)) selectedIds.remove(id);
    notifyListeners();
  }

  void selectAll(Iterable<PhotoItem> items) {
    selectedIds.addAll(items.map((e) => e.id));
    notifyListeners();
  }

  void clearSelection() {
    selectedIds.clear();
    notifyListeners();
  }

  /// 初始化：请求权限并加载。
  Future<void> init() async {
    permission = await GalleryService.requestPermission();
    if (permission.isAuth) {
      await loadAll();
    } else {
      error = '未获得相册访问权限，请在系统设置中开启。';
      errorVisible = true;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    loading = true;
    loaded = false;
    progress = 0;
    error = null;
    errorVisible = false;
    loadingMessage = '正在读取相册';
    notifyListeners();

    List<AssetEntity> assets;
    try {
      assets = await GalleryService.loadAllAssets(
        onProgress: (done, total) {
          progress = total == 0 ? 1.0 : done / total;
          notifyListeners();
        },
      );
    } catch (e) {
      loading = false;
      error = '读取相册失败：$e';
      errorVisible = true;
      notifyListeners();
      return;
    }

    photos
      ..clear()
      ..addAll(assets.map(PhotoItem.fromAsset));

    // 加载分析缓存，避免重复分析。
    await _loadCache();

    loaded = true;
    loading = false;
    notifyListeners();

    // 后台读取文件大小，不阻塞首屏显示。
    unawaited(_fillFileSizes());
  }

  Future<void> _fillFileSizes() async {
    final list = photos;
    var idx = 0;
    Future<void> worker() async {
      while (true) {
        final i = idx;
        if (i >= list.length) break;
        idx = i + 1;
        try {
          list[i].sizeBytes = await list[i].asset.fileSize;
        } catch (_) {
          list[i].sizeBytes = 0;
        }
      }
    }

    await Future.wait(List.generate(10, (_) => worker()));
    notifyListeners();
  }

  /// 从磁盘加载分析缓存，填充 dHash / 清晰度 / AI 标签。
  Future<void> _loadCache() async {
    final cache = await CacheService.load();
    for (final p in photos) {
      final entry = cache[p.id];
      if (entry is Map) {
        p.dHash = entry['dHash'] as String?;
        p.blurScore = (entry['blur'] as num?)?.toDouble();
        final labels = entry['labels'];
        if (labels is List) {
          p.labels = labels.whereType<String>().toSet();
        }
      }
    }
  }

  /// 构建待持久化的缓存数据。
  Map<String, dynamic> _buildCache() {
    final map = <String, dynamic>{};
    for (final p in photos) {
      map[p.id] = {
        'dHash': p.dHash,
        'blur': p.blurScore,
        'labels': p.labels.toList(),
      };
    }
    return map;
  }

  /// 运行重复/模糊/类型分析。
  Future<void> analyze() async {
    if (analyzing) return;
    analyzing = true;
    analysisProgress = 0;
    analysisMessage = '';
    notifyListeners();

    await AnalysisService.analyzeAll(
      this,
      onProgress: (p, m) {
        analysisProgress = p;
        analysisMessage = m;
        notifyListeners();
      },
    );

    analyzing = false;
    analyzed = true;
    notifyListeners();
    await CacheService.save(_buildCache());
  }

  /// 运行 AI 内容识别（人物/风景/食物/文档）。
  Future<void> analyzeAi() async {
    if (aiRunning) return;
    aiRunning = true;
    notifyListeners();

    final people = <PhotoItem>[];
    final landscape = <PhotoItem>[];
    final food = <PhotoItem>[];
    final docs = <PhotoItem>[];
    var done = 0;

    for (final p in photos) {
      final cats = await AiLabeler.label(p);
      if (cats.contains(FilterCategory.people)) people.add(p);
      if (cats.contains(FilterCategory.landscape)) landscape.add(p);
      if (cats.contains(FilterCategory.food)) food.add(p);
      if (cats.contains(FilterCategory.documents)) docs.add(p);
      done++;
      if (done % 5 == 0) notifyListeners();
    }

    categoryCache
      ..[FilterCategory.people] = people
      ..[FilterCategory.landscape] = landscape
      ..[FilterCategory.food] = food
      ..[FilterCategory.documents] = docs;

    aiRunning = false;
    aiAnalyzed = true;
    notifyListeners();
    await CacheService.save(_buildCache());
  }

  /// 从本地列表移除指定 id 的照片（不删除文件，用于滑动删除后的同步）。
  void removeItems(Iterable<String> ids) {
    final s = ids.toSet();
    photos.removeWhere((p) => s.contains(p.id));
    categoryCache.clear();
    selectedIds.removeAll(s);
    notifyListeners();
  }

  /// 删除选中的照片/视频，并同步本地列表与缓存。
  Future<DeleteResult> deleteSelected() async {
    final items = photos.where((p) => selectedIds.contains(p.id)).toList();
    final result = await DeleteService.deleteItems(items);
    if (result.success > 0) {
      final ok = result.successIds.toSet();
      photos.removeWhere((p) => ok.contains(p.id));
      // 清空缓存，避免残留已删除项的引用。
      categoryCache.clear();
      selectedIds.clear();
      notifyListeners();
    }
    return result;
  }
}
