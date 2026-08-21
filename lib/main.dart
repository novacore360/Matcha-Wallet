import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env is a local-dev convenience only. CI builds (Codemagic) inject
  // config via --dart-define instead and won't ship a .env file at all —
  // AppConfig falls back gracefully either way.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env present (e.g. CI build) — AppConfig will use dart-define
    // values or hardcoded fallbacks instead.
  }

  // Lock orientation and use a clean status bar to match the minimalist UI.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const MatchaWalletApp());
}

class MatchaWalletApp extends StatelessWidget {
  const MatchaWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        title: 'Matcha Wallet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
