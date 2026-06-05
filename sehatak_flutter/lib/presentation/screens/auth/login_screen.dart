import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/core/services/biometric_service.dart';
import 'package:sehatak/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:sehatak/presentation/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  bool _obscure = true, _obscure2 = true, _agree = false;
  final BiometricService _bio = BiometricService();
  bool _hasBiometric = false;
  String _bioName = 'البصمة';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final a = await _bio.isAvailable();
    if (a) { final t = await _bio.getAvailableTypes(); setState(() { _hasBiometric = true; _bioName = _bio.getBiometricName(t); }); }
  }

  void _guest() => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
  void _login() {
    if (_email.text.isEmpty || _pass.text.isEmpty) { _showMsg('املأ الحقول', true); return; }
    context.read<AuthBloc>().add(LoginWithEmail(email: _email.text.trim(), password: _pass.text.trim()));
  }
  void _register() {
    if (!_agree) { _showMsg('وافق على الشروط', true); return; }
    if (_regPass.text != _regConfirm.text) { _showMsg('كلمتا المرور غير متطابقتين', true); return; }
    if (_regPass.text.length < 6) { _showMsg('6 أحرف', true); return; }
    context.read<AuthBloc>().add(RegisterWithEmail(name: _name.text.trim(), email: _regEmail.text.trim(), phone: _regPhone.text.trim(), password: _regPass.text.trim()));
  }

  @override
  void dispose() {
    _tabCtrl.dispose(); _email.dispose(); _pass.dispose(); _name.dispose();
    _regEmail.dispose(); _regPhone.dispose(); _regPass.dispose(); _regConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, s) {
        if (s is Authenticated) {
          Navigator.of(ctx).pushAndRemoveUntil(
            PageRouteBuilder(pageBuilder: (_, __, ___) => const HomeScreen(), transitionsBuilder: (_, a, __, ch) => FadeTransition(opacity: a, child: ch), transitionDuration: const Duration(milliseconds: 400)),
            (r) => false,
          );
        }
        if (s is AuthError) _showMsg(s.message, true);
      },
      builder: (ctx, s) => Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: d ? [const Color(0xFF0B1121), const Color(0xFF1A2540)] : AppColors.primaryGradient)),
          child: SafeArea(child: Stack(children: [
            Positioned(top: -80, right: -60, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
            Positioned(top: 100, left: -40, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
            Center(
              child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
                const SizedBox(height: 20),
                Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.health_and_safety, size: 38, color: AppColors.primary)),
                const SizedBox(height: 8),
                const Text('صحتك', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                const Text('منصة الرعاية الصحية', style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Cairo')),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(color: d ? const Color(0xFF1A2540) : Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    Container(margin: const EdgeInsets.all(14), decoration: BoxDecoration(color: d ? const Color(0xFF0B1121) : Colors.grey[100], borderRadius: BorderRadius.circular(14)), child: TabBar(controller: _tabCtrl, indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)), labelColor: Colors.white, unselectedLabelColor: Colors.grey, padding: const EdgeInsets.all(4), tabs: const [Tab(text: 'تسجيل الدخول'), Tab(text: 'إنشاء حساب')])),
                    SizedBox(height: _tabCtrl.index == 0 ? 240 : 420, child: TabBarView(controller: _tabCtrl, children: [
                      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                        TextField(controller: _email, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: const Icon(Icons.email_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                        const SizedBox(height: 10),
                        TextField(controller: _pass, obscureText: _obscure, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: s is AuthLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: s is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل الدخول', style: TextStyle(fontSize: 15)))),
                      ])),
                      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                        TextField(controller: _name, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'الاسم الكامل', prefixIcon: const Icon(Icons.person_outline, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                        const SizedBox(height: 8), TextField(controller: _regEmail, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: const Icon(Icons.email_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                        const SizedBox(height: 8), TextField(controller: _regPhone, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'رقم الهاتف', prefixIcon: const Icon(Icons.phone_android, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                        const SizedBox(height: 8), TextField(controller: _regPass, obscureText: _obscure, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                        const SizedBox(height: 8), TextField(controller: _regConfirm, obscureText: _obscure2, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: const Icon(Icons.lock_outline, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                        const SizedBox(height: 6), Row(children: [Checkbox(value: _agree, activeColor: AppColors.primary, onChanged: (v) => setState(() => _agree = v!), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap), const Text('أوافق على الشروط', style: TextStyle(fontSize: 10))]),
                        const SizedBox(height: 6),
                        SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: s is AuthLoading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: s is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إنشاء حساب', style: TextStyle(fontSize: 15)))),
                      ])),
                    ])),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: SizedBox(height: 46, child: OutlinedButton(onPressed: () => context.read<AuthBloc>().add(LoginWithGoogle()), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), backgroundColor: Colors.white.withOpacity(0.15)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.g_mobiledata, color: Colors.white, size: 20), SizedBox(width: 4), Text("Google", style: TextStyle(fontSize: 13, color: Colors.white))])))),
                  const SizedBox(width: 10),
                  Expanded(child: SizedBox(height: 46, child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), backgroundColor: Colors.white.withOpacity(0.15)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.apple, color: Colors.white, size: 20), SizedBox(width: 4), Text("Apple", style: TextStyle(fontSize: 13, color: Colors.white))])))),
                ]),
                if (_hasBiometric) ...[
                  const SizedBox(height: 10),
                  GestureDetector(onTap: () async { if (await _bio.authenticate(reason: 'الدخول بـ $_bioName')) _guest(); }, child: Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), child: Icon(Icons.fingerprint, color: Colors.white, size: 26))),
                  const SizedBox(height: 4),
                  Text('$_bioName', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
                const SizedBox(height: 8),
                TextButton(onPressed: _guest, child: const Text('تصفح كضيف', style: TextStyle(color: Colors.white60, fontSize: 13, fontFamily: 'Cairo'))),
              ])),
            ),
          ])),
        ),
      ),
    );
  }

  void _showMsg(String m, bool e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: e ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)));
}
