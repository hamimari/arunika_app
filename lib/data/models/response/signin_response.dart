class SignInResponse {
  final String token;
  final String refreshToken;
  final String userId;

  SignInResponse({
    required this.token,
    required this.userId,
    required this.refreshToken,
  });

  factory SignInResponse.fromJson(Map<String, dynamic> json) {
    return SignInResponse(
      token: json['access_token'],
      userId: json['user_id'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': token,
      'userId': userId,
      'refreshToken': refreshToken,
    };
  }
}