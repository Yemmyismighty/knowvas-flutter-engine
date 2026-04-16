import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'empty_state.dart';
import 'error_view.dart';
import 'loading_indicator.dart';

/// Widget that handles AsyncValue states automatically
/// Simplifies rendering of loading, error, and data states
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.skipLoadingOnRefresh = true,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final bool skipLoadingOnRefresh;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () {
        if (skipLoadingOnRefresh && value.hasValue) {
          return data(value.requireValue);
        }
        return loading?.call() ?? const LoadingIndicator();
      },
      error: (err, stack) {
        if (error != null) {
          return error!(err, stack);
        }
        return ErrorView(
          message: err.toString(),
          onRetry: null,
        );
      },
    );
  }
}

/// Widget for handling list data with loading, error, and empty states
class AsyncListWidget<T> extends StatelessWidget {
  const AsyncListWidget({
    super.key,
    required this.value,
    required this.data,
    required this.emptyState,
    this.loading,
    this.error,
    this.skipLoadingOnRefresh = true,
  });

  final AsyncValue<List<T>> value;
  final Widget Function(List<T> data) data;
  final Widget emptyState;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final bool skipLoadingOnRefresh;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (items) {
        if (items.isEmpty) {
          return emptyState;
        }
        return data(items);
      },
      loading: () {
        if (skipLoadingOnRefresh && value.hasValue) {
          final items = value.requireValue;
          if (items.isEmpty) {
            return emptyState;
          }
          return data(items);
        }
        return loading?.call() ?? const LoadingIndicator();
      },
      error: (err, stack) {
        if (error != null) {
          return error!(err, stack);
        }
        return ErrorView(
          message: err.toString(),
          onRetry: null,
        );
      },
    );
  }
}

/// Widget for handling nullable data with loading, error, and empty states
class AsyncNullableWidget<T> extends StatelessWidget {
  const AsyncNullableWidget({
    super.key,
    required this.value,
    required this.data,
    required this.emptyState,
    this.loading,
    this.error,
    this.skipLoadingOnRefresh = true,
  });

  final AsyncValue<T?> value;
  final Widget Function(T data) data;
  final Widget emptyState;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final bool skipLoadingOnRefresh;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (item) {
        if (item == null) {
          return emptyState;
        }
        return data(item);
      },
      loading: () {
        if (skipLoadingOnRefresh && value.hasValue) {
          final item = value.requireValue;
          if (item == null) {
            return emptyState;
          }
          return data(item);
        }
        return loading?.call() ?? const LoadingIndicator();
      },
      error: (err, stack) {
        if (error != null) {
          return error!(err, stack);
        }
        return ErrorView(
          message: err.toString(),
          onRetry: null,
        );
      },
    );
  }
}
