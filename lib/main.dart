import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_data.dart';
import 'providers/cgpa_provider.dart';
import 'providers/data_provider.dart';
import 'providers/gpa_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppData()..load()),
        ChangeNotifierProvider(create: (_) => GpaProvider()..load()),
        ChangeNotifierProvider(create: (_) => CgpaProvider()..load()),
        ChangeNotifierProvider(create: (_) => DataProvider()..load()),
      ],
      child: Consumer<AppData>(
        builder: (context, data, _) {
          return MaterialApp(
            title: 'MCKRU CGPA Calculator',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: data.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.0),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
