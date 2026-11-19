import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../state/gallery_state.dart';
import 'swipe_page.dart';

/// 根页面：加载照片后直接进入全屏滑动模式（抖音式）。
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<GalleryState>();
    state.addListener(_sync);
    _sync();
    if (!state.loaded && !state.loading) {
      state.init();
    }
  }

  @override
  void dispose() {
    context.read<GalleryState>().removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final ready = context.read<GalleryState>().loaded;
    if (ready != _ready && mounted) {
      setState(() => _ready = ready);
      if (ready) {
        // 进入滑动模式后，检测「媒体管理」权限，避免删除弹确认框。
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkManageMedia());
      }
    }
  }

  /// Android 12+：未开启「媒体管理」时引导开启，上滑删除即可不再弹确认框。
  Future<void> _checkManageMedia() async {
    try {
      final can = await PhotoManager.canManageMedia();
      if (can || !mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('开启「媒体管理」权限'),
          content: const Text('开启后，上滑删除照片将不再弹出确认框，刷起来更流畅。是否现在去开启？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('暂不'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('去开启'),
            ),
          ],
        ),
      );
      if (go == true) {
        await PhotoManager.requestManageMedia();
      }
    } catch (_) {
      // 不支持该能力的设备上静默忽略。
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<GalleryState>();
    if (!_ready) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!state.errorVisible) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '${state.loadingMessage} ${(state.progress * 100).toStringAsFixed(0)}%',
                ),
              ] else ...[
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
            ],
          ),
        ),
      );
    }
    return SwipePage(items: state.photos);
  }
}
