import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_scaffold.dart';

class BeneficiariesScreen extends ConsumerStatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  ConsumerState<BeneficiariesScreen> createState() =>
      _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends ConsumerState<BeneficiariesScreen> {
  String _type = 'ngn_transfer';

  Future<void> _delete(String id) async {
    try {
      await ref.read(transferRepositoryProvider).deleteBeneficiary(id);
      ref.invalidate(recentBeneficiariesProvider(_type));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final beneficiaries = ref.watch(recentBeneficiariesProvider(_type));
    return AppScaffold(
      appBar: AppBar(title: const Text('Recent recipients')),
      body: Column(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ngn_transfer', label: Text('NGN')),
              ButtonSegment(value: 'usd_transfer', label: Text('USD')),
              ButtonSegment(value: 'cny_transfer', label: Text('CNY')),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: beneficiaries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(userFacingError(error))),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text(
                        'No recent recipients.',
                        style: AppTypography.bodyMuted,
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          tileColor: AppColors.surfaceMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          title: Text(item.displayName),
                          subtitle: Text(
                            '${item.bankName} · ${item.accountNumber}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove recipient',
                            onPressed: () => _delete(item.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
