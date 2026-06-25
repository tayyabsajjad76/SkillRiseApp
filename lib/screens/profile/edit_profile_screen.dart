import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final void Function(String name, String email) onSaved;
  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.onSaved,
  });
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final _nameCtrl  = TextEditingController(text: widget.initialName);
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  final _phoneCtrl = TextEditingController();
  final _bioCtrl   = TextEditingController();

  File?   _pickedImage;       // local preview before upload
  String? _existingPhotoUrl;  // already-saved Cloudinary URL
  bool    _saving = false;

  static const _cloudName    = 'diqwi9l0d';
  static const _uploadPreset = 'skillrisepics';

  static const _bg     = Color(0xFF07080F);
  static const _bg2    = Color(0xFF0D1120);
  static const _border = Color(0x12FFFFFF);
  static const _primary= Color(0xFF1A56FF);
  static const _muted  = Color(0x6BFFFFFF);
  static const _text   = Color(0xFFF0F4FF);

  @override
  void initState() { super.initState(); _loadExtras(); }

  Future<void> _loadExtras() async {
    final p = await SharedPreferences.getInstance();
    // Also try Firestore for photoURL
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String? photoUrl;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      photoUrl = doc.data()?['photoURL'] as String?;
    }
    setState(() {
      _phoneCtrl.text   = p.getString('user_phone') ?? '';
      _bioCtrl.text     = p.getString('user_bio')   ?? '';
      _existingPhotoUrl = photoUrl ?? FirebaseAuth.instance.currentUser?.photoURL;
    });
  }

  // ── Pick image from gallery ──────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  // ── Upload to Cloudinary, return URL ─────
  Future<String?> _uploadToCloudinary(File image) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final res = await req.send();
    if (res.statusCode == 200) {
      final body = await res.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    }
    debugPrint('Cloudinary upload failed: ${res.statusCode}');
    return null;
  }

  // ── Save everything ──────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? photoUrl = _existingPhotoUrl;

      // 1. Upload new image if picked
      if (_pickedImage != null) {
        final uploaded = await _uploadToCloudinary(_pickedImage!);
        if (uploaded != null) {
          photoUrl = uploaded;
          setState(() => _existingPhotoUrl = uploaded);
        } else {
          _showSnack('Image upload failed. Other changes saved.', isError: true);
        }
      }

      // 2. Update FirebaseAuth profile
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameCtrl.text.trim());
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      }

      // 3. Save to Firestore
      if (user != null) {
        final data = <String, dynamic>{
          'name'  : _nameCtrl.text.trim(),
          'email' : _emailCtrl.text.trim(),
          'phone' : _phoneCtrl.text.trim(),
          'bio'   : _bioCtrl.text.trim(),
        };
        if (photoUrl != null) data['photoURL'] = photoUrl;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(data);
      }

      // 4. SharedPreferences (local cache)
      final p = await SharedPreferences.getInstance();
      await p.setString('user_name',  _nameCtrl.text.trim());
      await p.setString('user_email', _emailCtrl.text.trim());
      await p.setString('user_phone', _phoneCtrl.text.trim());
      await p.setString('user_bio',   _bioCtrl.text.trim());

      widget.onSaved(_nameCtrl.text.trim(), _emailCtrl.text.trim());
      _showSnack('Profile saved!');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _primary,
    ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  // ── Avatar widget ────────────────────────
  Widget _buildAvatar() {
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase()
        : '?';

    Widget avatar;
    if (_pickedImage != null) {
      // Immediate local preview
      avatar = CircleAvatar(
        radius: 48,
        backgroundImage: FileImage(_pickedImage!),
      );
    } else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      // Saved Cloudinary URL
      avatar = CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(_existingPhotoUrl!),
        onBackgroundImageError: (_, __) {},
      );
    } else {
      // Fallback initial
      avatar = CircleAvatar(
        radius: 48,
        backgroundColor: _primary.withOpacity(0.2),
        child: Text(initial,
            style: const TextStyle(
                fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(children: [
        avatar,
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration:
            const BoxDecoration(color: _primary, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('EDIT PROFILE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: _primary)),
          const SizedBox(height: 8),
          const Text('Update Your Info',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 24),

          Center(child: _buildAvatar()),
          const SizedBox(height: 28),

          Form(
            key: _formKey,
            child: Column(children: [
              _field('Full Name', _nameCtrl,  Icons.person_outline),
              _field('Email',     _emailCtrl, Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              _field('Phone',     _phoneCtrl, Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              _field('Bio',       _bioCtrl,   Icons.info_outline,
                  maxLines: 3),
            ]),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _saving
                  ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save Changes',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: _text),
          validator: (v) =>
          (v == null || v.isEmpty) ? '$label is required' : null,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _muted),
            prefixIcon: Icon(icon, color: _primary),
            filled: true, fillColor: _bg2,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary)),
          ),
        ),
      );
}