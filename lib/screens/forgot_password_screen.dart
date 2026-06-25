import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading  = false;
  bool _sent     = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.resetPassword(_emailCtrl.text.trim());
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1B4B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccessState() : _buildFormState(),
        ),
      ),
    );
  }

  // ── Success State ────────────────────────
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: Colors.green, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          'Check Your Email',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
        ),
        const SizedBox(height: 12),
        Text(
          'Password reset link sent to\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text('Back to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _sendReset,
          child: const Text('Resend Email', style: TextStyle(color: Color(0xFF4F46E5))),
        ),
      ],
    );
  }

  // ── Form State ───────────────────────────
  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20)],
            ),
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text('Forgot Password?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
        ),
        const Center(
          child: Text('Enter your email to receive a reset link',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        const SizedBox(height: 40),

        // Error banner
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: const Text('Email',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B), fontSize: 14)),
        ),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
          decoration: InputDecoration(
            hintText: 'you@example.com',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4F46E5)),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}