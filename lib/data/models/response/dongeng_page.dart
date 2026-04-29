class DongengPage {
  final String id;
  final String dongengId;
  final int pageNumber;
  final String imageUrl;
  final String text;
  final String audioUrl;

  const DongengPage({
    required this.id,
    required this.dongengId,
    required this.pageNumber,
    required this.imageUrl,
    required this.text,
    this.audioUrl = '',
  });

  factory DongengPage.fromJson(Map<String, dynamic> json) {
    return DongengPage(
      id: json['id'] as String,
      dongengId: json['dongeng_id'] as String,
      pageNumber: json['page_number'] as int,
      imageUrl: json['image_url'] as String,
      text: json['text'] as String,
      audioUrl: (json['audio_url'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dongeng_id': dongengId,
      'page_number': pageNumber,
      'image_url': imageUrl,
      'text': text,
      'audio_url': audioUrl,
    };
  }
}
