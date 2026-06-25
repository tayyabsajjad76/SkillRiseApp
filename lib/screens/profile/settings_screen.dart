import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});
  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _busy = false;

  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SETTINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _primary)),
          const SizedBox(height: 8),
          const Text('App Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 24),

          _label('Account'),
          _nav('Change Email', Icons.email_outlined, () => _showChangeEmailDialog(context)),
          const SizedBox(height: 16),

          _label('Security'),
          _nav('Change Password', Icons.lock_outline, () => _showChangePasswordDialog(context)),
          const SizedBox(height: 16),

          _label('Storage'),
          _nav('Clear Cache', Icons.cleaning_services_outlined, () => _clearCache(context)),
          const SizedBox(height: 16),

          _label('About'),
          _infoRow('App Version', Icons.info_outline, _appVersion),
          _nav('Terms & Privacy Policy', Icons.description_outlined, () => _showTermsDialog(context)),
          _nav('Rate the App', Icons.star_outline, () => _rateApp(context)),
          const SizedBox(height: 16),

          _label('Danger Zone'),
          _nav('Delete Account', Icons.delete_outline, () => _showDeleteAccountDialog(context), danger: true),
        ]),
      ),
    );
  }

  // ── Change Email ──────────────────────────────
  void _showChangeEmailDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Email', style: TextStyle(color: _text, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: emailCtrl,
            style: const TextStyle(color: _text),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'New Email',
              labelStyle: TextStyle(color: _muted),
              enabledBorder: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: true,
            style: const TextStyle(color: _text),
            decoration: const InputDecoration(
              labelText: 'Current Password',
              labelStyle: TextStyle(color: _muted),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            onPressed: () async {
              final newEmail = emailCtrl.text.trim();
              final pass     = passCtrl.text;
              if (newEmail.isEmpty || !newEmail.contains('@') || pass.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter a valid email and your password.')));
                return;
              }
              Navigator.pop(ctx);
              await _changeEmail(context, newEmail, pass);
            },
            child: const Text('Update Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeEmail(BuildContext context, String newEmail, String currentPassword) async {
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('Not logged in.');

      // Re-authenticate before sensitive update
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);

      // Sends a verification link to the new email; email updates once verified
      await user.verifyBeforeUpdateEmail(newEmail);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Verification link sent to $newEmail. Confirm it to finish.'),
        backgroundColor: _primary,
      ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = e.message ?? 'Failed to update email.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = 'Incorrect password.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Change Password ───────────────────────────
  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(color: _text, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: currentCtrl,
            obscureText: true,
            style: const TextStyle(color: _text),
            decoration: const InputDecoration(
              labelText: 'Current Password',
              labelStyle: TextStyle(color: _muted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newCtrl,
            obscureText: true,
            style: const TextStyle(color: _text),
            decoration: const InputDecoration(
              labelText: 'New Password (min 6 chars)',
              labelStyle: TextStyle(color: _muted),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            onPressed: () async {
              final current = currentCtrl.text;
              final next    = newCtrl.text;
              if (current.isEmpty || next.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter current password and a new password (6+ chars).')));
                return;
              }
              Navigator.pop(ctx);
              await _changePassword(context, current, next);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, String currentPassword, String newPassword) async {
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('Not logged in.');

      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.'), backgroundColor: _primary));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = e.message ?? 'Failed to update password.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = 'Incorrect current password.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Clear Cache ───────────────────────────────
  Future<void> _clearCache(BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared!'), backgroundColor: _primary));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e'), backgroundColor: Colors.red));
    }
  }

  // ── Delete Account ────────────────────────────
  void _showDeleteAccountDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'This will permanently delete your account and all your data (tasks, roadmap, courses, quiz history). This cannot be undone.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passCtrl,
            obscureText: true,
            style: const TextStyle(color: _text),
            decoration: const InputDecoration(
              labelText: 'Enter your password to confirm',
              labelStyle: TextStyle(color: _muted),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final pass = passCtrl.text;
              if (pass.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter your password to confirm.')));
                return;
              }
              Navigator.pop(ctx);
              await _deleteAccount(context, pass);
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, String password) async {
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('Not logged in.');

      // Re-authenticate before destructive action
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);

      final uid = user.uid;
      final db  = FirebaseFirestore.instance;

      // Delete subcollections first
      const subcollections = [
        'tasks', 'roadmap', 'courses', 'quiz_history',
        'completedProjects', 'notifications', 'notificationSettings',
      ];
      for (final sub in subcollections) {
        final snap = await db.collection('users').doc(uid).collection(sub).get();
        for (final d in snap.docs) {
          await d.reference.delete();
        }
      }

      // Delete the main user doc and the auth account
      await db.collection('users').doc(uid).delete();
      await user.delete();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = e.message ?? 'Failed to delete account.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = 'Incorrect password.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Terms & Privacy Policy ────────────────────
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Terms & Privacy Policy', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
              child: SingleChildScrollView(
                child: Text(
                  '''SkillRise Terms of Use & Privacy Policy

1. Account & Data
You are responsible for keeping your login credentials secure. We store your profile, learning progress, tasks, roadmap, and quiz history in Firebase to provide app functionality.

2. Data Usage
Your data (name, email, learning interests, progress) is used solely to personalize your experience within SkillRise. We do not sell your data to third parties.

3. AI Features
Roadmap, task, and course suggestions are generated using AI (Groq) based on the profile information you provide. AI suggestions may not always be fully accurate.

4. Notifications
With your permission, we send push notifications for tasks, quizzes, and reminders. You can manage these in Notification Settings.

5. Account Deletion
You may delete your account at any time from Settings. This permanently removes your profile and all associated learning data.

6. Changes
This is a student project (SkillRise). Terms may be updated as the app evolves.

Last updated: 2026''',
                  style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: _primary)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Rate the App ───────────────────────────────
  Future<void> _rateApp(BuildContext context) async {
    // TODO: replace with your real Play Store package URL once published
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.assignment2';
    final uri = Uri.parse(playStoreUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Play Store.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Play Store: $e'), backgroundColor: Colors.red));
    }
  }

  // ── UI helpers ─────────────────────────────────
  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary, letterSpacing: 0.5)),
  );

  Widget _infoRow(String title, IconData icon, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: _bg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
    child: ListTile(
      leading: Icon(icon, color: _primary, size: 20),
      title: Text(title, style: const TextStyle(color: _text, fontWeight: FontWeight.w500, fontSize: 13)),
      trailing: Text(value, style: const TextStyle(color: _muted, fontSize: 12)),
    ),
  );

  Widget _nav(String title, IconData icon, VoidCallback onTap, {bool danger = false}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: _bg2, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: danger ? Colors.red.withOpacity(0.2) : _border),
    ),
    child: ListTile(
      leading: Icon(icon, color: danger ? Colors.red : _primary, size: 20),
      title: Text(title, style: TextStyle(color: danger ? Colors.red : _text, fontWeight: FontWeight.w500, fontSize: 13)),
      trailing: _busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
          : const Icon(Icons.chevron_right, color: Color(0x6BFFFFFF)),
      onTap: _busy ? null : onTap,
    ),
  );
}