import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/model/usuario.dart';
import 'package:whatsapp/telas/abacontatos.dart';
import 'package:whatsapp/telas/abaconversas.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _emailUsuario = "";
  List<String> itensMenu = ["Configurações", "Deslogar", "Excluir conta"];

  Future _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = await auth.currentUser;

    if (usuarioLogado != null) {
      setState(() {
        _emailUsuario = usuarioLogado.email ?? "Email não disponível";
      });
    }
  }

  _escolhaMenuItem(String itemEscolhido) {
    switch (itemEscolhido) {
      case "Configurações":
        Navigator.pushNamed(context, "/configuracoes");
        break;
      case "Deslogar":
        _deslogarUsuario();
        break;
      case "Excluir conta":
        _excluirContaUsuario();
        break;
    }
  }

  _excluirContaUsuario() async {
    // Confirmação de exclusão
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Excluir Conta",
            style: TextStyle(color: Colors.red),
          ),
          content: Text("Você tem certeza que deseja excluir sua conta?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Excluir"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return; // Se não confirmar, retorna

    _confirmarDeletar(); // Chama o método para excluir a conta
  }

  _confirmarDeletar() async {
    // Solicitar senha para reautenticação
    String? senha = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController senhaController = TextEditingController();
        return AlertDialog(
          title: Text("Digite sua senha"),
          content: TextField(
            controller: senhaController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Senha",
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2), 
                borderRadius: BorderRadius.circular(10), 
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.green,
                    width: 2), 
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true, 
              fillColor: Colors.white, 
              hintText: 'Digite sua senha',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400), 
              contentPadding: EdgeInsets.symmetric(
                  vertical: 15, horizontal: 10), 
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(senhaController.text);
              },
              child: Text("Confirmar"),
            ),
          ],
        );
      },
    );

    if (senha == null || senha.isEmpty) return; // Se não for fornecida a senha, retorna

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? usuarioLogado = auth.currentUser;

      if (usuarioLogado != null) {
        // Reautenticação do usuário
        String email = usuarioLogado.email!;

        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: senha, // Usa a senha fornecida pelo usuário
        );

        // Exclui os dados do usuário no Firestore
        FirebaseFirestore db = FirebaseFirestore.instance;
        await db.collection("usuarios").doc(usuarioLogado.uid).delete();

        // Exclui a conta do Firebase Authentication
        await usuarioLogado.delete();

        // Navega de volta para a tela de login após a exclusão
        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      print("Erro ao excluir conta: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao excluir conta: $e")),
      );
    }
  }

  _deslogarUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose(); // Libera o controlador ao fechar a tela
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Center(
              child: Text(
                "WhatsApp",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            backgroundColor: Color(0xff075E54),
            bottom: TabBar(
              tabs: [
                Tab(
                  child: Text(
                    "Conversas",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    "Contatos",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              indicatorWeight: 6.0,
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
            actions: [
              PopupMenuButton<String>(
                itemBuilder: (context) {
                  return itensMenu.map((String item) {
                    return PopupMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList();
                },
                onSelected: _escolhaMenuItem,
              )
            ],
          ),
          body: TabBarView(
            children: [AbaConversas(), AbaContatos()],
          ),
        ));
  }
}
