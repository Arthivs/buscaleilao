import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).registrar(
          _nomeCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _senhaCtrl.text,
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authProvider).error ?? 'Erro ao criar conta')),
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
                  const Text('Criar conta grátis',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Comece a identificar oportunidades hoje',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outlined)),
                    validator: (v) => v!.isEmpty ? 'Informe seu nome' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
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
                    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Criar minha conta'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Já tenho conta — Entrar'),
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
