import 'package:flutter/material.dart';
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
