// lib/presentation/features/registration/state/registration_provider.dart
import 'package:flutter/material.dart';

class RegistrationProvider with ChangeNotifier {
  String? _email;
  String? _nickname;
  String? _password;
  DateTime? _birthDate = DateTime(2000, 1, 1);
  String? _income;
  String? _location;
  String _maritalStatus = '';
  String _education = '';
  String _major = '';
  String _employmentStatus = '';
  List<String> _specialGroup = [];
  List<String> _interests = [];

  String? get email => _email;
  String? get nickname => _nickname;
  String? get password => _password;
  DateTime? get birthDate => _birthDate;
  String? get income => _income;
  String? get location => _location;
  String  get maritalStatus => _maritalStatus;
  String  get education => _education;
  String  get major => _major;
  String  get employmentStatus => _employmentStatus;
  List<String> get specialGroup => List.unmodifiable(_specialGroup);
  List<String> get interests => List.unmodifiable(_interests);

  void updateEmail(String v)        { _email = v; notifyListeners(); }
  void updateNickname(String v)     { _nickname = v; notifyListeners(); }
  void updatePassword(String v)     { _password = v; notifyListeners(); }
  void updateBirthDate(DateTime v)  { _birthDate = v; notifyListeners(); }
  void updateIncome(String v)       { _income = v; notifyListeners(); }
  void updateLocation(String v)     { _location = v; notifyListeners(); }

  void updateSurvey(Map<String, List<String>> s) {
    _maritalStatus    = s['혼인 여부']?.first ?? '';
    _education        = s['최종 학력']?.first ?? '';
    _major            = s['전공']?.first ?? '';
    _employmentStatus = s['취업상태']?.first ?? '';
    _specialGroup     = s['특화분야'] ?? [];
    _interests        = s['관심분야'] ?? [];
    notifyListeners();
  }

  Map<String, dynamic> toSignupJson() {
    return {
      "email": _email ?? '',
      "nickname": _nickname ?? '',
      "password": _password ?? '',
      "birthDate": (_birthDate ?? DateTime(2000,1,1)).toIso8601String().split('T')[0],
      "location": _location ?? '',
      "income": _income ?? '0',
      "maritalStatus": _maritalStatus,
      "education": _education,
      "major": _major,
      "employmentStatus": _employmentStatus,
      "specialGroup": _specialGroup,
      "interests": _interests,
    };
  }

  void reset() {
    _email = _nickname = _password = null;
    _birthDate = DateTime(2000,1,1);
    _income = _location = null;
    _maritalStatus = _education = _major = _employmentStatus = '';
    _specialGroup = [];
    _interests = [];
    notifyListeners();
  }
}
