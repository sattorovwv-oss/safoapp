import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/auth.dart';
import 'core/offline_queue.dart';
import 'core/settings.dart';
import 'core/store.dart';
import 'core/theme.dart';
import 'screens/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final settings = await AppSettings.load();
  runApp(SafoApp(settings: settings));
}

class SafoApp extends StatefulWidget {
  const SafoApp({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<SafoApp> createState() => _SafoAppState();
}

class _SafoAppState extends State<SafoApp> {
  late final PlacesStore _store = PlacesStore(widget.settings);
  late final AuthStore _auth = AuthStore(widget.settings);
  late final OfflineQueue _queue = OfflineQueue(_auth);

  @override
  void initState() {
    super.initState();
    _auth.restore().then((_) => _queue.load());
  }

  @override
  void dispose() {
    _store.dispose();
    _queue.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: widget.settings,
      child: AuthScope(
        auth: _auth,
        child: QueueScope(
          queue: _queue,
          child: StoreScope(
            store: _store,
            child: Builder(
              builder: (context) {
                final s = context.app;
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: s.t('app'),
                  themeMode: s.themeMode,
                  theme: buildTheme(Brightness.light),
                  darkTheme: buildTheme(Brightness.dark),
                  themeAnimationDuration: const Duration(milliseconds: 420),
                  themeAnimationCurve: Curves.easeOut,
                  home: const SplashScreen(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
