import 'dart:convert';

class RecentMessage {
  final String text;
  final DateTime timestamp;

  const RecentMessage({required this.text, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RecentMessage.fromJson(Map<String, dynamic> json) => RecentMessage(
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  static List<RecentMessage> fromJsonList(String jsonString) {
    final list = jsonDecode(jsonString) as List;
    return list
        .map((e) => RecentMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String toJsonList(List<RecentMessage> messages) {
    return jsonEncode(messages.map((m) => m.toJson()).toList());
  }
}
