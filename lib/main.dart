import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/blocs/locale_cubit.dart';
import 'core/utils/localization_util.dart';
import 'screens/home_screen.dart';
import 'theme/colors.dart';
import 'theme/themes.dart';

// ignore: constant_identifier_names
const bool MODE_MOCK = false;
// ignore: constant_identifier_names
const bool WITH_CLEAN_PREF = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setSystemUIMode();
  requestPermissions();

  // CLEAN PREF USE
  if (WITH_CLEAN_PREF) {
    await handlerCleanPref();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final Locale initialLocale = await getStoredLocale();

  runApp(
    MultiBlocProvider(providers: [
      BlocProvider(create: (_) => LocaleCubit(initialLocale)),
    ], child: const MyApp()),
  );
}

void setSystemUIMode() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: ThemeColors.primary,
    systemNavigationBarDividerColor: ThemeColors.primary,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
}

Future<void> requestPermissions() async {
  // await [
  //  Permission.storage,
  // ].request();
}

Future<void> handlerCleanPref() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  prefs.clear();
  secureStorage.deleteAll();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
        builder: (context, state) => MaterialApp(
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                LocalizationApp.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                if (!supportedLocales.contains(locale)) {
                  return LocalizationApp.forcedLocale;
                }
                return locale;
              },
              locale: state,
              supportedLocales: LocalizationApp.supportedLocales,
              onGenerateTitle: (BuildContext context) =>
                  context.translate("common.appTitle"),
              theme: Themes.light(),
              home: const PopScope(canPop: false, child: HomeScreen()),
              // On a phone this never kicks in (screens are already
              // narrower than the cap) - it only matters on a wide browser
              // window (the web build), where stretching every screen and
              // dialog edge to edge would force hero art into an extreme,
              // unrecognizable crop and spread everything else out oddly.
              // Applied here (not per-screen) so it covers pushed routes
              // and dialogs too, not just the match screen itself.
              builder: (context, child) {
                if (child == null) return const SizedBox.shrink();
                return ColoredBox(
                  color: const Color(0xFF1b1b1b),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: child,
                    ),
                  ),
                );
              },
            ));
  }
}
