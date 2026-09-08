import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (message.contains('user already registered')) {
      return 'Já existe uma conta com este e-mail.';
    }
    if (message.contains('password')) {
      return 'A senha não atende aos requisitos de segurança.';
    }
  }
  return 'Não foi possível concluir a operação. Tente novamente.';
}
