import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/data/services/bank_logo_catalog.dart';
import 'package:transfa/shared/widgets/bank_logo.dart';

void main() {
  const records = [
    BankLogoRecord(
      name: 'Access Bank Nigeria',
      aliases: ['Access Bank Nigeria'],
      bankCode: '000014',
      scCode: '044',
      pngUrl: 'https://example.com/access.png',
    ),
    BankLogoRecord(
      name: 'Guaranty Trust Bank',
      aliases: ['GTBank'],
      bankCode: '000013',
      scCode: '058',
      pngUrl: 'https://example.com/gtbank.png',
    ),
  ];

  test('matches a logo by provider or sort code', () {
    expect(
      BankLogoCatalog.find(
        records,
        bankName: 'Different provider label',
        bankCode: '044',
      )?.name,
      'Access Bank Nigeria',
    );
  });

  test('matches a logo by normalized name and alias', () {
    expect(
      BankLogoCatalog.find(records, bankName: 'GT Bank')?.name,
      'Guaranty Trust Bank',
    );
  });

  test('bundles 40 common Nigerian institutions for offline use', () {
    expect(bundledBankLogoRecords, hasLength(40));
    expect(
      bundledBankLogoRecords.map((record) => record.assetPath).toSet(),
      hasLength(40),
    );
    expect(
      BankLogoCatalog.find(
        bundledBankLogoRecords,
        bankName: 'OPay',
        bankCode: '100004',
      )?.assetPath,
      'assets/images/bank_logos/opay.png',
    );
    expect(
      BankLogoCatalog.find(
        bundledBankLogoRecords,
        bankName: 'United Bank for Africa',
      )?.assetPath,
      'assets/images/bank_logos/uba.png',
    );
  });

  test('fallback initials and color are stable', () {
    expect(bankInitials('First City Monument Bank'), 'FC');
    expect(stableBankColor('Unknown Bank'), stableBankColor('Unknown Bank'));
    expect(
      stableBankColor('Unknown Bank'),
      isNot(stableBankColor('Another Bank')),
    );
  });
}
