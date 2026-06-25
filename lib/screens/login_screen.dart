// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// import 'home/home_screen.dart';
// import 'signup_screen.dart';
// import 'forgot_password_screen.dart'; // ✅ NEW import
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey   = GlobalKey<FormState>();
//   final _emailCtrl = TextEditingController();
//   final _passCtrl  = TextEditingController();
//   bool _obscure  = true;
//   bool _loading  = false;
//   String? _error;
//
//   @override
//   void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }
//
//   Future<void> _login() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() { _loading = true; _error = null; });
//     final err = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
//     setState(() => _loading = false);
//     if (err != null) {
//       setState(() => _error = err);
//     } else {
//       if (!mounted) return;
//       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
//     }
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
//               const SizedBox(height: 40),
//               // Logo / header
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
//               const SizedBox(height: 24),
//               const Center(child: Text('Welcome Back!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)))),
//               const Center(child: Text('Login to your SkillRise account', style: TextStyle(color: Colors.grey, fontSize: 14))),
//               const SizedBox(height: 40),
//
//               // Error banner
//               if (_error != null) ...[
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
//                   child: Row(children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 18),
//                     const SizedBox(width: 8),
//                     Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
//                   ]),
//                 ),
//                 const SizedBox(height: 16),
//               ],
//
//               _label('Email'),
//               _field(_emailCtrl, 'you@example.com', Icons.email_outlined,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null),
//               const SizedBox(height: 16),
//               _label('Password'),
//               _field(_passCtrl, 'Your password', Icons.lock_outline,
//                   obscure: _obscure,
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
//                     onPressed: () => setState(() => _obscure = !_obscure),
//                   ),
//                   validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
//
//               // ✅ NEW: Forgot password link
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
//                   ),
//                   child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 13)),
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//               SizedBox(
//                 width: double.infinity, height: 54,
//                 child: ElevatedButton(
//                   onPressed: _loading ? null : _login,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     elevation: 4,
//                   ),
//                   child: _loading
//                       ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                       : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                 const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
//                 GestureDetector(
//                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
//                   child: const Text('Sign Up', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
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
import 'signup_screen.dart';
import 'forgot_password_screen.dart'; // ✅ NEW import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
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
              const SizedBox(height: 40),
              // Logo / header
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
              const SizedBox(height: 24),
              const Center(child: Text('Welcome Back!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFF0F4FF)))),
              const Center(child: Text('Login to your SkillRise account', style: TextStyle(color: Color(0x6BFFFFFF), fontSize: 14))),
              const SizedBox(height: 40),

              // Error banner
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              _label('Email'),
              _field(_emailCtrl, 'you@example.com', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null),
              const SizedBox(height: 16),
              _label('Password'),
              _field(_passCtrl, 'Your password', Icons.lock_outline,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0x6BFFFFFF)),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),

              // ✅ NEW: Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF6EA8FF), fontSize: 13)),
                ),
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? ", style: TextStyle(color: Color(0x6BFFFFFF))),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text('Sign Up', style: TextStyle(color: Color(0xFF6EA8FF), fontWeight: FontWeight.bold)),
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