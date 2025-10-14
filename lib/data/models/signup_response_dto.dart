// lib/data/models/signup_response_dto.dart
class SignupResponseDto {
  final String? token;
  final String? nickname;

  const SignupResponseDto({this.token, this.nickname});

  factory SignupResponseDto.fromJson(Map<String, dynamic> j) => SignupResponseDto(
    token: j['token'] as String?,
    nickname: j['nickname'] as String?,
  );
}