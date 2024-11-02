import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Configuracoes extends StatefulWidget {
  const Configuracoes({super.key});

  @override
  State<Configuracoes> createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {
  final _controllerNome = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imagem;
  late String _idUsuarioLogado;
  var _subindoImagem = false;
  double _progress = 0.0;
  String? _urlImagemRecuperada;

  Future<void> _recuperarImagem(String origemCamera) async {
    XFile? imagemSelecionada;
    switch(origemCamera) {
      case "camera":
        imagemSelecionada = await _picker.pickImage(source: ImageSource.camera);
        break;
      case "galeria":
        imagemSelecionada = await _picker.pickImage(source: ImageSource.gallery);
        break;
    }

    if (imagemSelecionada != null) {
      setState(() {
        _subindoImagem = true;
        _imagem = File(imagemSelecionada!.path);
        _uploadImagem();
      });
    }  
  }

  Future _uploadImagem() async {
    if (_imagem == null) return;

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference pastaRaiz = storage.ref();
    Reference arquivo = pastaRaiz
    .child("perfil")
    .child("$_idUsuarioLogado.jpg");

    UploadTask task = arquivo.putFile(_imagem!);
    task.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          if (snapshot.state == TaskState.running) {
            _progress = snapshot.bytesTransferred / snapshot.totalBytes;
            _subindoImagem = true;
          } else if (snapshot.state == TaskState.success) {
            _subindoImagem = false;
            _progress = 1.0;
          }
        });
    });

    try {
    TaskSnapshot snapshot = await task; // Aguarda a tarefa de upload ser concluída
    _recuperarUrlImagem(snapshot); // Chama sua função para recuperar a URL da imagem
  } catch (e) {
    print("Erro ao fazer upload ou obter URL: $e");
  }
  }

  Future _recuperarUrlImagem(TaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();
    _atualizarUrlImagemFirestore(url);
    setState(() {
      _urlImagemRecuperada = url;
    });
  }

  _atualizarNomeFirestore() {
    String nome = _controllerNome.text;
    FirebaseFirestore db = FirebaseFirestore.instance;
    Map<String, dynamic> dadosAtualizar = {
      "nome" : nome
    };

    db.collection("usuarios")
    .doc(_idUsuarioLogado)
    .update(dadosAtualizar);

    setState(() {
      
    });

  }

  _atualizarUrlImagemFirestore(String url) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    Map<String, dynamic> dadosAtualizar = {
      "urlImagem" : url
    };

    db.collection("usuarios")
    .doc(_idUsuarioLogado)
    .update(dadosAtualizar);

  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = await auth.currentUser;
    _idUsuarioLogado = usuarioLogado!.uid;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot = await db.collection("usuarios")
    .doc(_idUsuarioLogado)
    .get();

    Map<String, dynamic> dados = snapshot.data() as Map<String, dynamic>;
    _controllerNome.text = dados["nome"];

    if (dados["urlImagem"] != null) {
      setState(() {
        _urlImagemRecuperada = dados["urlImagem"];
      });
    }
  }
   
   @override
  void initState() {
    _recuperarDadosUsuario();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configurações"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: _subindoImagem
              ? CircularProgressIndicator()
              : Container(),
              ),
              CircleAvatar(
                radius: 100,
                backgroundImage: 
                _urlImagemRecuperada != null
                ? NetworkImage(_urlImagemRecuperada!)
                : null,
                backgroundColor: Colors.grey,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _recuperarImagem("camera");
                    },
                    child: Text("Câmera"),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      _recuperarImagem("galeria");
                    },
                    child: Text("Galeria"),
                    )
                ],
              ),
              Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: TextField(
                      autofocus: true,
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                        fontSize: 20
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Nome",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32)
                        )
                      ),
                      controller: _controllerNome,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        await _atualizarNomeFirestore();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.fromLTRB(32, 16, 32, 16)
                      ),
                      child: Text("Salvar", style: TextStyle(color: Colors.white, fontSize: 20)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}