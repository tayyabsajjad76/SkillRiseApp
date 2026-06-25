import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'overview_screen.dart';
import 'edit_profile_screen.dart';
import 'progress_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;
  const ProfileScreen({super.key, this.onLogout});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int    _selectedIndex = 0;
  String _name          = 'Guest';
  String _email         = '';
  bool   _loggedIn      = false;

  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  static const _navItems = [
    _NavItem(label: 'Overview',        icon: Icons.person_rounded),
    _NavItem(label: 'Edit Profile',    icon: Icons.edit_outlined),
    _NavItem(label: 'Progress Report', icon: Icons.bar_chart_rounded),
    _NavItem(label: 'Notifications',   icon: Icons.notifications_outlined),
    _NavItem(label: 'Settings',        icon: Icons.settings_outlined),
    _NavItem(label: 'Help & Support',  icon: Icons.help_outline_rounded),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = AuthService.getUid();
    if (uid == null) { setState(() => _loggedIn = false); return; }

    final doc  = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};

    setState(() {
      _loggedIn = true;
      _name     = data['name']?.toString() ?? 'Guest';
      _email    = data['email']?.toString() ?? '';
    });

    // ADD THIS ↓
    if (mounted) await NotificationService.init(context);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); widget.onLogout?.call(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return const OverviewScreen();
      case 1: return EditProfileScreen(
        initialName: _name, initialEmail: _email,
        onSaved: (n, e) => setState(() { _name = n; _email = e; }),
      );
      case 2: return const ProgressScreen();
      case 3: return const ProfileNotificationsScreen();
      case 4: return const ProfileSettingsScreen();
      case 5: return const HelpScreen();
      default: return const OverviewScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = AuthService.getInitial(_name);
    return Column(children: [
      Container(
        color: _bg2,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: _primary.withOpacity(0.25),
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_name.split(' ').first, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                if (_email.isNotEmpty) Text(_email, style: const TextStyle(color: _muted, fontSize: 10), overflow: TextOverflow.ellipsis),
              ])),
              if (_loggedIn)
                GestureDetector(
                  onTap: _showLogoutDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final sel = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _primary.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? _primary : _border),
                    ),
                    child: Row(children: [
                      Icon(_navItems[i].icon, size: 15, color: sel ? _primary : _muted),
                      const SizedBox(width: 6),
                      Text(_navItems[i].label, style: TextStyle(color: sel ? _text : _muted, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                    ]),
                  ),
                );
              }),
            ),
          ),
          Container(height: 1, color: _border),
        ]),
      ),
      Expanded(child: _buildContent()),
    ]);
  }
}

class _NavItem {
  final String label; final IconData icon;
  const _NavItem({required this.label, required this.icon});
}