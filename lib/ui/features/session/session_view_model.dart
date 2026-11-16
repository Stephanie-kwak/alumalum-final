import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/models/user_profile.dart';

enum SessionStatus { loading, signedOut, signedIn }

/// 로그인 상태와 내 프로필. 라우터가 이 값을 보고 첫 화면을 정한다.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel({required this._auth, required this._users}) {
    _authSub = _auth.uidChanges.listen(_onUid);
  }

  final AuthService _auth;
  final UserRepository _users;
  StreamSubscription<String?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  String? _uid;
  bool _profileLoaded = false;
  SessionStatus _status = SessionStatus.loading;
  SessionStatus get status => _status;
  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _signingUp = false;

  /// 가입 화면이 계정을 만들고 프로필을 쓰는 동안 true. 라우터는 이 동안 화면을 옮기지 않는다
  /// (중간 상태로 가입 화면이 사라지면 실패 문구와 입력값을 잃는다).
  bool get signingUp => _signingUp;
  set signingUp(bool v) {
    _signingUp = v;
    _recompute();
  }

  void _onUid(String? uid) {
    _profileSub?.cancel();
    _uid = uid;
    _profile = null;
    _profileLoaded = uid == null;
    _recompute();
    if (uid == null) return;
    _profileSub = _users
        .watch(uid)
        .listen(
          (p) {
            _profile = p;
            _profileLoaded = true;
            _recompute();
          },
          onError: (_) {
            _profile = null;
            _profileLoaded = true;
            _recompute();
          },
        );
  }

  /// 계정은 있는데 프로필이 없으면(임시 계정, 가입 도중 실패) 로그인 전으로 본다.
  void _recompute() {
    _status = _uid == null || (_profileLoaded && _profile == null)
        ? SessionStatus.signedOut
        : _profile != null
        ? SessionStatus.signedIn
        : SessionStatus.loading;
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
