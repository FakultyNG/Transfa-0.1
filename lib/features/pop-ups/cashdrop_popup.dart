import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/error_messages.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/repositories.dart';
import '../transfers/presentation/transfer_state.dart';

class CashDropScreen extends ConsumerStatefulWidget {
  const CashDropScreen({super.key});

  @override
  ConsumerState<CashDropScreen> createState() => _CashDropScreenState();
}

class _CashDropScreenState extends ConsumerState<CashDropScreen> {
  bool _loading = false;

  Future<void> _setEnabled(bool enabled) async {
    final config = await ref.read(cashDropConfigProvider.future);
    if (!config.featureEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CashDrop is not available yet.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repository = ref.read(deviceFeaturesRepositoryProvider);
      if (enabled) {
        await repository.registerCashDrop();
      } else {
        await repository.disableCashDrop();
      }
      ref.invalidate(cashDropStatusProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan() async {
    final config = await ref.read(cashDropConfigProvider.future);
    if (!config.featureEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CashDrop is not available yet.')),
      );
      return;
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await image.readAsBytes();
      final match = await ref
          .read(deviceFeaturesRepositoryProvider)
          .resolveCashDrop('data:image/jpeg;base64,${base64Encode(bytes)}');
      final suggestions = await ref
          .read(transferRepositoryProvider)
          .suggestBanks(match.accountNumber);
      final selected = suggestions.where(
        (item) => item.bankName.toLowerCase() == match.bankName.toLowerCase(),
      );
      final bank = selected.isNotEmpty
          ? selected.first
          : suggestions.isNotEmpty
          ? suggestions.first
          : null;
      if (bank == null) {
        throw StateError('The matched bank could not be resolved safely.');
      }
      ref.read(transferDraftProvider.notifier).state = TransferDraft(
        currency: TxCurrency.ngn,
        recipientName: match.displayName,
        recipientAccount: match.accountNumber,
        bankName: bank.bankName,
        bankCode: bank.bankCode,
      );
      if (!mounted) return;
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.push(Routes.transfer);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(cashDropStatusProvider);
    final config = ref.watch(cashDropConfigProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CashDrop'),
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: config.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(userFacingError(error))),
            data: (feature) {
              if (!feature.featureEnabled) {
                return const _CashDropDisabledView();
              }
              return status.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text(userFacingError(error))),
                data: (item) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.face_retouching_natural_rounded, size: 72),
                    const SizedBox(height: 18),
                    Text(
                      item.enabled ? 'CashDrop is active' : 'Enable CashDrop',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.enabled
                          ? 'Your verified profile image can receive CashDrop payments.'
                          : 'Link your verified profile image and funding account to receive payments.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMuted,
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _loading ? null : _scan,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Scan profile to pay'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _setEnabled(!item.enabled),
                      icon: Icon(
                        item.enabled
                            ? Icons.link_off_rounded
                            : Icons.link_rounded,
                      ),
                      label: Text(
                        item.enabled ? 'Disable CashDrop' : 'Enable receiving',
                      ),
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                    ],
                    const Spacer(),
                    Text(
                      'CashDrop matches verified profile images. It does not scan QR codes.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CashDropDisabledView extends StatelessWidget {
  const _CashDropDisabledView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.face_retouching_off_rounded, size: 72),
        const SizedBox(height: 18),
        Text(
          'CashDrop is unavailable',
          textAlign: TextAlign.center,
          style: AppTypography.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'This feature is turned off while Transfa completes face verification support.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Scan profile to pay'),
        ),
        const Spacer(),
        Text(
          'No camera permission is requested while CashDrop is disabled.',
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
      ],
    );
  }
}
