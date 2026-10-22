import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'dart:async';
import 'dart:io';

// Provider for connectivity state
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier();
    });

class ConnectivityState {
  final bool isConnected;

  const ConnectivityState({this.isConnected = true});

  ConnectivityState copyWith({bool? isConnected}) {
    return ConnectivityState(isConnected: isConnected ?? this.isConnected);
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _recheckTimer;
  bool _isInitialized = false;

  ConnectivityNotifier({bool autoStart = true})
    : super(const ConnectivityState()) {
    if (autoStart) _initConnectivity();
  }

  void _initConnectivity() {
    if (_isInitialized) return;
    _isInitialized = true;

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        _setConnected(false);
      } else {
        unawaited(_checkConnectivity());
      }
    });

    unawaited(_checkConnectivity());
    _recheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_checkConnectivity()),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      // Simple connectivity check - try to reach a reliable host
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));

      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      _setConnected(isConnected);
    } catch (_) {
      _setConnected(false);
    }
  }

  void _setConnected(bool isConnected) {
    if (state.isConnected != isConnected) {
      state = state.copyWith(isConnected: isConnected);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _recheckTimer?.cancel();
    super.dispose();
  }
}
