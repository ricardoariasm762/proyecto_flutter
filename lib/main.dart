import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/theme_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'core/localization/language_controller.dart';
import 'core/controllers/home_controller.dart';
import 'services/location_service.dart';
import 'services/ride_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mowhkgekfndkbjddchiz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vd2hrZ2VrZm5ka2JqZGRjaGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NjQ3MjUsImV4cCI6MjA4OTQ0MDcyNX0.mBn0tIQocTy2pFgXrwgx2PBmctEOY8mLvWpxfQp_iNs',
  );

  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageController()),
        Provider<RideService>(create: (_) => RideService()),
        ChangeNotifierProvider(create: (context) => HomeController(LocationService(), context.read<RideService>())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final themeCtrl = ThemeController.instance;
        
        final String? fontFamily = GoogleFonts.notoSans().fontFamily;
        const TextTheme textTheme = TextTheme(
          displayMedium: TextStyle(fontSize: 41),
          displaySmall: TextStyle(fontSize: 36),
          labelSmall: TextStyle(fontSize: 11, letterSpacing: 0.5),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RideMatch Comunidad',
          themeMode: themeCtrl.themeMode,
          theme: FlexThemeData.light(
            scheme: themeCtrl.usedScheme,
            useMaterial3: themeCtrl.useMaterial3,
            surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
            blendLevel: 8,
            appBarStyle: FlexAppBarStyle.primary,
            appBarOpacity: 0.94,
            appBarElevation: 0.5,
            transparentStatusBar: true,
            tabBarStyle: FlexTabBarStyle.forAppBar,
            fontFamily: fontFamily,
            textTheme: textTheme,
            primaryTextTheme: textTheme,
            subThemesData: const FlexSubThemesData(
              interactionEffects: true,
              defaultRadius: null,
              bottomSheetRadius: 24,
              useMaterial3Typography: true,
              inputDecoratorBorderType: FlexInputBorderType.outline,
              inputDecoratorIsFilled: true,
              inputDecoratorUnfocusedHasBorder: false,
              thickBorderWidth: 1.5,
              thinBorderWidth: 1,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
          ),
          darkTheme: FlexThemeData.dark(
            scheme: themeCtrl.usedScheme,
            useMaterial3: themeCtrl.useMaterial3,
            surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
            blendLevel: 8,
            appBarStyle: FlexAppBarStyle.background,
            appBarOpacity: 0.94,
            appBarElevation: 0.5,
            transparentStatusBar: true,
            tabBarStyle: FlexTabBarStyle.forAppBar,
            fontFamily: fontFamily,
            textTheme: textTheme,
            primaryTextTheme: textTheme,
            subThemesData: const FlexSubThemesData(
              interactionEffects: true,
              defaultRadius: null,
              bottomSheetRadius: 24,
              useMaterial3Typography: true,
              inputDecoratorBorderType: FlexInputBorderType.outline,
              inputDecoratorIsFilled: true,
              inputDecoratorUnfocusedHasBorder: false,
              thickBorderWidth: 1.5,
              thinBorderWidth: 1,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
          ),
          home: StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
              return session != null ? const HomeScreen() : const AuthScreen();
            },
          ),
        );
      },
    );
  }
}
