import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/repositories/academy_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/services/auth_service.dart';
import 'firebase_options.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';
import 'ui/features/demo/demo_store.dart';
import 'ui/features/home/view_models/academy_search_view_model.dart';
import 'ui/features/session/session_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;
  final auth = AuthService(FirebaseAuth.instance);
  final users = UserRepository(db);
  final academies = AcademyRepository(db);
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: auth),
        Provider.value(value: users),
        Provider.value(value: academies),
        ChangeNotifierProvider(
          create: (_) => SessionViewModel(auth: auth, users: users),
        ),
        ChangeNotifierProvider(create: (_) => AcademySearchViewModel(academies)),
        ChangeNotifierProvider(create: (_) => DemoStore()),
      ],
      child: const AlumalumApp(),
    ),
  );
}

class AlumalumApp extends StatefulWidget {
  const AlumalumApp({super.key});

  @override
  State<AlumalumApp> createState() => _AlumalumAppState();
}

class _AlumalumAppState extends State<AlumalumApp> {
  late final _router = buildRouter(context.read<SessionViewModel>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '알음알음',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
