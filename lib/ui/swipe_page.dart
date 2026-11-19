import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../models/photo_item.dart';
import '../services/delete_service.dart';
import '../state/gallery_state.dart';

/// 抖音式滑动浏览：上滑删除当前照片，下滑返回上一张。
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

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
    _index = widget.items.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _items.length - 1);
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
      // 同步移除全局列表，返回首页后不再出现。
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
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
    }
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
              const Text('已全部处理完', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回'),
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
            _FullImage(item: item),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        '${_index + 1} / ${_items.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    Text(
                      '已删 $_deleted',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: Column(
                children: [
                  Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 32),
                  Text('上滑删除', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 6),
                  Text(
                    '下滑返回上一张',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  const _FullImage({required this.item});

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
