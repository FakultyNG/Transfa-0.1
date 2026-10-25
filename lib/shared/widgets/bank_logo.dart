import 'package:flutter/material.dart';

import '../../data/services/bank_logo_catalog.dart';

class BankLogo extends StatelessWidget {
  const BankLogo({
    super.key,
    required this.bankName,
    this.bankCode,
    this.size = 44,
  });

  final String bankName;
  final String? bankCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = BankInitialsLogo(bankName: bankName, size: size);
    return FutureBuilder<BankLogoRecord?>(
      future: BankLogoCatalog.instance.resolve(
        bankName: bankName,
        bankCode: bankCode,
      ),
      builder: (context, snapshot) {
        final record = snapshot.data;
        final assetPath = record?.assetPath;
        if (assetPath != null && assetPath.isNotEmpty) {
          return _LogoFrame(
            size: size,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => fallback,
            ),
          );
        }

        final url = record?.pngUrl;
        if (url == null || url.isEmpty) return fallback;
        return _LogoFrame(
          size: size,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      },
    );
  }
}

class _LogoFrame extends StatelessWidget {
  const _LogoFrame({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Container(
      width: size,
      height: size,
      color: Colors.white,
      padding: EdgeInsets.all(size * 0.08),
      child: child,
    ),
  );
}

class BankInitialsLogo extends StatelessWidget {
  const BankInitialsLogo({super.key, required this.bankName, this.size = 44});

  final String bankName;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: stableBankColor(bankName),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      bankInitials(bankName),
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.3,
      ),
    ),
  );
}

String bankInitials(String bankName) {
  const ignored = {'bank', 'plc', 'limited', 'ltd', 'nigeria', 'microfinance'};
  final words = bankName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && !ignored.contains(word.toLowerCase()))
      .toList();
  if (words.isEmpty) return 'BK';
  if (words.length == 1) {
    return words.first
        .substring(0, words.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
  return '${words.first[0]}${words[1][0]}'.toUpperCase();
}

Color stableBankColor(String bankName) {
  const palette = [
    Color(0xFF075E54),
    Color(0xFFAD1457),
    Color(0xFF0288D1),
    Color(0xFF5E35B1),
    Color(0xFF00695C),
    Color(0xFFC62828),
    Color(0xFF1565C0),
    Color(0xFF6D4C41),
  ];
  var hash = 0;
  for (final unit in bankName.toLowerCase().codeUnits) {
    hash = ((hash * 31) + unit) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}
