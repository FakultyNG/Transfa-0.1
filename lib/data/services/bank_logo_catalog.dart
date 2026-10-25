import 'package:dio/dio.dart';

class BankLogoRecord {
  const BankLogoRecord({
    required this.name,
    this.aliases = const [],
    this.bankCode = '',
    this.scCode = '',
    this.pngUrl = '',
    this.assetPath,
  });

  final String name;
  final List<String> aliases;
  final String bankCode;
  final String scCode;
  final String pngUrl;
  final String? assetPath;

  factory BankLogoRecord.fromJson(Map<String, dynamic> json) {
    final logos = json['logos'] is Map
        ? Map<String, dynamic>.from(json['logos'] as Map)
        : const <String, dynamic>{};
    return BankLogoRecord(
      name: (json['name'] ?? '').toString(),
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((alias) => alias.toString())
          .toList(growable: false),
      bankCode: (json['bankCode'] ?? '').toString(),
      scCode: (json['scCode'] ?? '').toString(),
      pngUrl: (logos['png'] ?? '').toString(),
    );
  }
}

class BankLogoCatalog {
  BankLogoCatalog({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  static const indexUrl =
      'https://cdn.jsdelivr.net/gh/Nigerian-Bank-Logos/ng-bank-logos@main/dist/banks_NGN.json';
  static final BankLogoCatalog instance = BankLogoCatalog();

  final Dio _dio;
  Future<List<BankLogoRecord>>? _records;

  Future<BankLogoRecord?> resolve({
    required String bankName,
    String? bankCode,
  }) async {
    final bundled = find(
      bundledBankLogoRecords,
      bankName: bankName,
      bankCode: bankCode,
    );
    if (bundled != null) return bundled;

    try {
      return find(await _load(), bankName: bankName, bankCode: bankCode);
    } catch (_) {
      // The bank picker must remain usable when the CDN is unavailable.
      return null;
    }
  }

  Future<List<BankLogoRecord>> _load() {
    final cached = _records;
    if (cached != null) return cached;
    final request = _fetch();
    _records = request;
    return request.onError((error, stackTrace) {
      _records = null;
      Error.throwWithStackTrace(
        error ?? StateError('Bank logo catalogue request failed'),
        stackTrace,
      );
    });
  }

  Future<List<BankLogoRecord>> _fetch() async {
    final response = await _dio.get<Object>(indexUrl);
    final root = response.data is Map
        ? Map<String, dynamic>.from(response.data! as Map)
        : const <String, dynamic>{};
    final rows = root['banks'] as List<dynamic>? ?? const [];
    return rows
        .whereType<Map>()
        .map((row) => BankLogoRecord.fromJson(Map<String, dynamic>.from(row)))
        .where((record) => record.pngUrl.isNotEmpty)
        .toList(growable: false);
  }

  static BankLogoRecord? find(
    List<BankLogoRecord> records, {
    required String bankName,
    String? bankCode,
  }) {
    final code = bankCode?.replaceAll(RegExp(r'\s+'), '') ?? '';
    if (code.isNotEmpty) {
      for (final record in records) {
        if (record.bankCode == code || record.scCode == code) return record;
      }
    }

    final target = _canonical(bankName);
    if (target.isEmpty) return null;
    for (final record in records) {
      final names = [record.name, ...record.aliases];
      if (names.any((name) => _canonical(name) == target)) return record;
    }
    for (final record in records) {
      final names = [record.name, ...record.aliases];
      if (names.any((name) {
        final candidate = _canonical(name);
        return candidate.length >= 4 &&
            target.length >= 4 &&
            (candidate.contains(target) || target.contains(candidate));
      })) {
        return record;
      }
    }
    return null;
  }

  static String _canonical(String value) {
    var normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const replacements = {
      'guarantytrustbank': 'gtbank',
      'firstcitymonumentbank': 'fcmb',
      'unitedbankforafrica': 'uba',
      'stanbicibtcbank': 'stanbicibtc',
    };
    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    for (final suffix in const [
      'nigeriaplc',
      'nigeria',
      'plc',
      'limited',
      'ltd',
      'microfinancebank',
      'microfinance',
      'mfb',
      'bank',
    ]) {
      if (normalized.endsWith(suffix) && normalized.length > suffix.length) {
        normalized = normalized.substring(0, normalized.length - suffix.length);
      }
    }
    return normalized;
  }
}

/// Frequently used institutions are bundled so the picker has logos instantly
/// and continues to look correct without a network connection.
const bundledBankLogoRecords = <BankLogoRecord>[
  BankLogoRecord(
    name: 'Access Bank Nigeria',
    aliases: ['Access Bank'],
    bankCode: '000014',
    scCode: '044',
    assetPath: 'assets/images/bank_logos/access-bank.png',
  ),
  BankLogoRecord(
    name: 'Citibank',
    aliases: ['Citibank Nigeria'],
    bankCode: '000009',
    scCode: '023',
    assetPath: 'assets/images/bank_logos/citibank.png',
  ),
  BankLogoRecord(
    name: 'Ecobank',
    aliases: ['Ecobank Nigeria'],
    bankCode: '000010',
    scCode: '050',
    assetPath: 'assets/images/bank_logos/ecobank.png',
  ),
  BankLogoRecord(
    name: 'Fidelity Bank',
    bankCode: '000007',
    scCode: '070',
    assetPath: 'assets/images/bank_logos/fidelity-bank.png',
  ),
  BankLogoRecord(
    name: 'First Bank of Nigeria',
    aliases: ['First Bank', 'FirstBank', 'FBN'],
    bankCode: '000016',
    scCode: '011',
    assetPath: 'assets/images/bank_logos/first-bank.png',
  ),
  BankLogoRecord(
    name: 'First City Monument Bank',
    aliases: ['FCMB'],
    bankCode: '000003',
    scCode: '214',
    assetPath: 'assets/images/bank_logos/fcmb.png',
  ),
  BankLogoRecord(
    name: 'Globus Bank',
    bankCode: '000027',
    scCode: '103',
    assetPath: 'assets/images/bank_logos/globus-bank.png',
  ),
  BankLogoRecord(
    name: 'GTBank Plc',
    aliases: ['GTBank', 'GTB', 'Guaranty Trust Bank'],
    bankCode: '000013',
    scCode: '058',
    assetPath: 'assets/images/bank_logos/gtbank.png',
  ),
  BankLogoRecord(
    name: 'Jaiz Bank',
    bankCode: '000006',
    scCode: '301',
    assetPath: 'assets/images/bank_logos/jaiz-bank.png',
  ),
  BankLogoRecord(
    name: 'Keystone Bank',
    bankCode: '000002',
    scCode: '082',
    assetPath: 'assets/images/bank_logos/keystone-bank.png',
  ),
  BankLogoRecord(
    name: 'Lotus Bank',
    bankCode: '000029',
    scCode: '303',
    assetPath: 'assets/images/bank_logos/lotus-bank.png',
  ),
  BankLogoRecord(
    name: 'NOVA Bank',
    aliases: ['Nova Merchant Bank'],
    bankCode: '060003',
    scCode: '561',
    assetPath: 'assets/images/bank_logos/nova-bank.png',
  ),
  BankLogoRecord(
    name: 'Optimus Bank Limited',
    aliases: ['Optimus Bank'],
    bankCode: '000036',
    scCode: '107',
    assetPath: 'assets/images/bank_logos/optimus-bank.png',
  ),
  BankLogoRecord(
    name: 'Parallex Bank',
    bankCode: '000030',
    scCode: '104',
    assetPath: 'assets/images/bank_logos/parallex-bank.png',
  ),
  BankLogoRecord(
    name: 'Polaris Bank',
    bankCode: '000008',
    scCode: '076',
    assetPath: 'assets/images/bank_logos/polaris-bank.png',
  ),
  BankLogoRecord(
    name: 'PremiumTrust Bank',
    aliases: ['Premium Trust Bank'],
    bankCode: '000031',
    scCode: '105',
    assetPath: 'assets/images/bank_logos/premiumtrust-bank.png',
  ),
  BankLogoRecord(
    name: 'Providus Bank',
    bankCode: '000023',
    scCode: '101',
    assetPath: 'assets/images/bank_logos/providus-bank.png',
  ),
  BankLogoRecord(
    name: 'Stanbic IBTC Bank',
    aliases: ['Stanbic IBTC'],
    bankCode: '000012',
    scCode: '221',
    assetPath: 'assets/images/bank_logos/stanbic-ibtc.png',
  ),
  BankLogoRecord(
    name: 'Standard Chartered Bank',
    aliases: ['Standard Chartered'],
    bankCode: '000021',
    scCode: '068',
    assetPath: 'assets/images/bank_logos/standard-chartered.png',
  ),
  BankLogoRecord(
    name: 'Sterling Bank',
    bankCode: '000001',
    scCode: '232',
    assetPath: 'assets/images/bank_logos/sterling-bank.png',
  ),
  BankLogoRecord(
    name: 'SunTrust Bank',
    aliases: ['SunTrust'],
    bankCode: '000022',
    scCode: '100',
    assetPath: 'assets/images/bank_logos/suntrust-bank.png',
  ),
  BankLogoRecord(
    name: 'TAJ Bank',
    aliases: ['TAJBank'],
    bankCode: '000026',
    scCode: '302',
    assetPath: 'assets/images/bank_logos/taj-bank.png',
  ),
  BankLogoRecord(
    name: 'Titan Trust Bank',
    bankCode: '000025',
    scCode: '102',
    assetPath: 'assets/images/bank_logos/titan-trust-bank.png',
  ),
  BankLogoRecord(
    name: 'Union Bank',
    aliases: ['Union Bank of Nigeria'],
    bankCode: '000018',
    scCode: '032',
    assetPath: 'assets/images/bank_logos/union-bank.png',
  ),
  BankLogoRecord(
    name: 'United Bank for Africa',
    aliases: ['UBA'],
    bankCode: '000004',
    scCode: '033',
    assetPath: 'assets/images/bank_logos/uba.png',
  ),
  BankLogoRecord(
    name: 'Unity Bank',
    bankCode: '000011',
    scCode: '215',
    assetPath: 'assets/images/bank_logos/unity-bank.png',
  ),
  BankLogoRecord(
    name: 'Wema Bank',
    bankCode: '000017',
    scCode: '035',
    assetPath: 'assets/images/bank_logos/wema-bank.png',
  ),
  BankLogoRecord(
    name: 'Zenith Bank Plc',
    aliases: ['Zenith Bank'],
    bankCode: '000015',
    scCode: '057',
    assetPath: 'assets/images/bank_logos/zenith-bank.png',
  ),
  BankLogoRecord(
    name: 'OPay Digital Services Limited',
    aliases: ['OPay', 'Paycom'],
    bankCode: '100004',
    scCode: '999992',
    assetPath: 'assets/images/bank_logos/opay.png',
  ),
  BankLogoRecord(
    name: 'Kuda',
    aliases: ['Kuda Bank', 'Kuda MFB'],
    bankCode: '090267',
    scCode: '50211',
    assetPath: 'assets/images/bank_logos/kuda.png',
  ),
  BankLogoRecord(
    name: 'Moniepoint',
    aliases: ['Moniepoint MFB'],
    bankCode: '090405',
    scCode: '50515',
    assetPath: 'assets/images/bank_logos/moniepoint.png',
  ),
  BankLogoRecord(
    name: 'Palmpay',
    aliases: ['PalmPay'],
    bankCode: '100033',
    scCode: '999991',
    assetPath: 'assets/images/bank_logos/palmpay.png',
  ),
  BankLogoRecord(
    name: 'VFD Microfinance Bank Limited',
    aliases: ['VFD', 'VFD MFB'],
    bankCode: '090110',
    scCode: '566',
    assetPath: 'assets/images/bank_logos/vfd-mfb.png',
  ),
  BankLogoRecord(
    name: 'Rubies MFB',
    aliases: ['Rubies'],
    bankCode: '090175',
    scCode: '125',
    assetPath: 'assets/images/bank_logos/rubies-mfb.png',
  ),
  BankLogoRecord(
    name: 'Carbon',
    aliases: ['Carbon MFB'],
    bankCode: '100026',
    scCode: '565',
    assetPath: 'assets/images/bank_logos/carbon.png',
  ),
  BankLogoRecord(
    name: 'Fairmoney Microfinance Bank',
    aliases: ['FairMoney', 'FairMoney MFB'],
    bankCode: '090551',
    scCode: '51318',
    assetPath: 'assets/images/bank_logos/fairmoney-mfb.png',
  ),
  BankLogoRecord(
    name: 'Sparkle MFB',
    aliases: ['Sparkle'],
    bankCode: '090325',
    scCode: '51310',
    assetPath: 'assets/images/bank_logos/sparkle-mfb.png',
  ),
  BankLogoRecord(
    name: 'Paga',
    bankCode: '100002',
    scCode: '916',
    assetPath: 'assets/images/bank_logos/paga.png',
  ),
  BankLogoRecord(
    name: 'MTN Momo PSB',
    aliases: ['MoMo PSB', 'MTN MoMo'],
    bankCode: '120003',
    assetPath: 'assets/images/bank_logos/mtn-momo-psb.png',
  ),
  BankLogoRecord(
    name: 'Airtel Smartcash PSB',
    aliases: ['SmartCash', 'SmartCash PSB'],
    bankCode: '120004',
    assetPath: 'assets/images/bank_logos/smartcash-psb.png',
  ),
];
