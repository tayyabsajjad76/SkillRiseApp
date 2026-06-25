// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// import 'home/home_screen.dart';
// import 'onboarding_screen.dart';
//
// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});
//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }
//
// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey    = GlobalKey<FormState>();
//   final _nameCtrl   = TextEditingController();
//   final _emailCtrl  = TextEditingController();
//   final _passCtrl   = TextEditingController();
//   final _pass2Ctrl  = TextEditingController();
//   bool _obscure1 = true;
//   bool _obscure2 = true;
//   bool _loading  = false;
//
//   @override
//   void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _pass2Ctrl.dispose(); super.dispose(); }
//
//   Future<void> _signup() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _loading = true);
//     await AuthService.signUp(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
//     setState(() => _loading = false);
//     if (!mounted) return;
//     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OnboardingFormScreen()), (_) => false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FF),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Form(
//             key: _formKey,
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               const SizedBox(height: 20),
//               Center(
//                 child: Container(
//                   width: 80, height: 80,
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20)],
//                   ),
//                   child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Center(child: Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)))),
//               const Center(child: Text('Join SkillRise and start learning', style: TextStyle(color: Colors.grey, fontSize: 14))),
//               const SizedBox(height: 32),
//
//               _label('Full Name'),
//               _field(_nameCtrl, 'Name', Icons.person_outline,
//                   validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
//               const SizedBox(height: 16),
//               _label('Email'),
//               _field(_emailCtrl, 'you@example.com', Icons.email_outlined,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null),
//               const SizedBox(height: 16),
//               _label('Password'),
//               _field(_passCtrl, 'Min 6 characters', Icons.lock_outline,
//                   obscure: _obscure1,
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
//                     onPressed: () => setState(() => _obscure1 = !_obscure1),
//                   ),
//                   validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
//               const SizedBox(height: 16),
//               _label('Confirm Password'),
//               _field(_pass2Ctrl, 'Repeat password', Icons.lock_outline,
//                   obscure: _obscure2,
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
//                     onPressed: () => setState(() => _obscure2 = !_obscure2),
//                   ),
//                   validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null),
//               const SizedBox(height: 28),
//
//               SizedBox(
//                 width: double.infinity, height: 54,
//                 child: ElevatedButton(
//                   onPressed: _loading ? null : _signup,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     elevation: 4,
//                   ),
//                   child: _loading
//                       ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                       : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                 const Text('Already have an account? ', style: TextStyle(color: Colors.grey)),
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: const Text('Login', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
//                 ),
//               ]),
//             ]),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _label(String text) => Padding(
//     padding: const EdgeInsets.only(bottom: 8),
//     child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B), fontSize: 14)),
//   );
//
//   Widget _field(TextEditingController ctrl, String hint, IconData icon,
//       {TextInputType? keyboardType, bool obscure = false, Widget? suffixIcon, String? Function(String?)? validator}) {
//     return TextFormField(
//       controller: ctrl,
//       keyboardType: keyboardType,
//       obscureText: obscure,
//       validator: validator,
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: TextStyle(color: Colors.grey[400]),
//         prefixIcon: Icon(icon, color: const Color(0xFF4F46E5)),
//         suffixIcon: suffixIcon,
//         filled: true, fillColor: Colors.white,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
//         enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
//         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
//         errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
//         focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home/home_screen.dart';
import 'onboarding_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _pass2Ctrl  = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading  = false;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _pass2Ctrl.dispose(); super.dispose(); }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await AuthService.signUp(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OnboardingFormScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
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
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFF0F4FF)))),
              const Center(child: Text('Join SkillRise and start learning', style: TextStyle(color: Color(0x6BFFFFFF), fontSize: 14))),
              const SizedBox(height: 32),

              _label('Full Name'),
              _field(_nameCtrl, 'Name', Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
              const SizedBox(height: 16),
              _label('Email'),
              _field(_emailCtrl, 'you@example.com', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null),
              const SizedBox(height: 16),
              _label('Password'),
              _field(_passCtrl, 'Min 6 characters', Icons.lock_outline,
                  obscure: _obscure1,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0x6BFFFFFF)),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
              const SizedBox(height: 16),
              _label('Confirm Password'),
              _field(_pass2Ctrl, 'Repeat password', Icons.lock_outline,
                  obscure: _obscure2,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0x6BFFFFFF)),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ', style: TextStyle(color: Color(0x6BFFFFFF))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Login', style: TextStyle(color: Color(0xFF6EA8FF), fontWeight: FontWeight.bold)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF0F4FF), fontSize: 14)),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, bool obscure = false, Widget? suffixIcon, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Color(0xFFF0F4FF)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x6BFFFFFF)),
        prefixIcon: Icon(icon, color: const Color(0xFF6EA8FF)),
        suffixIcon: suffixIcon,
        filled: true, fillColor: const Color(0xFF0D1120),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x12FFFFFF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x12FFFFFF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1A56FF))),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      ),
    );
  }
}