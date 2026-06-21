class Usuario {
  final int id;
  final String nome;
  final String email;
  final String role;
  final String plano;
  final bool ativo;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    required this.plano,
    required this.ativo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'],
        nome: json['nome'],
        email: json['email'],
        role: json['role'],
        plano: json['plano'],
        ativo: json['ativo'],
      );

  bool get isAdmin => role == 'admin';
}
