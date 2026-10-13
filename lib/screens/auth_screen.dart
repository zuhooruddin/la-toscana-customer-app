import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.register = false});
  final bool register;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  late bool _register = widget.register;
  bool _marketing = false;
  bool _terms = false;
  bool _busy = false;
  bool _showPassword = false;

  @override
  void dispose() {
    for (final c in [_email, _password, _name, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final s = S.of(context);
    if (!_form.currentState!.validate()) return;
    if (_register && !_terms) return showSnack(context, s.t('terms'), error: true);
    setState(() => _busy = true);
    final app = context.read<AppState>();
    try {
      if (_register) {
        await app.register(email: _email.text.trim(), password: _password.text, name: _name.text.trim(), phone: _phone.text.trim(), marketing: _marketing);
      } else {
        await app.login(_email.text.trim(), _password.text);
      }
      if (mounted) context.canPop() ? context.pop() : context.go('/account');
    } catch (e) {
      if (mounted) showSnack(context, apiErrorText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
          const Center(child: BrandLogo(height: 72)),
          const SizedBox(height: 18),
          Text(_register ? s.t('registerTitle') : s.t('loginTitle'), textAlign: TextAlign.center, style: Brand.h1),
          const SizedBox(height: 6),
          Text(s.t('authSubtitle'), textAlign: TextAlign.center, style: const TextStyle(color: Brand.muted, height: 1.45)),
          const SizedBox(height: 24),
          if (_register) ...[
            TextFormField(controller: _name, decoration: InputDecoration(labelText: s.t('name'), prefixIcon: const Icon(Icons.person_outline_rounded)), textCapitalization: TextCapitalization.words, validator: (v) => (v ?? '').trim().isEmpty ? s.t('name') : null),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, decoration: InputDecoration(labelText: s.t('phone'), prefixIcon: const Icon(Icons.phone_rounded)), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch((v ?? '').trim()) ? null : 'Email',
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
            decoration: InputDecoration(
              labelText: s.t('password'),
              helperText: _register ? s.t('passwordHint') : null,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: s.t('password'),
                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (v) {
              final p = v ?? '';
              if (!_register) return p.isEmpty ? s.t('password') : null;
              return p.length >= 10 && RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p) ? null : s.t('passwordHint');
            },
          ),
          if (_register) ...[
            CheckboxListTile(value: _marketing, onChanged: (v) => setState(() => _marketing = v ?? false), title: Text(s.t('marketing')), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
            CheckboxListTile(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), title: Text(s.t('terms')), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
          ],
          const SizedBox(height: 22),
          FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(_register ? s.t('register') : s.t('login'))),
          TextButton(onPressed: () => setState(() => _register = !_register), child: Text(_register ? s.t('haveAccount') : s.t('noAccount'))),
        ]),
      ),
    );
  }
}
