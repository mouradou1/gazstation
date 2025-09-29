import 'dart:math' as math;

String formatNumber(num value, {int decimals = 0}) {
  final isNegative = value < 0;
  final fixedValue = value.abs().toStringAsFixed(decimals);
  final parts = fixedValue.split('.');
  final integerPart = parts.first;

  final chunks = <String>[];
  for (var i = integerPart.length; i > 0; i -= 3) {
    final start = math.max(0, i - 3);
    chunks.add(integerPart.substring(start, i));
  }
  final formattedInt = chunks.reversed.join(' ');

  var result = formattedInt;
  if (decimals > 0 && parts.length > 1) {
    final fractional = parts[1].padRight(decimals, '0');
    if (int.tryParse(fractional) != 0) {
      result = '$formattedInt.${fractional.substring(0, decimals)}';
    }
  }

  if (isNegative && result != '0') {
    result = '-$result';
  }
  return result;
}

String formatLiters(num value, {int decimals = 0}) {
  return '${formatNumber(value, decimals: decimals)} L';
}

String formatMillimeters(num value, {int decimals = 0}) {
  return '${formatNumber(value, decimals: decimals)} mm';
}

String formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
