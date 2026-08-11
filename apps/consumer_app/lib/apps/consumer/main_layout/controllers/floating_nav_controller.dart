import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/legacy.dart';

class FloatingNavState {
  final bool isBottomBarVisible;
  final bool isTopHeaderCollapsed;
  final double lastOffset;

  const FloatingNavState({
    this.isBottomBarVisible = true,
    this.isTopHeaderCollapsed = false,
    this.lastOffset = 0.0,
  });

  FloatingNavState copyWith({
    bool? isBottomBarVisible,
    bool? isTopHeaderCollapsed,
    double? lastOffset,
  }) {
    return FloatingNavState(
      isBottomBarVisible: isBottomBarVisible ?? this.isBottomBarVisible,
      isTopHeaderCollapsed: isTopHeaderCollapsed ?? this.isTopHeaderCollapsed,
      lastOffset: lastOffset ?? this.lastOffset,
    );
  }
}

class FloatingNavController extends StateNotifier<FloatingNavState> {
  FloatingNavController() : super(const FloatingNavState());

  void handleUserScroll(UserScrollNotification notification) {
    if (notification.depth != 0) return; // Ignore nested scrollables
    if (notification.metrics.axis != Axis.vertical) return; // Only react to vertical scrolling

    if (notification.direction == ScrollDirection.reverse) {
      // User is scrolling DOWN -> Hide bottom bar, collapse top bar
      if (state.isBottomBarVisible || !state.isTopHeaderCollapsed) {
        state = state.copyWith(
          isBottomBarVisible: false,
          isTopHeaderCollapsed: true,
        );
      }
    } else if (notification.direction == ScrollDirection.forward) {
      // User is scrolling UP -> Show bottom bar, expand top bar
      if (!state.isBottomBarVisible || state.isTopHeaderCollapsed) {
        state = state.copyWith(
          isBottomBarVisible: true,
          isTopHeaderCollapsed: false,
        );
      }
    }
  }

  void handleScrollUpdate(ScrollUpdateNotification notification) {
    if (notification.depth != 0) return;

    final metrics = notification.metrics;
    if (metrics.pixels <= 10) {
      // At the top of page -> Always show bars
      if (!state.isBottomBarVisible || state.isTopHeaderCollapsed) {
        state = state.copyWith(
          isBottomBarVisible: true,
          isTopHeaderCollapsed: false,
        );
      }
    }
  }

  void showBars() {
    state = state.copyWith(
      isBottomBarVisible: true,
      isTopHeaderCollapsed: false,
    );
  }
}

final floatingNavControllerProvider =
    StateNotifierProvider<FloatingNavController, FloatingNavState>((ref) {
  return FloatingNavController();
});
