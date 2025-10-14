// lib/data/models/signup_request_dto.dart
class SignupRequestDto {
  final String email;
  final String nickname;
  final String password;
  final String birthDate; // YYYY-MM-DD
  final int income;
  final String location;
  final Map<String, dynamic> survey;

  const SignupRequestDto({
    required this.email,
    required this.nickname,
    required this.password,
    required this.birthDate,
    required this.income,
    required this.location,
    required this.survey,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'nickname': nickname,
    'password': password,
    'birthDate': birthDate,
    'income': income,
    'location': location,
    'survey': survey,
  };
}