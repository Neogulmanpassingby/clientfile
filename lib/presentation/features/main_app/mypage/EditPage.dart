import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  // ------------------------ controller & util ------------------------ //
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _incomeController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _formatter = NumberFormat('#,###');

  late final AnimationController _shakeController;
  String? _nicknameError;
  String? _nicknameSuccess;

  // ----------------------------- state ----------------------------- //
  DateTime? _selectedBirthDate;
  String? _selectedSido;
  String? _selectedSigungu;
  String? _selectedCityGu;
  String? _selectedLocation;

  Map<String, List<String>> _selectedTags = {};

  bool _isLoading = true;

  // ------------------------- constants ------------------------- //
  final Set<String> _singleSelectCategories = {
    '혼인 여부',
    '최종 학력',
    '전공',
    '취업 상태',
  };

  final Map<String, List<String>> _options = {
    '혼인 여부': ['기혼', '미혼'],
    '최종 학력': [
      '고졸 미만',
      '고교 재학',
      '고교 졸업',
      '대학 재학',
      '대졸 예정',
      '대학 졸업',
      '대학 석/박사'
    ],
    '전공': [
      '인문계열',
      '사회계열',
      '상경계열',
      '이학계열',
      '공학계열',
      '예체능계열',
      '농산업계열',
      '기타'
    ],
    '취업 상태': [
      '재직자',
      '자영업자',
      '미취업자',
      '프리랜서',
      '일용근로자',
      '(예비)창업자',
      '단기근로자',
      '영농종사자',
      '기타'
    ],
    '특화 분야': [
      '중소기업',
      '여성',
      '기초생활수급자',
      '한부모가정',
      '장애인',
      '농업인',
      '군인',
      '지역인재',
      '기타'
    ],
    '관심 분야': [
      '대출',
      '보조금',
      '바우처',
      '금리혜택',
      '교육지원',
      '맞춤형상담서비스',
      '인턴',
      '벤처',
      '중소기업',
      '청년가장',
      '장기미취업청년',
      '공공임대주택',
      '신용회복',
      '육아',
      '출산',
      '해외진출',
      '주거지원'
    ],
  };

  // 실제 서비스에선 별도 파일로 분리 권장
  final Map<String, List<String>> _sidoSigungu = {
    '서울특별시': [
      '종로구', '중구', '용산구', '성동구', '광진구', '동대문구', '중랑구', '성북구',
      '강북구', '도봉구', '노원구', '은평구', '서대문구', '마포구', '양천구', '강서구',
      '구로구', '금천구', '영등포구', '동작구', '관악구', '서초구', '강남구', '송파구',
      '강동구',
    ],
    '부산광역시': [
      '중구', '서구', '동구', '영도구', '부산진구', '동래구', '남구', '북구',
      '해운대구', '사하구', '금정구', '강서구', '연제구', '수영구', '사상구', '기장군',
    ],
    '대구광역시': [
      '중구', '동구', '서구', '남구', '북구', '수성구', '달서구', '달성군',
    ],
    '인천광역시': [
      '중구', '동구', '미추홀구', '연수구', '남동구', '부평구', '계양구', '서구',
      '강화군', '옹진군',
    ],
    '광주광역시': ['동구', '서구', '남구', '북구', '광산구'],
    '대전광역시': ['동구', '중구', '서구', '유성구', '대덕구'],
    '울산광역시': ['중구', '남구', '동구', '북구', '울주군'],
    '세종특별자치시': ['세종특별자치시'],
    '경기도': [
      '수원시', '성남시', '의정부시', '안양시', '부천시', '광명시', '평택시', '동두천시',
      '안산시', '고양시', '과천시', '구리시', '남양주시', '오산시', '시흥시', '군포시',
      '의왕시', '하남시', '용인시', '파주시', '이천시', '안성시', '김포시', '화성시',
      '광주시', '여주시', '양평군', '연천군', '포천시', '가평군',
    ],
    '강원도': [
      '춘천시', '원주시', '강릉시', '동해시', '태백시', '속초시', '삼척시', '홍천군',
      '횡성군', '영월군', '평창군', '정선군', '철원군', '화천군', '양구군', '인제군',
      '고성군', '양양군',
    ],
    '충청북도': [
      '청주시', '충주시', '제천시', '보은군', '옥천군', '영동군', '증평군', '진천군',
      '괴산군', '음성군', '단양군',
    ],
    '충청남도': [
      '천안시', '공주시', '보령시', '아산시', '서산시', '논산시', '계룡시', '당진시',
      '금산군', '부여군', '서천군', '청양군', '홍성군', '예산군', '태안군',
    ],
    '전라북도': [
      '전주시', '군산시', '익산시', '정읍시', '남원시', '김제시', '완주군', '진안군',
      '무주군', '장수군', '임실군', '순창군', '고창군', '부안군',
    ],
    '전라남도': [
      '목포시', '여수시', '순천시', '나주시', '광양시', '담양군', '곡성군', '구례군',
      '고흥군', '보성군', '화순군', '장흥군', '강진군', '해남군', '영암군', '무안군',
      '함평군', '영광군', '장성군', '완도군', '진도군', '신안군',
    ],
    '경상북도': [
      '포항시', '경주시', '김천시', '안동시', '구미시', '영주시', '영천시', '상주시',
      '문경시', '경산시', '군위군', '의성군', '청송군', '영양군', '영덕군', '청도군',
      '고령군', '성주군', '칠곡군', '예천군', '봉화군', '울진군', '울릉군',
    ],
    '경상남도': [
      '창원시', '진주시', '통영시', '사천시', '김해시', '밀양시', '거제시', '양산시',
      '의령군', '함안군', '창녕군', '고성군', '남해군', '하동군', '산청군', '함양군',
      '거창군', '합천군',
    ],
    '제주특별자치도': ['제주시', '서귀포시'],
  };
  final Map<String, List<String>> kCityGu = {
    '인천시': ['중구', '동구', '남구', '북구'],
    '수원시': ['장안구', '권선구', '팔달구', '영통구'],
    '성남시': ['수정구', '중원구', '분당구'],
    '안양시': ['만안구', '동안구'],
    '부천시': ['중구', '원미구', '남구', '소사구', '오정구'],
    '안산시': ['상록구', '단원구'],
    '고양시': ['덕양구', '일산동구', '일산서구'],
    '용인시': ['처인구', '기흥구', '수지구'],
    '청주시': ['상당구', '서원구', '흥덕구', '청원구'],
    '전주시': ['완산구', '덕진구'],
    '광주시': ['동구', '서구', '북구', '광산구'],
    '창원시': ['의창구', '성산구', '마산합포구', '마산회원구', '진해구'],
    '대전시': ['동구', '중구', '서구'],
    '천안시': ['동남구', '서북구'],
    '포항시': ['남구', '북구'],
    '부산시': ['중구', '서구', '동구', '영도구', '동래구'],
    '울산시': ['중구', '남구', '동구', '북구', '울주군'],
    '마산시': ['합포구', '회원구'],
  };
  // ================================================================= //
  // lifecycle
  // ================================================================= //

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fetchUserInfo();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _emailController.dispose();
    _nicknameController.dispose();
    _birthDateController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  // ================================================================= //
  // data I/O
  // ================================================================= //

  Future<void> _fetchUserInfo() async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.get(
      Uri.parse('$baseUrl/api/mypage/detail'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      setState(() => _isLoading = false);
      debugPrint('유저 정보 불러오기 실패: ${res.body}');
      return;
    }

    final data = jsonDecode(res.body);
    setState(() {
      _emailController.text = data['email'] ?? '';
      _nicknameController.text = data['nickname'] ?? '';

      final birthStr = data['birthDate']?.toString() ?? '';
      if (birthStr.isNotEmpty) {
        final parsed = DateTime.tryParse(birthStr);
        if (parsed != null) {
          _selectedBirthDate = parsed;
          _birthDateController.text = DateFormat('yyyy-MM-dd').format(parsed);
        }
      }

      final rawIncome = data['income']?.toString().replaceAll(',', '') ?? '0';
      _incomeController.text = _formatter.format(int.tryParse(rawIncome) ?? 0);

      final loc = (data['location'] ?? '').toString().split(' ');
      if (loc.length >= 2) {
        _selectedSido = loc[0];
        _selectedSigungu = loc[1];
      }
      if (loc.length == 3) _selectedCityGu = loc[2];
      _updateLocationString();

      final tagMap = data['tags'] as Map<String, dynamic>? ?? {};
      _selectedTags = tagMap.map((k, v) => MapEntry(k, List<String>.from(v)));
      for (final cat in _singleSelectCategories) {
        _selectedTags.putIfAbsent(cat, () => []);
      }

      _isLoading = false;
    });
  }

  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    final token = await _storage.read(key: 'access_token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/auth/check-nickname?nickname=$nickname'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final exists = jsonDecode(res.body)['data']['exists'] as bool;

        setState(() {
          if (exists) {
            _nicknameError = '이미 사용 중인 닉네임입니다';
            _nicknameSuccess = null;
            _shakeController.forward(from: 0);
          } else {
            _nicknameError = null;
            _nicknameSuccess = '사용 가능한 닉네임입니다';
          }
        });
      } else {
        setState(() {
          _nicknameError = '서버 오류가 발생했습니다';
          _nicknameSuccess = null;
        });
      }
    } catch (e) {
      setState(() {
        _nicknameError = '요청 실패: ${e.toString()}';
        _nicknameSuccess = null;
      });
    }
  }



  Future<void> _saveProfile() async {
    final token = await _storage.read(key: 'access_token');

    final body = {
      'email': _emailController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'birthDate': _selectedBirthDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
          : '',
      'location': _selectedLocation ?? '',
      'income': _incomeController.text.replaceAll(',', '').trim(),
      'maritalStatus': _selectedTags['혼인 여부']?.first ?? '',
      'education': _selectedTags['최종 학력']?.first ?? '',
      'major': _selectedTags['전공']?.first ?? '',
      'employmentStatus': _selectedTags['취업 상태'] ?? [],
      'specialGroup': _selectedTags['특화 분야'] ?? [],
      'interests': _selectedTags['관심 분야'] ?? [],
    };

    final res = await http.put(
      Uri.parse('$baseUrl/api/mypage/edit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.statusCode == 200 ? '저장되었습니다' : '저장에 실패했습니다'),
      ),
    );
    if (res.statusCode == 200) Navigator.pop(context);
  }

  // ================================================================= //
  // util
  // ================================================================= //

  void _updateLocationString() {
    if (_selectedSido != null && _selectedSigungu != null) {
      _selectedLocation = kCityGu.containsKey(_selectedSigungu) && _selectedCityGu != null
          ? '$_selectedSido $_selectedSigungu $_selectedCityGu'
          : '$_selectedSido $_selectedSigungu';
    }
  }

  void _onIncomeChanged(String value) {
    final numeric = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.isEmpty) {
      _incomeController.clear();
      return;
    }
    final formatted = _formatter.format(int.parse(numeric));
    _incomeController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _toggleTag(String category, String option) {
    setState(() {
      _selectedTags.putIfAbsent(category, () => []);
      if (_singleSelectCategories.contains(category)) {
        _selectedTags[category] = [option];
      } else {
        _selectedTags[category]!.contains(option)
            ? _selectedTags[category]!.remove(option)
            : _selectedTags[category]!.add(option);
      }
    });
  }

  Widget _buildTagChips(String category, List<String> options) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Wrap(
        children: options.map((opt) {
          final selected = _selectedTags[category]?.contains(opt) ?? false;
          return GestureDetector(
            onTap: () => _toggleTag(category, opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF4263EB) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );

  Widget _buildNicknameField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final dx = sin(_shakeController.value * pi * 4) * 6;
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    errorText: null, // ✅ 완전히 제거
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _nicknameError != null
                            ? Colors.red
                            : (_nicknameSuccess != null ? Colors.green : Colors.grey),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _nicknameError != null
                            ? Colors.red
                            : (_nicknameSuccess != null ? Colors.green : const Color(0xFF4263EB)),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _checkNickname,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4263EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('중복확인', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      if (_nicknameError != null)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 8),
          child: Text(
            _nicknameError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      if (_nicknameSuccess != null)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 8),
          child: Text(
            _nicknameSuccess!,
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
        ),
    ],
  );
  

  // ================================================================= //
  // build
  // ================================================================= //

  @override
  Widget build(BuildContext context) {
    final sigunguList = _selectedSido == null ? [] : _sidoSigungu[_selectedSido] ?? [];
    final cityGuList =
    _selectedSigungu != null && kCityGu.containsKey(_selectedSigungu) ? kCityGu[_selectedSigungu] ?? [] : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('개인정보 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        enabled: false,
                        decoration: const InputDecoration(labelText: '이메일'),
                      ),
                      const SizedBox(height: 16),
                      _buildNicknameField(),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _birthDateController,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: '생년월일'),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData(
                                  useMaterial3: false, // M2처럼 원형 강조
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF4263EB), // ✅ 선택된 날짜 원 배경색
                                    onPrimary: Colors.white,    // ✅ 원 안 텍스트색
                                    surface: Colors.white,
                                    onSurface: Colors.black,    // 일반 날짜 텍스트색
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    // ✅ 날짜 셀 모양을 '원'으로 강제
                                    dayShape: const WidgetStatePropertyAll<OutlinedBorder?>(CircleBorder()),

                                    // ✅ 날짜 숫자 크기(선택/비선택 공통)
                                    dayStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),

                                    // ✅ 선택 상태 배경/전경 색
                                    dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) return const Color(0xFF4263EB);
                                      return null; // 기본(투명)
                                    }),
                                    dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) return Colors.white;
                                      if (states.contains(WidgetState.disabled)) return Colors.black38;
                                      return null; // 시스템 기본
                                    }),

                                    // (옵션) 오늘 표시 색감 보강
                                    todayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) return const Color(0xFF4263EB);
                                      return const Color(0x334263EB); // 약한 배경
                                    }),
                                    todayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) return Colors.white;
                                      return const Color(0xFF4263EB);
                                    }),

                                    // (옵션) 헤더 텍스트 크기
                                    headerHeadlineStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                    headerHelpStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            setState(() {
                              _selectedBirthDate = picked;
                              _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('거주지', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('시/도 선택'),
                        value: _sidoSigungu.keys.contains(_selectedSido) ? _selectedSido : null,
                        items: _sidoSigungu.keys
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedSido = v;
                          _selectedSigungu = null;
                          _selectedCityGu = null;
                          _updateLocationString();
                        }),
                      ),
                      if (_selectedSido != null)
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('시/군/구 선택'),
                          value: sigunguList.contains(_selectedSigungu) ? _selectedSigungu : null,
                          items: sigunguList
                              .map<DropdownMenuItem<String>>((g) => DropdownMenuItem<String>(
                            value: g,
                            child: Text(g),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedSigungu = v;
                            _selectedCityGu = null;
                            _updateLocationString();
                          }),
                        ),
                      if (cityGuList.isNotEmpty)
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('행정구 선택'),
                          value: cityGuList.contains(_selectedCityGu) ? _selectedCityGu : null,
                          items: cityGuList.cast<String>().map<DropdownMenuItem<String>>((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() {
                            _selectedCityGu = v;
                            _updateLocationString();
                          }),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _incomeController,
                        keyboardType: TextInputType.number,
                        onChanged: _onIncomeChanged,
                        decoration: const InputDecoration(
                          labelText: '연소득',
                          prefixText: '₩ ',
                        ),
                      ),
                      const Divider(height: 32),
                      for (final entry in _options.entries) _buildTagChips(entry.key, entry.value),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4263EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
