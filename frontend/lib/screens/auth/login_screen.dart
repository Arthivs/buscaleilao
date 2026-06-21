import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _senhaCtrl.text,
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authProvider).error ?? 'Erro ao entrar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).loading;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gavel, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Leilão Inteligente',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        Text('Plataforma de oportunidades',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 40),

                  const Text('Entrar na sua conta',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => v!.isEmpty ? 'Informe o e-mail' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => v!.isEmpty ? 'Informe a senha' : null,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Entrar'),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/registrar'),
                    child: const Text('Não tem conta? Criar conta grátis'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
