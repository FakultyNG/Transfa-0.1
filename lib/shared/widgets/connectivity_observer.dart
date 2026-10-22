// lib/shared/widgets/connectivity_observer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pop-ups/no_internet_popup.dart';
import '../../providers/connectivity_provider.dart';

/// Widget that monitors connectivity and shows the no internet popup when needed
class ConnectivityObserver extends ConsumerWidget {
  final Widget child;

  const ConnectivityObserver({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: connectivityState.isConnected
                ? const SizedBox.shrink(key: ValueKey('online'))
                : ColoredBox(
                    key: const ValueKey('offline'),
                    color: Colors.black.withValues(alpha: 0.7),
                    child: const Center(
                      child: NoInternetPopup(dismissible: false),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
