class ArCardResponse {
  final String? id;
  final String? type;
  final String? title;
  final String? fileUrl;
  final String? shortCode;
  final String? audioUrl;

  ArCardResponse({
    this.id,
    this.type,
    this.title,
    this.fileUrl,
    this.shortCode,
    this.audioUrl,
  });

  factory ArCardResponse.fromJson(Map<String, dynamic> json) {
    return ArCardResponse(
      id: json['id'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      fileUrl: json['file_url'] as String?,
      shortCode: json['short_code'] as String?,
      audioUrl: json['audio_url'] as String?,
    );
  }
}
