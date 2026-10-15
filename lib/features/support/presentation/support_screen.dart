import 'package:flutter/material.dart';

import 'support_chat_screen.dart';

/// The customer-facing support entry point is one continuous conversation.
/// Ticket records remain an internal transport detail for the support API.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) => const SupportChatScreen();
}
