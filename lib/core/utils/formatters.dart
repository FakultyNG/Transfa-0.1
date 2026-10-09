import 'package:intl/intl.dart';

class AppFormat {
  AppFormat._();

  static final _ngn = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );
  static final _usd = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );
  static final _cny = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );
  static final _compact = NumberFormat.compactCurrency(
    locale: 'en_NG',
    symbol: '₦',
  );

  static String ngn(num value) => _ngn.format(value);
  static String usd(num value) => _usd.format(value);
  static String cny(num value) => _cny.format(value);
  static String compactNgn(num value) => _compact.format(value);

  static String dateTime(DateTime dt) => DateFormat('d MMM, h:mm a').format(dt);
  static String dateShort(DateTime dt) => DateFormat('d MMM yyyy').format(dt);
}
