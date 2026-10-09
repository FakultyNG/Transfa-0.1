import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _subject = TextEditingController();
  final _message = TextEditingController();
  final _transactionId = TextEditingController();
  PlatformFile? _attachment;
  String _category = 'account';
  bool _loading = false;

  @override
  void dispose() {
    _tabs.dispose();
    _subject.dispose();
    _message.dispose();
    _transactionId.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (file == null || !mounted) return;
    final size = await file.length();
    if (!mounted) return;
    if (size == null || size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachments must be 5 MB or smaller.')),
      );
      return;
    }
    setState(() => _attachment = file);
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final repository = ref.read(supportRepositoryProvider);
      final attachmentUrls = <String>[];
      if (_attachment case final attachment?) {
        final uploaded = await repository.upload(
          bytes: await attachment.readAsBytes(),
          fileName: attachment.name,
        );
        attachmentUrls.add(uploaded.url);
      }
      final ticket = await repository.create(
        subject: _subject.text.trim(),
        message: _message.text.trim(),
        transactionId: _transactionId.text.trim(),
        category: _category,
        attachmentUrls: attachmentUrls,
      );
      ref.invalidate(supportTicketsProvider);
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      _transactionId.clear();
      setState(() => _attachment = null);
      _tabs.animateTo(0);
      context.push('/support/tickets/${ticket.id}');
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
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: const Text('Support'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'My tickets'),
          Tab(text: 'New ticket'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        _TicketList(onCreate: () => _tabs.animateTo(1)),
        ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            AppInput(
              label: 'Subject',
              hint: 'What do you need help with?',
              controller: _subject,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'account', child: Text('Account')),
                DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'kyc', child: Text('KYC')),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Transaction ID',
              hint: 'Optional',
              controller: _transactionId,
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Message',
              hint: 'Describe the issue',
              controller: _message,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(_attachment?.name ?? 'Attach screenshot'),
              trailing: _attachment == null
                  ? null
                  : IconButton(
                      tooltip: 'Remove attachment',
                      onPressed: () => setState(() => _attachment = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
              onTap: _pickAttachment,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Create support ticket',
              loading: _loading,
              onPressed:
                  _subject.text.trim().isNotEmpty &&
                      _message.text.trim().isNotEmpty
                  ? _submit
                  : null,
            ),
          ],
        ),
      ],
    ),
  );
}

class _TicketList extends ConsumerWidget {
  const _TicketList({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(supportTicketsProvider);
        await ref.read(supportTicketsProvider.future);
      },
      child: tickets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 100),
            Text(
              userFacingError(error),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted,
            ),
          ],
        ),
        data: (items) => items.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.support_agent_rounded, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No support tickets yet.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMuted,
                  ),
                  TextButton(
                    onPressed: onCreate,
                    child: const Text('Create one'),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ticket = items[index];
                  return ListTile(
                    tileColor: AppColors.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(ticket.subject ?? ticket.id),
                    subtitle: Text(
                      '${ticket.status.replaceAll('_', ' ')} · ${AppFormat.dateTime(ticket.createdAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/support/tickets/${ticket.id}'),
                  );
                },
              ),
      ),
    );
  }
}
