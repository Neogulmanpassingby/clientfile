import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'MainPage/HomePage.dart';
import 'MainPage/SearchPage.dart';
import 'MainPage/MyPage.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;
  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // ✅ 탭 전환 시마다 "새 인스턴스"를 반환 (상태 유지 안 함)
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const HomePage(key: ValueKey('home'));
      case 1:
        return const SearchPage(key: ValueKey('search'));
      case 2:
        return const MyPage(key: ValueKey('mypage'));
      default:
        return const SizedBox.shrink();
    }
  }

  void _showExitSnackBar(BuildContext context, {String message = '한 번 더 뒤로가기를 누르면 앱이 종료됩니다', Duration duration = const Duration(seconds: 2)}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: EdgeInsets.only(left: 20, right: 20, bottom: 20 + MediaQuery.of(context).viewPadding.bottom),
      content: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 280),
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - t)), // 아래에서 살짝 올라오게
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xDB1A1A1A),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14))),
            ],
          ),
        ),
      ),
    );

    messenger.showSnackBar(snack);
  }

  Future<bool> _onWillPop() async {
    final rootNav = Navigator.of(context, rootNavigator: true);

    // 상세 페이지 등 push된 라우트가 있으면 pop
    if (rootNav.canPop()) {
      rootNav.pop();
      return false;
    }

    // 홈 탭에서 2초 내 두 번 누르면 종료
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      _showExitSnackBar(context);
      return false;
    }

    if (Platform.isAndroid) {
      SystemNavigator.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          // 🔄 이전 페이지 dispose, 새 페이지 mount (스택에 안 쌓임)
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _buildCurrentPage(),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: '검색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '마이페이지',
            ),
          ],
        ),
      ),
    );
  }
}
