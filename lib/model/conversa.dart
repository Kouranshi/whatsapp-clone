import 'package:cloud_firestore/cloud_firestore.dart';

class Conversa {
  late String idRemetente;
  late String idDestinatario;
  late String nome;
  late String mensagem;
  late String caminhoFoto;
  late String tipoMensagem;

  Conversa();

  salvar() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db.collection("conversas")
    .doc(idRemetente)
    .collection("ultima_conversa")
    .doc(idDestinatario)
    .set(toMap());
  }

  Map <String, dynamic> toMap() {
     return {
      "idRemetente": idRemetente,
      "idDestinatario": idDestinatario,
      "nome": nome,
      "mensagem": mensagem,
      "caminhoFoto": caminhoFoto,
      "tipoMensagem": tipoMensagem
     };
  }
}