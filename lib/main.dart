import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/OnBoardingPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '청정지대',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        inputDecorationTheme: const InputDecorationTheme(
          // TextField 밑줄·아웃라인 기본값 커스텀
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4263EB), width: 2),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFF4263EB),
          selectionColor: Color(0xFF4263EB),
          selectionHandleColor: Color(0xFF4263EB),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      home: const OnboardingPage(),
    );
  }
}
