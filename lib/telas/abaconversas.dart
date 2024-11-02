import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/model/conversa.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp/model/usuario.dart';

class AbaConversas extends StatefulWidget {
  const AbaConversas({super.key});

  @override
  State<AbaConversas> createState() => _AbaConversasState();
}

class _AbaConversasState extends State<AbaConversas> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  late String _idUsuarioLogado;
  final _controller = StreamController<QuerySnapshot>.broadcast();
  List<Conversa> listaConversas = [];

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  void initState() {
    _recuperarDadosUsuario();
    Conversa conversa = Conversa();
    conversa.nome = "";
    conversa.mensagem = "";
    conversa.caminhoFoto = "";

    listaConversas.add(conversa);
    super.initState();
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = auth.currentUser;
    setState(() {
      _idUsuarioLogado = usuarioLogado!.uid;
    });
    _adicionarListenerConversas();
  }

  Stream<QuerySnapshot> _adicionarListenerConversas() {
    final stream = db
        .collection("conversas")
        .doc(_idUsuarioLogado)
        .collection("ultima_conversa")
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
    });

    return stream;
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Center(
                child: Text("Nenhuma conexão."),
              );
            case ConnectionState.waiting:
              return Center(
                child: Column(
                  children: [
                    Text("Carregando conversas..."),
                    CircularProgressIndicator()
                  ],
                ),
              );
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text("Erro ao carregar dados.");
              } else {
                QuerySnapshot querySnapshot = snapshot.data!;
                if (querySnapshot.docs.isEmpty) {
                  return Center(
                    child: Text("Você não tem nenhuma mensagem ainda :(",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  );
                }
                return ListView.builder(
                  itemCount: querySnapshot.docs.length,
                  itemBuilder: (context, indice) {
                    List<DocumentSnapshot> conversas = querySnapshot.docs.toList();
                    DocumentSnapshot item = conversas[indice];

                    String? urlImagem = item["caminhoFoto"];
                    String tipo = item["tipoMensagem"];
                    String mensagem = item["mensagem"];
                    String nome = item["nome"];
                    String idDestinatario = item["idDestinatario"];

                    Usuario usuario = Usuario();
                    usuario.nome = nome;
                    usuario.urlImagem = urlImagem;
                    usuario.idUsuario = idDestinatario;

                    return ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, "/mensagens", arguments: usuario);
                      },
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      leading: CircleAvatar(
                        maxRadius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage: urlImagem != null
                              ?NetworkImage(urlImagem)
                              : AssetImage("assets/images/contato.png") as ImageProvider,
                      ),
                      title: Text(
                        nome,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        tipo == "texto"
                        ? mensagem
                        : "Imagem...",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  },
                );
              }
          }
        });
  }
}