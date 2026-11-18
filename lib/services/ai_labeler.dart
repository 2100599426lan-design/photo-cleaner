import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../models/filter_category.dart';
import '../models/photo_item.dart';

/// 本地 AI 图像标签：人物 / 风景 / 食物 / 文档。
class AiLabeler {
  AiLabeler._();

  static ImageLabeler? _labeler;

  static ImageLabeler get labeler {
    _labeler ??= ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.55),
    );
    return _labeler!;
  }

  /// 识别单张照片，返回命中的分类集合；失败返回空集合。
  static Future<Set<FilterCategory>> label(PhotoItem p) async {
    try {
      final file = await p.asset.file;
      if (file == null) return <FilterCategory>{};
      final input = InputImage.fromFilePath(file.path);
      final labels = await labeler.processImage(input);
      final result = <FilterCategory>{};
      for (final l in labels) {
        final name = l.label.toLowerCase();
        p.labels.add(l.label);
        if (_isPeople(name)) result.add(FilterCategory.people);
        if (_isLandscape(name)) result.add(FilterCategory.landscape);
        if (_isFood(name)) result.add(FilterCategory.food);
        if (_isDocument(name)) result.add(FilterCategory.documents);
      }
      return result;
    } catch (_) {
      return <FilterCategory>{};
    }
  }

  static bool _isPeople(String n) =>
      n.contains('person') ||
      n.contains('people') ||
      n.contains('face') ||
      n.contains('selfie') ||
      n.contains('portrait') ||
      n.contains('child');

  static bool _isLandscape(String n) =>
      n.contains('sky') ||
      n.contains('landscape') ||
      n.contains('nature') ||
      n.contains('mountain') ||
      n.contains('sea') ||
      n.contains('beach') ||
      n.contains('tree') ||
      n.contains('plant') ||
      n.contains('flower') ||
      n.contains('water') ||
      n.contains('sunset') ||
      n.contains('cloud') ||
      n.contains('forest');

  static bool _isFood(String n) =>
      n.contains('food') ||
      n.contains('fruit') ||
      n.contains('vegetable') ||
      n.contains('meal') ||
      n.contains('dish') ||
      n.contains('dessert') ||
      n.contains('cake') ||
      n.contains('bread') ||
      n.contains('coffee') ||
      n.contains('drink');

  static bool _isDocument(String n) =>
      n.contains('text') ||
      n.contains('document') ||
      n.contains('paper') ||
      n.contains('book') ||
      n.contains('receipt') ||
      n.contains('screen') ||
      n.contains('keyboard');
}
