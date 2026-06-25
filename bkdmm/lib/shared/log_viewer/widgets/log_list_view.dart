/// 日志列表视图
///
/// 使用虚拟滚动显示大量日志
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../providers/log_viewer_provider.dart';
import 'log_entry_widget.dart';

/// 日志列表视图
class LogListView extends ConsumerStatefulWidget {
  const LogListView({super.key});

  @override
  ConsumerState<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends ConsumerState<LogListView> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 检测是否接近底部
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isNearBottom = maxScroll - currentScroll < 100;

    if (isNearBottom != !_showScrollToBottom) {
      setState(() {
        _showScrollToBottom = !isNearBottom;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logViewerProvider);
    final entries = state.entries;
    final tdTheme = TDTheme.of(context);

    // 自动滚动到底部
    ref.listen<LogViewerState>(logViewerProvider, (previous, next) {
      if (state.autoScroll &&
          next.entries.length > (previous?.entries.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    });

    if (entries.isEmpty) {
      return _buildEmptyState(tdTheme);
    }

    return Stack(
      children: [
        // 日志列表
        ListView.builder(
          controller: _scrollController,
          itemCount: entries.length,
          itemExtent: 28, // 固定行高，提高性能
          itemBuilder: (context, index) {
            final entry = entries[index];
            return LogEntryWidget(
              entry: entry,
              index: index,
              tdTheme: tdTheme,
            );
          },
        ),

        // 滚动到底部按钮
        if (_showScrollToBottom)
          Positioned(
            right: 16,
            bottom: 16,
            child: TDButton(
              icon: TDIcons.arrow_down,
              theme: TDButtonTheme.primary,
              type: TDButtonType.fill,
              size: TDButtonSize.small,
              shape: TDButtonShape.circle,
              onTap: _scrollToBottom,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(TDThemeData tdTheme) {
    final isPaused = ref.watch(logIsPausedProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPaused ? TDIcons.pause_circle : TDIcons.file,
            size: 48,
            color: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 16),
          TDText(
            isPaused ? '日志已暂停' : '暂无日志',
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorSecondary,
          ),
          if (isPaused) ...[
            const SizedBox(height: 8),
            TDText(
              '点击继续按钮恢复日志显示',
              font: tdTheme.fontBodySmall,
              textColor: tdTheme.textColorPlaceholder,
            ),
          ],
        ],
      ),
    );
  }
}
