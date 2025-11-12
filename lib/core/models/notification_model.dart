import 'dart:convert';

class NotificationModel {
  const NotificationModel({
    required this.title,
    required this.text,
    required this.package,
    required this.time,
    required this.extras,
    required this.actions,
  });

  final String title;
  final String text;
  final String package;
  final DateTime time;
  final Map<String, dynamic> extras;
  final List<String> actions;

  factory NotificationModel.fromJsonString(String source) =>
      NotificationModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      package: json['package']?.toString() ?? '',
      time: _parseTime(json['time']),
      extras: _mapExtras(json['extras']),
      actions: _parseActions(json['actions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'text': text,
    'package': package,
    'time': time.millisecondsSinceEpoch,
    'extras': extras,
    'actions': actions,
  };

  String toJsonString() => jsonEncode(toJson());

  static DateTime _parseTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsed);
      }
      final date = DateTime.tryParse(value);
      if (date != null) {
        return date;
      }
    }
    return DateTime.now();
  }

  static Map<String, dynamic> _mapExtras(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry('$key', v));
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return {'raw': value};
      }
    }
    return const {};
  }

  static List<String> _parseActions(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const [];
  }
}
