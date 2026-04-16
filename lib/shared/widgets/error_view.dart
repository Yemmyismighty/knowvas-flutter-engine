import 'package:flutter/material.dart';

/// Reusable error view widget with retry functionality
/// Provides consistent error UI across the app
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.title = 'Something went wrong',
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticLabel = '$title. $message.${onRetry != null ? ' Double tap retry button to try again.' : ''}';

    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: theme.colorScheme.error.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Retry',
                    button: true,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact error view for inline display
class InlineErrorView extends StatelessWidget {
  const InlineErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticLabel = 'Error: $message.${onRetry != null ? ' Double tap retry button to try again.' : ''}';

    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: 'Retry',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRetry,
                    color: theme.colorScheme.error,
                    tooltip: 'Retry',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Network error view with specific messaging
class NetworkErrorView extends StatelessWidget {
  const NetworkErrorView({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      icon: Icons.wifi_off,
      title: 'Connection Error',
      message: 'Unable to connect. Please check your internet connection.',
      onRetry: onRetry,
    );
  }
}

/// Server error view
class ServerErrorView extends StatelessWidget {
  const ServerErrorView({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      icon: Icons.cloud_off,
      title: 'Server Error',
      message: 'Something went wrong on our end. Please try again later.',
      onRetry: onRetry,
    );
  }
}
