import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// A loading overlay widget that blocks interaction and shows a progress indicator.
///
/// Features:
/// - Semi-transparent background
/// - Centered circular progress indicator
/// - Blocks all touch events
/// - Optional message text
class LoadingOverlay extends StatelessWidget {
  /// Creates a loading overlay.
  const LoadingOverlay({
    super.key,
    this.isLoading = true,
    this.child,
    this.message,
    this.backgroundColor,
  });

  /// Whether the overlay is visible.
  final bool isLoading;

  /// The child widget to display behind the overlay.
  final Widget? child;

  /// Optional message to display below the progress indicator.
  final String? message;

  /// Custom background color (defaults to semi-transparent surface).
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        if (child != null) child!,
        if (isLoading)
          Material(
            color: backgroundColor ?? colorScheme.surface.withValues(alpha: 0.8),
            child: InkWell(
              // Block all touch events
              onTap: () {},
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TDLoading(
                      size: TDLoadingSize.large,
                      icon: TDLoadingIcon.circle,
                      iconColor: colorScheme.primary,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A loading indicator widget for inline use.
class LoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  const LoadingIndicator({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.0,
    this.color,
  });

  /// The size of the indicator.
  final double size;

  /// The stroke width of the indicator.
  final double strokeWidth;

  /// Optional custom color (defaults to primary color).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: TDLoading(
        size: TDLoadingSize.small,
        icon: TDLoadingIcon.circle,
        iconColor: color ?? colorScheme.primary,
      ),
    );
  }
}

/// A loading shimmer effect for placeholder content.
class LoadingShimmer extends StatelessWidget {
  /// Creates a loading shimmer.
  const LoadingShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  /// The child widget to apply shimmer on.
  final Widget child;

  /// Base color of the shimmer.
  final Color? baseColor;

  /// Highlight color of the shimmer.
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final base = baseColor ?? colorScheme.surfaceContainerHighest;
    final highlight = highlightColor ?? colorScheme.surface;

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            highlight,
            base,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

/// A placeholder tile that shows a shimmer loading effect.
class LoadingPlaceholderTile extends StatelessWidget {
  /// Creates a loading placeholder tile.
  const LoadingPlaceholderTile({
    super.key,
    this.height = 72.0,
  });

  /// The height of the tile.
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const LoadingShimmer(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
          ),
          title: Text('Loading...'),
          subtitle: Text('Please wait'),
        ),
      ),
    );
  }
}

/// Loading state enum for widgets.
enum LoadingState {
  /// Initial state, not loading.
  initial,

  /// Currently loading.
  loading,

  /// Loading completed successfully.
  success,

  /// Loading failed with error.
  error,
}

/// A widget that shows different content based on loading state.
class LoadingStateBuilder<T> extends StatelessWidget {
  /// Creates a loading state builder.
  const LoadingStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.data,
    this.error,
    this.onRetry,
  });

  /// Current loading state.
  final LoadingState state;

  /// Builder for success state with data.
  final Widget Function(T? data) builder;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Custom error widget.
  final Widget? errorWidget;

  /// Custom empty widget.
  final Widget? emptyWidget;

  /// The data to pass to builder.
  final T? data;

  /// Error message if any.
  final String? error;

  /// Retry callback for error state.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case LoadingState.initial:
      case LoadingState.loading:
        return loadingWidget ?? const LoadingIndicator();
      case LoadingState.success:
        if (data == null && emptyWidget != null) {
          return emptyWidget!;
        }
        return builder(data);
      case LoadingState.error:
        return errorWidget ??
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TDIcons.close_circle,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(error ?? 'An error occurred'),
                  if (onRetry != null) ...[
                    const SizedBox(height: 16),
                    TDButton(
                      theme: TDButtonTheme.primary,
                      type: TDButtonType.fill,
                      onTap: onRetry,
                      icon: TDIcons.refresh,
                      text: 'Retry',
                    ),
                  ],
                ],
              ),
            );
    }
  }
}