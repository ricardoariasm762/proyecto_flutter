import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/theme_controller.dart';
import 'screens/splash_screen.dart';
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
        ChangeNotifierProvider(
          create: (context) =>
              HomeController(LocationService(), context.read<RideService>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        context.read<LanguageController>(),
      ]),
      builder: (context, _) {
        final themeCtrl = ThemeController.instance;

        final String? fontFamily = GoogleFonts.poppins().fontFamily;
        const TextTheme textTheme = TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RideMatch Comunidad',
          themeMode: themeCtrl.themeMode,
          theme: FlexThemeData.light(
            scheme: themeCtrl.usedScheme,
            useMaterial3: themeCtrl.useMaterial3,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 7,
            appBarStyle: FlexAppBarStyle.background,
            appBarOpacity: 1.0,
            appBarElevation: 0,
            transparentStatusBar: true,
            tabBarStyle: FlexTabBarStyle.forAppBar,
            fontFamily: fontFamily,
            textTheme: textTheme,
            primaryTextTheme: textTheme,
            subThemesData: const FlexSubThemesData(
              interactionEffects: true,
              defaultRadius: 12.0,
              bottomSheetRadius: 24,
              useMaterial3Typography: true,
              inputDecoratorBorderType: FlexInputBorderType.outline,
              inputDecoratorIsFilled: true,
              inputDecoratorUnfocusedHasBorder: false,
              inputDecoratorFocusedHasBorder: true,
              inputDecoratorFillColor: Color(0xFFF3F3F3),
              inputDecoratorBorderWidth: 1.0,
              thickBorderWidth: 1.5,
              thinBorderWidth: 1,
              elevatedButtonSchemeColor: SchemeColor.onPrimary,
              elevatedButtonSecondarySchemeColor: SchemeColor.primary,
              cardRadius: 16.0,
              cardElevation: 0,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
          ),
          darkTheme: FlexThemeData.dark(
            scheme: themeCtrl.usedScheme,
            useMaterial3: themeCtrl.useMaterial3,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 13,
            appBarStyle: FlexAppBarStyle.background,
            appBarOpacity: 1.0,
            appBarElevation: 0,
            transparentStatusBar: true,
            tabBarStyle: FlexTabBarStyle.forAppBar,
            fontFamily: fontFamily,
            textTheme: textTheme,
            primaryTextTheme: textTheme,
            subThemesData: const FlexSubThemesData(
              interactionEffects: true,
              defaultRadius: 12.0,
              bottomSheetRadius: 24,
              useMaterial3Typography: true,
              inputDecoratorBorderType: FlexInputBorderType.outline,
              inputDecoratorIsFilled: true,
              inputDecoratorUnfocusedHasBorder: false,
              inputDecoratorFocusedHasBorder: true,
              inputDecoratorBorderWidth: 1.0,
              thickBorderWidth: 1.5,
              thinBorderWidth: 1,
              elevatedButtonSchemeColor: SchemeColor.onPrimary,
              elevatedButtonSecondarySchemeColor: SchemeColor.primary,
              cardRadius: 16.0,
              cardElevation: 0,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
