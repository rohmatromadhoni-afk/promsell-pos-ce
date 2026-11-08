import 'package:intl/intl.dart';
import 'package:promsell_pos_ce/core/domain/money.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const String _rupiah = 'Rp';

  /// Rp 12.500 (tanpa desimal, pemisah ribuan titik)
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: _rupiah,
    decimalDigits: 0,
  );

  /// 12.500 (tanpa simbol)
  static final _groupedInteger = NumberFormat('#,##0', 'id_ID');

  /// 12,5 (satu desimal, untuk ringkasan K/M)
  static final _oneDecimal = NumberFormat('#,##0.0', 'id_ID');

  static String format(double amount) => _formatter.format(amount);

  static String formatNoDecimal(double amount) => _formatter.format(amount);

  /// Angka dengan pemisah ribuan, tanpa simbol dan tanpa desimal.
  /// Contoh: 12500 -> 12.500
  static String formatGrouped(double amount) =>
      _groupedInteger.format(amount.round());

  static String formatGroupedWithSymbol(
    double amount,
    String symbol, {
    String? locale,
  }) {
    final formatted = locale == null
        ? formatGrouped(amount)
        : NumberFormat('#,##0', locale).format(amount.round());
    return '$symbol$formatted';
  }

  /// Angka bulat dengan pemisah ribuan.
  static String formatGroupedInt(int value) => _groupedInteger.format(value);

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '$_rupiah ${_oneDecimal.format(amount / 1000000)}M';
    } else if (amount >= 1000) {
      return '$_rupiah ${_oneDecimal.format(amount / 1000)}K';
    }
    return format(amount);
  }

  static String formatCompactWithSymbol(double amount, String symbol) {
    if (amount >= 1000000) {
      return '$symbol${_oneDecimal.format(amount / 1000000)}M';
    } else if (amount >= 1000) {
      return '$symbol${_oneDecimal.format(amount / 1000)}K';
    }
    return '$symbol${_groupedInteger.format(amount.round())}';
  }

  /// Formats a [Money] value dengan format Rupiah.
  static String formatMoney(Money money) => format(money.value);

  /// Formats a [Money] value tanpa desimal.
  static String formatMoneyNoDecimal(Money money) =>
      formatNoDecimal(money.value);

  /// Formats a [Money] value dalam bentuk ringkas (K/M).
  static String formatMoneyCompact(Money money) => formatCompact(money.value);

  /// Formats a quantity dengan K/M untuk angka besar.
  static String formatQuantityCompact(int qty) {
    if (qty >= 1000000) {
      return '${_oneDecimal.format(qty / 1000000)}M';
    } else if (qty >= 1000) {
      return '${_oneDecimal.format(qty / 1000)}K';
    }
    return qty.toString();
  }
}
