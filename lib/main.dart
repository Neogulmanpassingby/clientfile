import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/OnBoardingPage.dart';
import 'utils/token_utils.dart';
import 'pages/MainPage/HomePage.dart';
import 'pages/LoginPage.dart';
import 'pages/Mainpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await getValidAccessToken();
  final Widget startPage = (token != null)
      ? const MainPage() // 유효한 토큰 있으면 홈
      : const OnboardingPage(); // 없으면 로그인

  runApp(MyApp(startPage: startPage)); // 수정된 부분
}

class MyApp extends StatelessWidget {
  final Widget startPage; // 추가된 필드
  const MyApp({super.key, required this.startPage});

  static const Color primaryColor = Color(0xFF4263EB);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '청정지대',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionColor: primaryColor,
          selectionHandleColor: primaryColor,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
        ),
      ),
      localizationsDelegates: _localizationDelegates,
      supportedLocales: _supportedLocales,
      home: startPage,
    );
  }

  static const _localizationDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const _supportedLocales = [Locale('ko', 'KR'), Locale('en', 'US')];
}
