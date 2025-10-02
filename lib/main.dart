import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/OnBoardingPage.dart';
import 'utils/token_utils.dart';
import 'pages/MainPage/HomePage.dart';
import 'pages/LoginPage.dart';
import 'pages/Mainpage.dart';

void main() async {
  // 1. Flutter engine 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  // 2. 유효한 액세스 토큰 확인
  final token = await getValidAccessToken();
  // 3. 토큰 유무에 따라 시작페이지 결정
  final Widget startPage = (token != null)
      ? const MainPage() // 토큰 있으면 : 메인페이지로
      : const OnboardingPage(); // 토큰 없으면 : 온보딩 페이지로
  // 4. 결정된 페이지를 시작점으로 앱 실행
  runApp(MyApp(startPage: startPage));
}

class MyApp extends StatelessWidget {
  final Widget startPage;
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
