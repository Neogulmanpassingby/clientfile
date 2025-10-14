// lib/core/routes/app_router.dart
import 'package:go_router/go_router.dart';

import '../auth/token_utils.dart'; // getValidAccessToken 여기서만 import
// 점진 이전 중: 기존 pages
import '../../presentation/features/main_app/Mainpage.dart';
import '../../presentation/features/auth/OnBoardingPage.dart';
import '../../presentation/features/main_app/core/PolicyDetailPage.dart';
import '../../presentation/features/auth/LoginPage.dart';
import '../../presentation/features/auth/ClapAnimationPage.dart';
import '../../presentation/features/main_app/mypage/InterestPoliciesPage.dart';
import '../../presentation/features/main_app/home/RecommendPage.dart';
import '../../presentation/features/auth/registration/view/RegisterFlow.dart';
import '../../presentation/features/main_app/mypage/EditPage.dart';

/// 앱 시작 전에 호출해서 로그인 여부만 Bool로 뽑음
Future<bool> fetchLoginFlag() async {
  try {
    final token = await getValidAccessToken();
    return token != null;
  } catch (_) {
    return false;
  }
}

class ClapArgs {
  final int mode;         // 0=Sign-Up, 1=Login
  final String nickname;
  const ClapArgs({required this.mode, required this.nickname});
}


GoRouter createRouter({required bool isLoggedIn}) {
  return GoRouter(
    debugLogDiagnostics: true, // 초기 문제 추적에 도움
    initialLocation: '/',      // 항상 루트로 시작
    routes: [
      // 루트는 동기 리다이렉트만 담당
      GoRoute(
        path: '/',
        redirect: (_, __) => isLoggedIn ? '/main' : '/onboarding',
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterFlow(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/main',
        builder: (_, state) {
          final tabStr = state.uri.queryParameters['tab'] ?? '0';
          final initialIndex = int.tryParse(tabStr) ?? 0;
          return MainPage(initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/celebrate',
        builder: (_, state) {
          final args = state.extra is ClapArgs
              ? state.extra as ClapArgs
              : const ClapArgs(mode: 0, nickname: '사용자');
          return ClapAnimationPage(mode: args.mode, nickname: args.nickname);
        },
      ),
      GoRoute(
        name: 'recommend',
        path: '/recommend',
        builder: (ctx, st) => const RecommendPage(),
      ),
      GoRoute(
        name: 'policyDetail',
        path: '/search/:id',
        builder: (ctx, st) {
          final id = st.pathParameters['id']!;
          return PolicyDetailPage(policyId: int.parse(id));
        },
      ),
      GoRoute(
        name: 'likes',
        path: '/likes',
        builder: (ctx, st) => const InterestPoliciesPage(),
      ),
      GoRoute(
        name: 'edit',
        path: '/edit',
        builder: (ctx, st) => const EditProfilePage(),
      ),
    ],
  );
}
