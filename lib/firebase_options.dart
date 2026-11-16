// Firebase 연결 정보. android 는 google-services.json, web 은 Firebase 콘솔의 웹 앱(Default Web App) 설정에서 만들었다.
// 다른 Firebase 프로젝트로 옮길 때는 수정 가이드의 'Firebase 바꾸기'를 따른다.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract final class DefaultFirebaseOptions {
  /// 웹 빌드(flutter build web)는 web, 그 밖에는 android 설정을 쓴다.
  static FirebaseOptions get currentPlatform => kIsWeb ? web : android;

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCUZxbsR5V4LAWlYzbUzRpxAChKKi_E3r0',
    appId: '1:30827668589:android:e8d99d42a0867061928b64',
    messagingSenderId: '30827668589',
    projectId: 'alumalum-demo',
    storageBucket: 'alumalum-demo.firebasestorage.app',
  );

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyDvtESmrIp_4AMM-O2_Mgxt-d5EW0SQ1FY',
    appId: '1:30827668589:web:c8a68e32e7d28b30928b64',
    messagingSenderId: '30827668589',
    projectId: 'alumalum-demo',
    authDomain: 'alumalum-demo.firebaseapp.com',
    storageBucket: 'alumalum-demo.firebasestorage.app',
  );
}
