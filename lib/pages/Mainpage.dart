import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'MainPage/HomePage.dart';
import 'MainPage/SearchPage.dart';
import 'MainPage/MyPage.dart';

=======
import 'package:shimmer/shimmer.dart';
>>>>>>> 5187ed4 (my first commit)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  static final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
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
    );
  }
}
<<<<<<< HEAD
=======

/// 홈 페이지
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("홈")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 카드
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 로봇 아이콘
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.android, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "AI가 추천한 정책",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1),
                    const SizedBox(height: 12),
                    const Text(
                      "오늘의 추천 정책은 ‘청년 지원금 정책’입니다.\n"
                          "자세한 내용은 정책 상세 페이지에서 확인하세요.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 아래 콘텐츠 (예: 더보기 리스트)
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    title: Text("1. 청년 창업 지원금"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  ListTile(
                    title: Text("2. 취업 연계 프로그램"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  ListTile(
                    title: Text("3. 주거 지원 정책"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 마이페이지
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 가짜 사용자 정보
    const userName = "홍길동";
    const email = "hong@test.com";
    const favorites = ["아이템 1", "아이템 2", "아이템 3"];

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 개인정보 영역
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(userName),
                subtitle: Text(email),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                  child: const Text('수정'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('⭐ 관심 정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            /// 관심 정보 리스트
            Expanded(
              child: ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(favorites[index]),
                    leading: const Icon(Icons.star, color: Colors.orange),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 개인정보 수정 페이지
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: "홍길동");
    final emailController = TextEditingController(text: "hong@test.com");

    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "이름"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 수정 처리 로직 (서버 연동 등)
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<String> _results = [];

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 예시: 1초 후에 결과 세팅 (서버 요청 흉내)
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _results = List.generate(5, (i) => "$query 결과 ${i + 1}");
      });
    });
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("검색")),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "검색어를 입력하세요",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 검색 결과 / 로딩 표시
          Expanded(
            child: _isLoading
                ? ListView.builder(
              itemCount: 5, // shimmer 아이템 갯수
              itemBuilder: (context, index) => _buildShimmerItem(),
            )
                : _results.isEmpty
                ? const Center(child: Text("검색 결과가 없습니다."))
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_results[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
>>>>>>> 5187ed4 (my first commit)
