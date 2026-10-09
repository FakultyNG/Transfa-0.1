import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class SupportTicketScreen extends ConsumerStatefulWidget {
  const SupportTicketScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<SupportTicketScreen> createState() =>
      _SupportTicketScreenState();
}

class _SupportTicketScreenState extends ConsumerState<SupportTicketScreen> {
  final _reply = TextEditingController();
  PlatformFile? _attachment;
  bool _loading = false;

  @override
  void dispose() {
    _reply.dispose();
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

  Future<void> _sendReply() async {
    if (_reply.text.trim().isEmpty) return;
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
      await repository.reply(
        id: widget.id,
        message: _reply.text.trim(),
        attachmentUrls: attachmentUrls,
      );
      _reply.clear();
      _attachment = null;
      ref.invalidate(supportTicketProvider(widget.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _close() async {
    try {
      await ref.read(supportRepositoryProvider).close(widget.id);
      ref.invalidate(supportTicketProvider(widget.id));
      ref.invalidate(supportTicketsProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = ref.watch(supportTicketProvider(widget.id));
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Support ticket'),
        actions: [
          IconButton(
            tooltip: 'Close ticket',
            onPressed: _close,
            icon: const Icon(Icons.check_circle_outline_rounded),
          ),
        ],
      ),
      body: ticket.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(userFacingError(error))),
        data: (item) {
          final closed = item.status == 'closed';
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.subject ?? item.id),
                subtitle: Text(item.status.replaceAll('_', ' ')),
              ),
              const Divider(),
              Expanded(
                child: item.messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.',
                          style: AppTypography.bodyMuted,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: item.messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final message = item.messages[index];
                          final isUser = message.sender == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message.message),
                                  if (message.attachmentUrls.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    for (final attachment
                                        in message.attachmentUrls)
                                      TextButton.icon(
                                        onPressed: () => launchUrl(
                                          Uri.parse(attachment),
                                          mode: LaunchMode.externalApplication,
                                        ),
                                        icon: const Icon(
                                          Icons.attachment_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Open attachment'),
                                      ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    AppFormat.dateTime(message.createdAt),
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (!closed) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppInput(
                        label: 'Reply',
                        hint: 'Write a message',
                        controller: _reply,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Attach screenshot',
                      onPressed: _pickAttachment,
                      icon: Icon(
                        _attachment == null
                            ? Icons.attach_file_rounded
                            : Icons.attachment_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Send reply',
                  loading: _loading,
                  onPressed: _reply.text.trim().isEmpty ? null : _sendReply,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
