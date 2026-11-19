import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../models/photo_item.dart';
import '../services/delete_service.dart';
import '../state/gallery_state.dart';
import 'home_page.dart';

/// 抖音式全屏浏览：下滑上一张，上滑删除当前照片。
class SwipePage extends StatefulWidget {
  const SwipePage({super.key, required this.items, this.initialIndex = 0});

  final List<PhotoItem> items;
  final int initialIndex;

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> {
  late final List<PhotoItem> _items;
  late int _index;
  int _deleted = 0;
  bool _showHint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
    _index = widget.items.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _items.length - 1);
    // 底部手势提示 3 秒后自动淡出，不挡图片。
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  /// 上滑 -> 删除；下滑 -> 上一张。
  void _onVerticalDragEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v <= -250) {
      _deleteCurrent();
    } else if (v >= 250) {
      _prev();
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
    }
  }

  Future<void> _deleteCurrent() async {
    if (_items.isEmpty) return;
    final current = _items[_index];

    // 乐观更新：立即从界面移除并显示下一张，删除在后台执行。
    setState(() {
      _items.removeAt(_index);
      _deleted++;
      if (_items.isEmpty) {
        _index = -1;
      } else if (_index >= _items.length) {
        _index = _items.length - 1;
      }
    });

    final result = await DeleteService.deleteItems([current]);
    if (result.success > 0) {
      if (mounted) {
        context.read<GalleryState>().removeItems([current.id]);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这张删除失败，可稍后重试')),
      );
    }

    if (_items.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已全部处理完，共删除 $_deleted 张')),
      );
    }
  }

  void _openGrid() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                '已全部处理完，共删除 $_deleted 张',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<GalleryState>().init(),
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _FullImage(key: ValueKey(item.id), item: item),
            ),
            // 顶部半透明渐变栏，不遮挡主体画面。
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.grid_view, color: Colors.white),
                          tooltip: '网格分类',
                          onPressed: _openGrid,
                        ),
                        Expanded(
                          child: Text(
                            '${_index + 1} / ${_items.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                        Text(
                          '已删 $_deleted',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 底部手势提示：短暂显示后淡出。
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: const [
                      Text(
                        '上滑 删除',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 24),
                      Text(
                        '下滑 上一张',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  const _FullImage({super.key, required this.item});

  final PhotoItem item;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: item.asset.thumbnailDataWithSize(
        const ThumbnailSize.square(1080),
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return Image.memory(data, fit: BoxFit.contain);
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        );
      },
    );
  }
}
