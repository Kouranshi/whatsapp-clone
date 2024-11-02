import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/model/usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AbaContatos extends StatefulWidget {
  const AbaContatos({super.key});

  @override
  State<AbaContatos> createState() => _AbaContatosState();
}

class _AbaContatosState extends State<AbaContatos> {
  late String? _emailUsuarioLogado;
  late String _idUsuarioLogado;

  Future<List<Usuario>> _recuperarContatos() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await db.collection("usuarios")
    .get();

    List<Usuario> listaUsuarios = [];
    for(DocumentSnapshot item in querySnapshot.docs) {
      var dados = item.data() as Map<String, dynamic>;
      if ( dados["email"] == _emailUsuarioLogado ) continue;

      Usuario usuario = Usuario();
      usuario.idUsuario = item.id;
      usuario.email = dados["email"];
      usuario.nome = dados["nome"];
      usuario.urlImagem = dados["urlImagem"];

      listaUsuarios.add(usuario);
    }

    return listaUsuarios;
  }

  Future<void> _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = await auth.currentUser;
    _idUsuarioLogado = usuarioLogado!.uid;
    _emailUsuarioLogado = usuarioLogado.email;

  }

  @override
  void initState() {
    _recuperarDadosUsuario();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>>(
      future: _recuperarDadosUsuario().then((_) => _recuperarContatos()),
      builder: (context, AsyncSnapshot<List<Usuario>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: [
                  Text("Carregando contatos.")
                ],
              ),
            );
          case ConnectionState.active:
          case ConnectionState.done:
             if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (_, indice) {
              List<Usuario>? listaItens = snapshot.data;
              Usuario usuario = listaItens![indice];

              return ListTile(
                onTap: () {
                  Navigator.pushNamed(context, "/mensagens", arguments: usuario);
                },
                contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                leading: CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: Colors.grey,
                  backgroundImage: usuario.urlImagem != null 
                  ? NetworkImage(usuario.urlImagem!)
                  : AssetImage("assets/images/contato.png")
                ),
                title: Text(
                  usuario.nome,
                  style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),
                ),
              );
            },
          ); 
          } else {
            return Center(child: Text("Nenhum contato encontrado."));
          }
          default:
            return Center(child: Text("Erro ao carregar contatos."));
        }
      }
    );
  }
}