import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cleanarea/data/constants/option_data.dart';
import 'package:cleanarea/data/constants/region_data.dart';

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
  bool _showCalendar = false;

  String? _selectedSido;
  String? _selectedSigungu;
  String? _selectedCityGu;
  String? _selectedLocation;

  Map<String, List<String>> _selectedTags = {};
  bool _isLoading = true;
  bool _showSurvey = false;
  bool _showLocation = false;
  bool _showIncome = false;

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
      for (final cat in singleSelectCategories) {
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
      _selectedLocation =
      kCityGu.containsKey(_selectedSigungu) && _selectedCityGu != null
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
      if (singleSelectCategories.contains(category)) {
        _selectedTags[category] = [option];
      } else {
        _selectedTags[category]!.contains(option)
            ? _selectedTags[category]!.remove(option)
            : _selectedTags[category]!.add(option);
      }
    });
  }

  Widget _buildTagChips(String category, List<String> options) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(category, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            children: options.map((opt) {
              final selected = _selectedTags[category]?.contains(opt) ?? false;
              return GestureDetector(
                onTap: () => _toggleTag(category, opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF4263EB) : Colors.grey
                        .shade300,
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

  Widget _buildNicknameField() =>
      Column(
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
                      return Transform.translate(
                          offset: Offset(dx, 0), child: child);
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
                                : (_nicknameSuccess != null
                                ? Colors.green
                                : Colors.grey),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _nicknameError != null
                                ? Colors.red
                                : (_nicknameSuccess != null
                                ? Colors.green
                                : const Color(0xFF4263EB)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                      '중복확인', style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('개인정보 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                title: '기본 정보',
                children: [
                  _buildDisabledField('이메일', 'user@email.com'),
                  const SizedBox(height: 16),
                  _buildNicknameField(),
                  const SizedBox(height: 16),
                  _buildDateField(),
                ],
              ),
              const SizedBox(height: 6),
              _sectionCard(
                title: '연소득',
                expandable: true,
                initiallyExpanded: _showIncome,
                onToggle: () => setState(() => _showIncome = !_showIncome),
                children: [
                  _buildIncomeField(),
                ],
              ),
              const SizedBox(height: 6),
              _sectionCard(
                title: '거주지',
                expandable: true,
                initiallyExpanded: _showLocation,
                onToggle: () => setState(() => _showLocation = !_showLocation),
                children: [
                  _buildDropdown(
                    label: '시/도 선택',
                    value: sidoSigungu.keys.contains(_selectedSido)
                        ? _selectedSido
                        : null,
                    items: sidoSigungu.keys.toList(),
                    onChanged: (v) => setState(() {
                      _selectedSido = v;
                      _selectedSigungu = null;
                      _selectedCityGu = null;
                      _updateLocationString();
                    }),
                  ),
                  if (_selectedSido != null)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, -0.05),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _selectedSido != null
                          ? Column(
                        key: const ValueKey('sigungu'),
                        children: [
                          _buildDropdown(
                            label: '시/군/구 선택',
                            value: (sidoSigungu[_selectedSido]
                                ?.contains(_selectedSigungu) ??
                                false)
                                ? _selectedSigungu
                                : null,
                            items: sidoSigungu[_selectedSido] ?? [],
                            onChanged: (v) => setState(() {
                              _selectedSigungu = v;
                              _selectedCityGu = null;
                              _updateLocationString();
                            }),
                          ),
                        ],
                      )
                          : const SizedBox.shrink(),
                    ),
                  if (_selectedSigungu != null &&
                      kCityGu.containsKey(_selectedSigungu))
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, -0.05),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: (_selectedSigungu != null &&
                          kCityGu.containsKey(_selectedSigungu))
                          ? Column(
                        key: const ValueKey('citygu'),
                        children: [
                          _buildDropdown(
                            label: '행정구 선택',
                            value: kCityGu[_selectedSigungu]!.contains(_selectedCityGu)
                                ? _selectedCityGu
                                : null,
                            items: kCityGu[_selectedSigungu] ?? [],
                            onChanged: (v) => setState(() {
                              _selectedCityGu = v;
                              _updateLocationString();
                            }),
                          ),
                        ],
                      )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _sectionCard(
                title: '상세 정보',
                expandable: true,
                initiallyExpanded: _showSurvey,
                onToggle: () => setState(() => _showSurvey = !_showSurvey),
                children: [
                  for (final entry in options.entries)
                    _buildTagChips(entry.key, entry.value),
                ],
              ),

              const SizedBox(height: 32),

              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4263EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================= //
  // widgets
  // ================================================================= //
  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    bool expandable = false,
    bool initiallyExpanded = true,
    VoidCallback? onToggle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: expandable ? onToggle : null,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (expandable)
                  AnimatedRotation(
                    turns: initiallyExpanded ? 0.5 : 0.0, // ▼ ↕ 애니메이션 회전
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more, size: 24),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                SizeTransition(sizeFactor: anim, child: child),
            child: initiallyExpanded
                ? Padding(
              key: const ValueKey('expanded'),
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _incomeController,
          keyboardType: TextInputType.number,
          onChanged: _onIncomeChanged,
          decoration: InputDecoration(
            prefixText: '₩ ',
            hintText: '예: 30,000,000',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '※ 세전 기준 연소득을 입력해주세요',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDisabledField(String label, String value) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF2F3F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ✅ RegisterPage4 스타일의 "눌렀을 때만 캘린더 슬라이드 표시"
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showCalendar = !_showCalendar),
          child: AbsorbPointer(
            child: TextField(
              controller: _birthDateController,
              decoration: InputDecoration(
                labelText: '생년월일',
                suffixIcon: Icon(
                  _showCalendar
                      ? Icons.keyboard_arrow_up
                      : Icons.calendar_today_outlined,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              SizeTransition(sizeFactor: anim, child: child),
          child: _showCalendar
              ? Container(
            key: const ValueKey('calendar'),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CalendarDatePicker(
                  initialDate:
                  _selectedBirthDate ?? DateTime(2000, 1, 1),
                  firstDate: DateTime(1930),
                  lastDate: DateTime.now(),
                  onDateChanged: (date) {
                    setState(() {
                      _selectedBirthDate = date;
                      _birthDateController.text =
                          DateFormat('yyyy-MM-dd').format(date);
                      _showCalendar = false;
                    });
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedBirthDate == null
                      ? '날짜를 선택해주세요'
                      : '${_selectedBirthDate!.year}년 ${_selectedBirthDate!.month}월 ${_selectedBirthDate!.day}일',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildModalButton({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value ?? '$label 선택',
                style: TextStyle(
                  color: value == null ? Colors.grey[500] : Colors.black87,
                  fontSize: 15,
                ),
              ),
              const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              )),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: Colors.grey),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: items.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _modalPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    String? selectedValue,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final selected = e == selectedValue;
                    return ListTile(
                      title: Text(
                        e,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF4263EB)
                              : Colors.black87,
                          fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check, color: Color(0xFF4263EB))
                          : null,
                      onTap: () => Navigator.pop(context, e),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openLocationSelector() async {
    String? sido = _selectedSido;
    String? sigungu = _selectedSigungu;
    String? cityGu = _selectedCityGu;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('거주지 선택',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // 시/도 선택
                  _buildModalButton(
                    label: '시/도',
                    value: sido,
                    onTap: () async {
                      final result = await _modalPicker(
                        context: context,
                        title: '시/도 선택',
                        items: sidoSigungu.keys.toList(),
                        selectedValue: sido,
                      );
                      if (result != null) {
                        setModalState(() {
                          sido = result;
                          sigungu = null;
                          cityGu = null;
                        });
                      }
                    },
                  ),

                  // 시군구 선택
                  if (sido != null)
                    _buildModalButton(
                      label: '시/군/구',
                      value: sigungu,
                      onTap: () async {
                        final result = await _modalPicker(
                          context: context,
                          title: '시/군/구 선택',
                          items: sidoSigungu[sido] ?? [],
                          selectedValue: sigungu,
                        );
                        if (result != null) {
                          setModalState(() {
                            sigungu = result;
                            cityGu = null;
                          });
                        }
                      },
                    ),

                  // 행정구 선택
                  if (sigungu != null && kCityGu.containsKey(sigungu))
                    _buildModalButton(
                      label: '행정구',
                      value: cityGu,
                      onTap: () async {
                        final result = await _modalPicker(
                          context: context,
                          title: '행정구 선택',
                          items: kCityGu[sigungu] ?? [],
                          selectedValue: cityGu,
                        );
                        if (result != null) {
                          setModalState(() => cityGu = result);
                        }
                      },
                    ),

                  const SizedBox(height:6),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedSido = sido;
                        _selectedSigungu = sigungu;
                        _selectedCityGu = cityGu;
                        _updateLocationString();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4263EB),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
      },
    );
  }





}