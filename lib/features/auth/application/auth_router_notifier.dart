import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  final notifier = AuthRouterNotifier(ref.watch(authRepositoryProvider));
  ref.onDispose(notifier.dispose);
  return notifier;
});

class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(this._repository) {
    _signedIn = _repository.currentSession != null;
    if (_repository.isConfigured) {
      _subscription = _repository.authStateChanges.listen((state) {
        final nextSignedIn = state.session != null;
        if (_signedIn != nextSignedIn) {
          _signedIn = nextSignedIn;
          notifyListeners();
        }
      });
    }
  }

  final AuthRepository _repository;
  StreamSubscription<AuthState>? _subscription;
  late bool _signedIn;

  bool get isConfigured => _repository.isConfigured;
  bool get isSignedIn => _signedIn;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
