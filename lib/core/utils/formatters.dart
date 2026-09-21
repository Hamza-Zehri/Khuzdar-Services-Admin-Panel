// Small formatting helpers shared across the admin panel.

String shortId(String? value, [int length = 8]) {
  final v = value ?? '';
  if (v.isEmpty) return '—';
  if (v.length <= length) return v;
  return v.substring(0, length);
}

String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String formatCount(Object? value) {
  if (value is! num) return '0';
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}