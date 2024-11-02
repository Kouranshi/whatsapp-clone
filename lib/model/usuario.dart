class Usuario {
  late String idUsuario;
  late String nome;
  late String email;
  late String senha;
  late String? urlImagem;

  Usuario();

  Map <String, dynamic> toMap() {
     return {
      "nome": nome,
      "email": email
     };
  }

  Usuario.fromMap(Map<String, dynamic> map) {
    nome = map["nome"];
    email = map["email"];
  }
}