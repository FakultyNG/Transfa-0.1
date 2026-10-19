import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as device_contacts;
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock_api/currency.dart';
import '../../../data/models/bank.dart';
import '../../../data/repositories/repositories.dart';
import '../../../core/utils/error_messages.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/transfa_logo.dart';

enum _PickerMode { search, recents, contacts }

/// Data the picker needs to carry forward once a recipient is chosen,
/// since selecting a recipient now skips back through PaySheet
/// entirely and opens the next sheet directly.
class RecipientPickerArgs {
  final String amount;
  final AmountCurrency currency;
  final String memo;
  final ValueChanged<String> onMemoChanged;

  const RecipientPickerArgs({
    required this.amount,
    required this.currency,
    required this.memo,
    required this.onMemoChanged,
  });
}

class RecipientPickerResult {
  const RecipientPickerResult({
    required this.name,
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
    this.imageUrl,
  });

  final String name;
  final String accountNumber;
  final String bankName;
  final String bankCode;
  final String? imageUrl;
}

/// "New Transfa" recipient picker. Three modes selected by the bottom
/// segmented control: search results, Recents tab, Contacts tab.
///
/// Picking a recipient here no longer pops a result back to PaySheet.
/// It closes itself *and* the PaySheet bottom sheet underneath it,
/// then opens SingleAccountSheet or MultipleAccountsSheet directly —
/// so the user goes straight from "who" to "confirm the details."
class RecipientPickerScreen extends ConsumerStatefulWidget {
  final RecipientPickerArgs? args;
  const RecipientPickerScreen({super.key, this.args});

  @override
  ConsumerState<RecipientPickerScreen> createState() =>
      _RecipientPickerScreenState();
}

class _RecipientPickerScreenState extends ConsumerState<RecipientPickerScreen> {
  _PickerMode _mode = _PickerMode.recents;
  final _search = TextEditingController();
  String? _selectedContactName;
  List<_Contact> _recents = const [];
  List<_Contact> _contacts = const [];
  bool _loadingRecents = true;
  bool _loadingContacts = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    try {
      final items = await ref
          .read(transferRepositoryProvider)
          .beneficiaries('ngn_transfer');
      if (!mounted) return;
      setState(() {
        _recents = items
            .where(
              (item) =>
                  item.bankCode != null && item.accountNumber.length == 10,
            )
            .map(_Contact.fromBeneficiary)
            .toList();
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _loadingRecents = false);
    }
  }

  Future<void> _loadContacts() async {
    if (_loadingContacts || _contacts.isNotEmpty) return;
    setState(() {
      _loadingContacts = true;
      _error = null;
    });
    try {
      final permission = await device_contacts.FlutterContacts.permissions
          .request(device_contacts.PermissionType.read);
      if (permission != device_contacts.PermissionStatus.granted &&
          permission != device_contacts.PermissionStatus.limited) {
        throw Exception(
          'Contact access is required to find Transfa users on this phone.',
        );
      }
      final deviceItems = await device_contacts.FlutterContacts.getAll(
        properties: {device_contacts.ContactProperty.phone},
      );
      final namesByPhone = <String, String>{};
      for (final contact in deviceItems) {
        for (final phone in contact.phones) {
          final key = _phoneKey(phone.number);
          if (key.isNotEmpty &&
              (contact.displayName?.trim().isNotEmpty ?? false)) {
            namesByPhone[key] = contact.displayName!.trim();
          }
        }
      }
      final matched = namesByPhone.isEmpty
          ? const <TransfaContact>[]
          : await ref
                .read(transferRepositoryProvider)
                .matchContacts(namesByPhone.keys.toList());
      if (!mounted) return;
      setState(() {
        _contacts = matched
            .map(
              (item) => _Contact.fromTransfaContact(
                item,
                deviceName: namesByPhone[_phoneKey(item.phoneNumber)],
              ),
            )
            .toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  String _phoneKey(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      return '234${digits.substring(1)}';
    }
    if (digits.startsWith('2340')) {
      return '234${digits.substring(4)}';
    }
    return digits;
  }

  void _pick(_Contact contact) => context.pop(
    RecipientPickerResult(
      name: contact.name,
      accountNumber: contact.accountNumber,
      bankName: contact.bankName,
      bankCode: contact.bankCode,
      imageUrl: contact.imageUrl,
    ),
  );

  void _selectContact(String name) {
    setState(() {
      _selectedContactName = _selectedContactName == name ? null : name;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _mode == _PickerMode.search
        ? 'Find a contact or account.'
        : 'Who do you want to pay?';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                _HeaderCard(subtitle: subtitle),
                const SizedBox(height: 48),
                if (_mode == _PickerMode.search) ..._searchView(),
                if (_mode == _PickerMode.recents)
                  ..._sectionView(
                    icon: const _RecentsCircle(),
                    label: 'Recents',
                    items: _recents.take(5).toList(),
                    extraItems: _recents.length > 5
                        ? _recents.skip(5).toList()
                        : null,
                    loading: _loadingRecents,
                  ),
                if (_mode == _PickerMode.contacts)
                  ..._sectionView(
                    icon: const _ContactsCircle(),
                    label: 'Contacts',
                    items: _contacts.take(5).toList(),
                    extraItems: _contacts.length > 5
                        ? _contacts.skip(5).toList()
                        : null,
                    loading: _loadingContacts,
                  ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: _BottomBar(
                mode: _mode,
                search: _search,
                onModeChanged: (m) {
                  setState(() => _mode = m);
                  if (m == _PickerMode.contacts || m == _PickerMode.search) {
                    _loadContacts();
                  }
                },
                onClose: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sectionView({
    required Widget icon,
    required String label,
    required List<_Contact> items,
    List<_Contact>? extraItems,
    bool loading = false,
  }) {
    return [
      Row(
        children: [
          icon,
          const SizedBox(width: 14),
          Text(
            label,
            style: AppTypography.displayMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (loading) const Center(child: CircularProgressIndicator()),
      if (!loading && _error != null)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      if (!loading && _error == null && items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('No Transfa recipients found yet.'),
        ),
      if (items.isNotEmpty)
        _ListCard(
          children: items
              .map(
                (c) => _ContactRow(
                  contact: c,
                  isSelected: _selectedContactName == c.name,
                  onTap: () {
                    _selectContact(c.name);
                    _pick(c);
                  },
                ),
              )
              .toList(),
        ),
      if (extraItems != null) ...[
        const SizedBox(height: 18),
        _ListCard(
          children: extraItems
              .map(
                (c) => _ContactRow(
                  contact: c,
                  isSelected: _selectedContactName == c.name,
                  onTap: () {
                    _selectContact(c.name);
                    _pick(c);
                  },
                ),
              )
              .toList(),
        ),
      ],
    ];
  }

  List<Widget> _searchView() {
    final query = _search.text.trim().toLowerCase();
    final all = <_Contact>[..._contacts, ..._recents];
    final seen = <String>{};
    final matches = all.where((item) {
      final unique = '${item.accountNumber}:${item.bankCode}';
      return seen.add(unique) &&
          (query.isEmpty ||
              '${item.name} ${item.accountNumber} ${item.bankName}'
                  .toLowerCase()
                  .contains(query));
    }).toList();
    final top = matches.take(1).toList();
    final others = matches.skip(1).toList();
    return [
      Text(
        'Top Result',
        style: AppTypography.displayMedium.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      const SizedBox(height: 12),
      if (top.isNotEmpty)
        _ListCard(
          children: top
              .map(
                (c) => _ContactRow(
                  contact: c,
                  isSelected: _selectedContactName == c.name,
                  onTap: () {
                    _selectContact(c.name);
                    _pick(c);
                  },
                ),
              )
              .toList(),
        ),
      if (top.isNotEmpty) const SizedBox(height: 28),
      Text(
        'Others',
        style: AppTypography.displayMedium.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      const SizedBox(height: 12),
      if (others.isNotEmpty)
        _ListCard(
          children: others
              .map(
                (c) => _ContactRow(
                  contact: c,
                  isSelected: _selectedContactName == c.name,
                  onTap: () {
                    _selectContact(c.name);
                    _pick(c);
                  },
                ),
              )
              .toList(),
        ),
    ];
  }
}

class _Contact {
  final String name;
  final String? imageUrl;
  final String accountNumber;
  final String bankName;
  final String bankCode;
  final String? subtitle;
  const _Contact({
    required this.name,
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
    this.imageUrl,
    this.subtitle,
  });

  factory _Contact.fromBeneficiary(Beneficiary item) => _Contact(
    name: item.displayName,
    accountNumber: item.accountNumber,
    bankName: item.bankName,
    bankCode: item.bankCode!,
    subtitle: _relativeTime(item.lastUsedAt),
  );

  factory _Contact.fromTransfaContact(
    TransfaContact item, {
    String? deviceName,
  }) => _Contact(
    name: (deviceName?.trim().isNotEmpty ?? false)
        ? deviceName!.trim()
        : item.displayName,
    imageUrl: item.profileImageUrl,
    accountNumber: item.accountNumber,
    bankName: item.bankName,
    bankCode: item.bankCode,
  );

  static String _relativeTime(DateTime? value) {
    if (value == null) {
      return 'Recently';
    }
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes.clamp(1, 59)} minutes ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return '${(difference.inDays / 7).floor()} weeks ago';
  }
}

class _HeaderCard extends StatelessWidget {
  final String subtitle;
  const _HeaderCard({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      radius: 28,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const TransfaMark(size: 30, white: true),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Transfa',
                  style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final List<Widget> children;
  const _ListCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: children),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final _Contact contact;
  final bool isSelected;
  final VoidCallback onTap;
  const _ContactRow({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = _avatar();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.black.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            SizedBox(width: 52, height: 52, child: avatar),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: AppTypography.subheading.copyWith(fontSize: 17),
                  ),
                  if (contact.subtitle != null)
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contact.subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    if (contact.imageUrl != null && contact.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          contact.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(),
        ),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
      decoration: BoxDecoration(
        color: _avatarColor(contact.name),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFFFF375F),
      Color(0xFF34C759),
      Color(0xFF6238FB),
      Color(0xFFC9826B),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

class _RecentsCircle extends StatelessWidget {
  const _RecentsCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SvgPicture.asset(Assets.recents, fit: BoxFit.cover),
      ),
    );
  }
}

class _ContactsCircle extends StatelessWidget {
  const _ContactsCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      child: SvgPicture.asset(Assets.contactHeader, width: 56, height: 56),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final _PickerMode mode;
  final TextEditingController search;
  final ValueChanged<_PickerMode> onModeChanged;
  final VoidCallback onClose;

  const _BottomBar({
    required this.mode,
    required this.search,
    required this.onModeChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == _PickerMode.search) {
      return Row(
        children: [
          _RoundIcon(
            child: SvgPicture.asset(Assets.contactsDark, width: 35, height: 35),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SearchPill(
              controller: search,
              onClear: () => search.clear(),
            ),
          ),
          const SizedBox(width: 8),
          _RoundIcon(
            onTap: onClose,
            child: const Icon(
              Icons.close_rounded,
              color: Colors.black,
              size: 22,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        _RoundIcon(
          onTap: () => onModeChanged(_PickerMode.search),
          child: const Icon(
            Icons.search_rounded,
            color: Colors.black,
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    icon: Icons.access_time_filled_rounded,
                    label: 'Recents',
                    active: mode == _PickerMode.recents,
                    activeColor: const Color(0xFFFF9F0A),
                    onTap: () => onModeChanged(_PickerMode.recents),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    icon: Icons.person_rounded,
                    label: 'Contacts',
                    active: mode == _PickerMode.contacts,
                    activeColor: const Color(0xFFFF375F),
                    onTap: () => onModeChanged(_PickerMode.contacts),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _RoundIcon(
          onTap: onClose,
          child: const Icon(Icons.close_rounded, color: Colors.black, size: 22),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _TabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  const _SearchPill({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.search_rounded, color: Colors.black54, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                hintText: '',
                border: InputBorder.none,
                isDense: true,
              ),
              style: AppTypography.subheading.copyWith(fontSize: 20),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black,
              child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _RoundIcon({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
