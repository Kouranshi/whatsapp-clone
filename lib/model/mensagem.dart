class Mensagem {

  late String idUsuario;
  late String mensagem;
  late String urlImagem;

  //Define o tipo da mensagem, que pode ser "texto" ou "imagem"
  late String tipo;
  late String data;

  Mensagem();

  Map <String, dynamic> toMap() {
     return {
      "idUsuario": idUsuario,
      "mensagem": mensagem,
      "urlImagem": urlImagem,
      "tipo": tipo,
      "data": data
      };
    }
}