import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whatsapp/model/conversa.dart';
import 'package:whatsapp/model/mensagem.dart';
import 'package:whatsapp/model/usuario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Mensagens extends StatefulWidget {
  final Usuario contato;
  const Mensagens(this.contato, {super.key});

  @override
  State<Mensagens> createState() => _MensagensState();
}

class _MensagensState extends State<Mensagens> {
  var _subindoImagem = false;
  double _progress = 0.0;
  final ImagePicker _picker = ImagePicker();
  late File _imagem;
  FirebaseFirestore db = FirebaseFirestore.instance;
  late String _idUsuarioLogado;
  late String _idUsuarioDestinatario;
  final _controllerMensagem = TextEditingController();
  final _controller = StreamController<QuerySnapshot>.broadcast();
  final ScrollController _scrollController = ScrollController();

  _enviarMensagem() {
    String textoMensagem = _controllerMensagem.text;
    if (textoMensagem.isNotEmpty) {
      Mensagem mensagem = Mensagem();
      mensagem.idUsuario = _idUsuarioLogado;
      mensagem.mensagem = textoMensagem;
      mensagem.urlImagem = "";
      mensagem.data = Timestamp.now().toString();
      mensagem.tipo = "texto";

      //salvar mensagem para remetente
      _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, mensagem);

      //salvar mensagem para o destinatário
      _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, mensagem);

      //salvar conversa
      _salvarConversa(mensagem);
    }
  }

  _salvarConversa(Mensagem msg) {
    //salvar conversa remetente
    Conversa cRemetente = Conversa();
    cRemetente.idRemetente = _idUsuarioLogado;
    cRemetente.idDestinatario = _idUsuarioDestinatario;
    cRemetente.mensagem = msg.mensagem;
    cRemetente.nome = widget.contato.nome;
    cRemetente.caminhoFoto = widget.contato.urlImagem!;
    cRemetente.tipoMensagem = msg.tipo;
    cRemetente.salvar();

    //salvar conversa destinatario
    Conversa cDestinatario = Conversa();
    cDestinatario.idRemetente = _idUsuarioDestinatario;
    cDestinatario.idDestinatario = _idUsuarioLogado;
    cDestinatario.mensagem = msg.mensagem;
    cDestinatario.nome = widget.contato.nome;
    cDestinatario.caminhoFoto = widget.contato.urlImagem!;
    cDestinatario.tipoMensagem = msg.tipo;
    cDestinatario.salvar();
  }

  _salvarMensagem(String idRemente, String idDestinatario, Mensagem msg) async {
    await db
        .collection("mensagens")
        .doc(idRemente)
        .collection(idDestinatario)
        .add(msg.toMap());

    _controllerMensagem.clear();
  }

  _enviarFoto() async {
    // Limpa o estado de upload antes de iniciar
  setState(() {
    _subindoImagem = false;
  });

  // Seleciona a imagem
  final XFile? imagemSelecionada = await _picker.pickImage(source: ImageSource.gallery);

  // Verifica se a imagem foi selecionada
  if (imagemSelecionada == null) {
    setState(() {
      _subindoImagem = false; // Garante que o indicador de progresso não apareça
    });
    return; // Retorna para encerrar o método se não houver imagem
  }

  // Atualiza o estado para indicar que a imagem está sendo enviada
  setState(() {
    _subindoImagem = true;
  });

  // Define o nome e a referência do arquivo no Firebase Storage
  final String nomeImagem = DateTime.now().microsecondsSinceEpoch.toString();
  final Reference arquivo = FirebaseStorage.instance
      .ref()
      .child("mensagens")
      .child(_idUsuarioLogado)
      .child("$nomeImagem.jpg");

  try {
    // Realiza o upload
    final UploadTask task = arquivo.putFile(File(imagemSelecionada.path));

    // Monitora o progresso do upload
    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _progress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    // Obtém a URL após o upload
    final TaskSnapshot snapshot = await task;
    _recuperarUrlImagem(snapshot);
  } catch (e) {
    print("Erro ao fazer upload ou obter URL: $e");
  } finally {
    // Reseta o estado de upload independentemente do resultado
    setState(() {
      _subindoImagem = false;
      _progress = 0.0;
    });
  }
  }

  Future _recuperarUrlImagem(TaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();

    Mensagem mensagem = Mensagem();
    mensagem.idUsuario = _idUsuarioLogado;
    mensagem.mensagem = "";
    mensagem.urlImagem = url;
    mensagem.data = Timestamp.now().toString();
    mensagem.tipo = "imagem";

    //salvar mensagem para remetente
    _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, mensagem);

    //salvar mensagem para o destinatário
    _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, mensagem);
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = auth.currentUser;
    setState(() {
      _idUsuarioLogado = usuarioLogado!.uid;
      _idUsuarioDestinatario = widget.contato.idUsuario;
    });
    _adicionarListenerMensagens();
  }

  Stream<QuerySnapshot> _adicionarListenerMensagens() {
    final stream = db
        .collection("mensagens")
        .doc(_idUsuarioLogado)
        .collection(_idUsuarioDestinatario)
        .orderBy("data", descending: false)
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
      Timer(Duration(seconds: 1), () {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });

    return stream;
  }

  @override
  void initState() {
    _recuperarDadosUsuario();
    super.initState();
  }

  Container _criarCaixaMensagem() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: TextField(
                controller: _controllerMensagem,
                autofocus: true,
                keyboardType: TextInputType.text,
                style: TextStyle(fontSize: 20),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 8, 32, 8),
                    hintText: "Digite uma mensagem...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32)),
                    prefixIcon: IconButton(
                        onPressed: _enviarFoto,
                        icon: _subindoImagem
                            ? CircularProgressIndicator()
                            : Icon(Icons.camera_alt,
                                color: Color(0xff075E54)))),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color(0xff075E54), // Cor verde
              shape: BoxShape.circle, // Forma circular
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _enviarMensagem,
              iconSize: 20,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          CircleAvatar(
            backgroundImage: widget.contato.urlImagem != null
                ? NetworkImage(widget.contato.urlImagem!)
                : AssetImage("assets/images/contato.png") as ImageProvider,
          ),
          SizedBox(width: 8),
          Text(widget.contato.nome)
        ],
      )),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/bg.png"), fit: BoxFit.cover)),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
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
                            children: [Text("Carregando mensagens...")],
                          ),
                        );
                      case ConnectionState.active:
                      case ConnectionState.done:
                        if (snapshot.hasError) {
                          return Expanded(
                            child: Text("Erro ao carregar dados."),
                          );
                        } else if (snapshot.hasData) {
                          QuerySnapshot querySnapshot = snapshot.data!;
                          return Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: querySnapshot.docs.length,
                              itemBuilder: (context, indice) {
                                List<DocumentSnapshot> mensagens =
                                    querySnapshot.docs.toList();
                                DocumentSnapshot item = mensagens[indice];
                                double larguraContainer =
                                    MediaQuery.of(context).size.width * 0.8;

                                Alignment alinhamento = Alignment.centerRight;
                                Color cor = Color(0xffd2ffa5);
                                if (_idUsuarioLogado != item["idUsuario"]) {
                                  alinhamento = Alignment.centerLeft;
                                  cor = Colors.white;
                                }

                                return Align(
                                  alignment: alinhamento,
                                  child: Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Container(
                                        width: larguraContainer,
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            color: cor,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(8))),
                                        child: item["tipo"] == "texto"
                                            ? Text(item["mensagem"],
                                                style: TextStyle(fontSize: 18))
                                            : Image.network(item["urlImagem"])),
                                  ),
                                );
                              },
                            ),
                          );
                        } else {
                          return Center(child: Text("Sem dados disponíveis."));
                        }
                    }
                  },
                ),
                _criarCaixaMensagem(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
