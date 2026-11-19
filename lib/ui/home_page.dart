import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../models/filter_category.dart';
import '../models/photo_item.dart';
import '../services/analysis_service.dart';
import '../state/gallery_state.dart';

/// 首页：照片网格 + 多选删除 + 分类 + 筛选。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FilterCategory _current = FilterCategory.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<GalleryState>();
      if (!state.loaded && !state.loading) state.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    final items = _currentItems(state);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.isSelectionMode ? '已选 ${state.selectedCount} 项' : _current.label,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swipe),
            tooltip: '返回滑动模式',
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '时间 + 大小筛选',
            onPressed: () => _openFilter(state),
          ),
          if (state.isSelectionMode)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: '全选',
              onPressed: () => state.selectAll(items),
            ),
          if (state.isSelectionMode)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: '清空选择',
              onPressed: () => state.clearSelection(),
            ),
        ],
      ),
      body: Column(
        children: [
          _CategoryBar(
            current: _current,
            onTap: (c) {
              setState(() => _current = c);
              state.clearSelection();
              _ensureCategoryReady(c);
            },
          ),
          if (state.analyzing || state.aiRunning)
            _ProgressBanner(
              message: state.analyzing
                  ? state.analysisMessage
                  : 'AI 识别中…',
              progress: state.analyzing ? state.analysisProgress : null,
            ),
          Expanded(child: _buildBody(state, items)),
        ],
      ),
      bottomNavigationBar: state.isSelectionMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text('删除所选（${state.selectedCount}）'),
                  onPressed: () => _confirmDelete(state),
                ),
              ),
            )
          : null,
    );
  }

  /// 当前分类下的照片（再叠加时间/大小筛选）。
  List<PhotoItem> _currentItems(GalleryState state) {
    final base = _current == FilterCategory.all
        ? state.photos
        : (state.categoryCache[_current] ?? const <PhotoItem>[]);
    if (state.timeSizeFilter.isActive) {
      return AnalysisService.applyTimeSizeFilter(base, state.timeSizeFilter);
    }
    return base;
  }

  /// 进入分类时，按需触发常规分析或 AI 分析。
  void _ensureCategoryReady(FilterCategory c) {
    if (c == FilterCategory.all) return;
    final state = context.read<GalleryState>();
    final needsAi = c == FilterCategory.people ||
        c == FilterCategory.landscape ||
        c == FilterCategory.food;
    if (needsAi) {
      if (!state.aiAnalyzed && !state.aiRunning) state.analyzeAi();
    } else {
      if (!state.analyzed && !state.analyzing) state.analyze();
    }
  }

  Widget _buildBody(GalleryState state, List<PhotoItem> items) {
    if (!state.loaded && state.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${state.loadingMessage} ${(state.progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      );
    }
    if (state.errorVisible) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(state.error ?? '发生错误', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => state.init(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      final String hint;
      if (state.analyzing || state.aiRunning) {
        hint = '正在分析…';
      } else if (_current != FilterCategory.all &&
          (state.categoryCache[_current] == null)) {
        hint = '该分类尚未分析';
      } else {
        hint = '该分类下暂无照片';
      }
      return Center(child: Text(hint));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _PhotoTile(
        item: items[i],
        selected: state.isSelected(items[i].id),
        onTap: () => state.toggleSelect(items[i].id),
      ),
    );
  }

  Future<void> _confirmDelete(GalleryState state) async {
    final count = state.selectedCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('将删除 $count 项照片/视频（会先移入系统回收站，可恢复）。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final result = await state.deleteSelected();
    if (!mounted) return;
    final msg = result.failed > 0
        ? '已删除 ${result.success} 项，${result.failed} 项失败'
        : '已删除 ${result.success} 项';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openFilter(GalleryState state) async {
    final result = await showModalBottomSheet<TimeSizeFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: state.timeSizeFilter),
    );
    if (result != null) {
      state.timeSizeFilter = result;
      state.clearSelection();
      // 触发重建以应用筛选。
      setState(() {});
    }
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.message, this.progress});

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (progress != null) ...[
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(value: progress),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.current, required this.onTap});

  final FilterCategory current;
  final ValueChanged<FilterCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final cats = FilterCategory.values;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = cats[i];
          return ChoiceChip(
            label: Text(c.label),
            selected: c == current,
            onSelected: (_) => onTap(c),
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PhotoItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ThumbImage(item: item),
          if (item.isVideo)
            const Positioned(
              right: 4,
              bottom: 4,
              child: Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
            ),
          if (selected)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Icon(Icons.check_circle, color: Colors.white, size: 36),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbImage extends StatelessWidget {
  const _ThumbImage({required this.item});

  final PhotoItem item;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: item.asset.thumbnailDataWithSize(
        const ThumbnailSize.square(200),
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return Image.memory(
            data,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }
        return const ColoredBox(color: Colors.black12);
      },
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final TimeSizeFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTime? _from = widget.initial.fromDate;
  late DateTime? _to = widget.initial.toDate;
  late final TextEditingController _minCtrl = TextEditingController(
    text: widget.initial.minBytes == null
        ? ''
        : (widget.initial.minBytes! ~/ (1024 * 1024)).toString(),
  );
  late final TextEditingController _maxCtrl = TextEditingController(
    text: widget.initial.maxBytes == null
        ? ''
        : (widget.initial.maxBytes! ~/ (1024 * 1024)).toString(),
  );

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('时间 + 大小筛选', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('拍摄时间', style: Theme.of(context).textTheme.labelLarge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await _pickDate(initial: _from);
                      if (d != null) setState(() => _from = d);
                    },
                    child: Text(_from == null ? '开始日期' : _fmt(_from!)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—'),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await _pickDate(initial: _to);
                      if (d != null) setState(() => _to = d);
                    },
                    child: Text(_to == null ? '结束日期' : _fmt(_to!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('文件大小（MB）', style: Theme.of(context).textTheme.labelLarge),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '最小',
                      isDense: true,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '最大',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, const TimeSizeFilter()),
                  child: const Text('清除'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final minMB = int.tryParse(_minCtrl.text);
                    final maxMB = int.tryParse(_maxCtrl.text);
                    Navigator.pop(
                      context,
                      TimeSizeFilter(
                        fromDate: _from,
                        toDate: _to,
                        minBytes: minMB == null ? null : minMB * 1024 * 1024,
                        maxBytes: maxMB == null ? null : maxMB * 1024 * 1024,
                      ),
                    );
                  },
                  child: const Text('应用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate({DateTime? initial}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
