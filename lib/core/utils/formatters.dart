import 'package:intl/intl.dart';

/// Money formatter for IDR, matching the backend's `Rp 1.234.567` style.
class Money {
  Money._();

  static final NumberFormat _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num? value) {
    if (value == null) return 'Rp 0';
    return _idr.format(value);
  }

  /// Parses "Rp 1.234.567" / "1.234.567" back to a double.
  static double? parse(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(cleaned);
  }
}

/// Date formatter that handles both ISO-8601 strings and `YYYY-MM-DD`.
class DateFormatter {
  DateFormatter._();

  static String fullDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = _parse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
  }

  static String dateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = _parse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(dt);
  }

  static String timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = _parse(iso);
    if (dt == null) return iso;
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
  }

  static DateTime? _parse(String input) {
    try {
      return DateTime.parse(input);
    } catch (_) {
      return null;
    }
  }
}

/// Tiny helpers for reading values out of JSON where the shape may vary.
class JsonHelper {
  JsonHelper._();

  static String? string(Object? json, [String key = '']) {
    if (json is Map) {
      if (key.isNotEmpty) {
        final v = json[key];
        return v?.toString();
      }
      return json.toString();
    }
    return json?.toString();
  }

  static int? intValue(Object? json, [String key = '']) {
    if (json is Map) {
      final v = key.isEmpty ? null : json[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }
    return null;
  }

  static double? doubleValue(Object? json, [String key = '']) {
    if (json is Map) {
      final v = key.isEmpty ? null : json[key];
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }
    if (json is num) return json.toDouble();
    return null;
  }

  static bool? boolValue(Object? json, [String key = '']) {
    if (json is Map) {
      final v = key.isEmpty ? null : json[key];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return null;
    }
    return null;
  }

  static Map<String, dynamic>? map(Object? json, [String key = '']) {
    if (json is Map) {
      if (key.isEmpty) return Map<String, dynamic>.from(json);
      final v = json[key];
      if (v is Map) return Map<String, dynamic>.from(v);
    }
    return null;
  }

  static List<Map<String, dynamic>>? list(Object? json, [String key = '']) {
    if (json is Map) {
      final v = key.isEmpty ? null : json[key];
      if (v is List) {
        return v.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
    }
    if (json is List) {
      return json.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    return null;
  }
}
