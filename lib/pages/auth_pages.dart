import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.errorMessage});
  final String? errorMessage;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _focusAndShowKeyboard(FocusNode focusNode) {
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && focusNode.hasFocus) {
        unawaited(
          SystemChannels.textInput.invokeMethod<void>('TextInput.show'),
        );
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AuthService.instance.signIn(_email.text, _password.text);
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'We could not sign you in. Check your email and password.');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!_validEmail(email)) {
      setState(() => _error =
          'Enter a valid email address first so we can send the reset link.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AuthService.instance.resetPassword(email);
      if (mounted)
        setState(() => _notice =
            'If that email is registered, password reset instructions have been sent.');
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'Could not send the reset link. Please try again later.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => _AuthBackdrop(
        child: _AuthCard(
          eyebrow: 'WELCOME BACK',
          title: 'Good to see you.',
          subtitle: 'Sign in to continue to your health services.',
          child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.errorMessage != null)
                    _MessageBox(text: widget.errorMessage!, error: true),
                  if (_error != null) _MessageBox(text: _error!, error: true),
                  if (_notice != null)
                    _MessageBox(text: _notice!, error: false),
                  TextFormField(
                      controller: _email,
                      focusNode: _emailFocus,
                      onTap: () => _focusAndShowKeyboard(_emailFocus),
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email
                      ],
                      validator: (v) => _validEmail(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid email address.',
                      decoration: _fieldDecoration(
                          'Email address', Icons.mail_outline)),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _password,
                      focusNode: _passwordFocus,
                      onTap: () => _focusAndShowKeyboard(_passwordFocus),
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password.'
                          : null,
                      decoration: _fieldDecoration(
                              'Password', Icons.lock_outline)
                          .copyWith(
                              suffixIcon: IconButton(
                                  tooltip: _hidePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined)))),
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          onPressed: _busy ? null : _forgotPassword,
                          child: const Text('Forgot password?'))),
                  if (_error != null) const SizedBox(height: 4),
                  SizedBox(
                      height: 52,
                      child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Sign in',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('NEW PATIENT?',
                            style: TextStyle(
                                color: Colors.blueGrey.shade500,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1))),
                    const Expanded(child: Divider())
                  ]),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const RegisterPage())),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Create a patient account'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)))),
                  const SizedBox(height: 14),
                  Text(
                      'Secure sign-in • Role access is managed by your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.blueGrey.shade500, fontSize: 11)),
                ]),
          ),
        ),
      );
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
      _success = false;
    });
    try {
      await AuthService.instance
          .register(_email.text, _password.text, _name.text);
      if (mounted) {
        setState(() {
          _success = true;
          _message =
              'Account created. Check your email for confirmation if enabled, then sign in.';
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _success = false;
          _message =
              'Could not create the account. Check your details and try again.';
        });
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => _AuthBackdrop(
        child: _AuthCard(
          eyebrow: 'PATIENT REGISTRATION',
          title: 'Create your account.',
          subtitle: 'Register to book and keep track of your appointments.',
          child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message != null)
                      _MessageBox(text: _message!, error: !_success),
                    TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) => (v?.trim().isNotEmpty ?? false)
                            ? null
                            : 'Enter your full name.',
                        decoration: _fieldDecoration(
                            'Full name', Icons.person_outline)),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => _validEmail(v?.trim() ?? '')
                            ? null
                            : 'Enter a valid email address.',
                        decoration: _fieldDecoration(
                            'Email address', Icons.mail_outline)),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => (v?.length ?? 0) >= 8
                            ? null
                            : 'Use at least 8 characters.',
                        decoration: _fieldDecoration(
                                'Password', Icons.lock_outline)
                            .copyWith(
                                suffixIcon: IconButton(
                                    tooltip: _hidePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword),
                                    icon: Icon(_hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined)))),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _confirm,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        validator: (v) => v == _password.text
                            ? null
                            : 'Passwords do not match.',
                        decoration: _fieldDecoration(
                            'Confirm password', Icons.verified_user_outlined)),
                    const SizedBox(height: 10),
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color:
                                AppConstants.redPrimary.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.shield_outlined,
                              size: 18, color: AppConstants.redPrimary),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  'All new accounts are PATIENT. Only an admin can assign another role.',
                                  style: TextStyle(fontSize: 12)))
                        ])),
                    const SizedBox(height: 14),
                    SizedBox(
                        height: 50,
                        child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Create account'))),
                    TextButton(
                        onPressed:
                            _busy ? null : () => Navigator.of(context).pop(),
                        child: const Text('Already have an account? Sign in')),
                  ])),
        ),
      );
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppConstants.redGradient),
          child: Stack(children: [
            Positioned(top: -100, right: -80, child: _GlowCircle(size: 280)),
            Positioned(bottom: -130, left: -100, child: _GlowCircle(size: 330)),
            SafeArea(
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 470),
                            child: child)))),
          ]),
        ),
      );
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white.withValues(alpha: .07)));
}

class _AuthCard extends StatelessWidget {
  const _AuthCard(
      {required this.eyebrow,
      required this.title,
      required this.subtitle,
      required this.child});
  final String eyebrow, title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .15),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]),
            child: const Icon(Icons.health_and_safety_rounded,
                size: 48, color: AppConstants.redPrimary)),
        const SizedBox(height: 12),
        const Text('MedAlert',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 28,
                      offset: const Offset(0, 14))
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eyebrow,
                  style: const TextStyle(
                      color: AppConstants.redPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 7),
              Text(title,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D2939))),
              const SizedBox(height: 5),
              Text(subtitle,
                  style:
                      TextStyle(color: Colors.blueGrey.shade600, height: 1.35)),
              const SizedBox(height: 20),
              child,
            ])),
        const SizedBox(height: 16),
        Text('Your health, connected to your community',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: .9), fontSize: 12)),
      ]);
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.text, required this.error});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final color = error ? Colors.red.shade700 : Colors.green.shade800;
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: (error ? Colors.red : Colors.green).withValues(alpha: .08),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline,
              color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(color: color, fontSize: 12)))
        ]));
  }
}

InputDecoration _fieldDecoration(String label, IconData icon) =>
    InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppConstants.redPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red)));

bool _validEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
