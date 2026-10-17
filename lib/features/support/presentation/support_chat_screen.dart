import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/support.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/homeFab.dart';
import 'memo_chat_screen.dart';

/// Original Transfa support chat UI backed by the live support API.
class SupportChatScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const SupportChatScreen({super.key, this.initialMessage});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poller;
  List<SupportMessage> _messages = const [];
  SupportTicket? _activeTicket;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _input.text = widget.initialMessage ?? '';
    _input.addListener(_inputChanged);
    unawaited(_clearSupportUnread());
    _loadConversation();
    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadConversation(silent: true),
    );
  }

  void _inputChanged() => setState(() {});

  Future<void> _clearSupportUnread() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllSupportRead();
      ref.invalidate(unreadSupportCountProvider);
      ref.invalidate(notificationsProvider);
    } catch (_) {
      // Chat remains usable if notification acknowledgement is unavailable.
    }
  }

  Future<void> _loadConversation({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final repository = ref.read(supportRepositoryProvider);
      final tickets = await repository.list();
      final detailed = await Future.wait(
        tickets.map((ticket) => repository.get(ticket.id)),
      );
      final messages = detailed.expand((ticket) => ticket.messages).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final open = detailed.where((ticket) => ticket.status != 'closed');
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _activeTicket = open.isEmpty ? null : open.first;
        _error = null;
        _loading = false;
      });
      _scrollToLatest();
      unawaited(_clearSupportUnread());
    } catch (error) {
      if (!mounted || silent) return;
      setState(() {
        _error = userFacingError(error);
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final repository = ref.read(supportRepositoryProvider);
      final active = _activeTicket;
      if (active == null) {
        await repository.create(
          subject: 'Support conversation',
          message: message,
          category: 'general',
        );
      } else {
        await repository.reply(id: active.id, message: message);
      }
      _input.clear();
      await _loadConversation(silent: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _input.removeListener(_inputChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _input.text.trim().isNotEmpty && !_sending;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            children: [
              const ChatHeaderCard(
                iconAsset: Assets.appIconSupport,
                title: 'Transfa Support',
                subtitle: 'Get the help you need.',
              ),
              const SizedBox(height: 18),
              Expanded(child: _conversation()),
              const SizedBox(height: 8),
              ChatComposeField(controller: _input),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HomeFab(onTap: () => context.go(Routes.dashboard)),
                  ChatSendFab(onTap: canSend ? _send : () {}, active: canSend),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conversation() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(
              onPressed: _loadConversation,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Send us a message whenever you need help.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadConversation,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _messages.length,
        itemBuilder: (_, index) {
          final message = _messages[index];
          return ChatBubble(
            msg: ChatMsg(
              message.sender == 'user' ? ChatAuthor.me : ChatAuthor.agent,
              message.message,
            ),
          );
        },
      ),
    );
  }
}
