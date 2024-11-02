import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp/model/usuario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {

  final _controllerNome = TextEditingController();
  final _controllerEmail = TextEditingController();
  final _controllerSenha = TextEditingController();
  var _mensagemErro = "";
  var _mensagemSucesso = "";

  _validarCampos() {
    //Recuperar dados dos campos
    var nome = _controllerNome.text;
    var email = _controllerEmail.text;
    var senha = _controllerSenha.text;

    //Validar nome
    if (nome.isNotEmpty) {
      if (email.contains("@")) {
        if (senha.isNotEmpty && senha.length >= 6) {

          Usuario usuario = Usuario();
          usuario.nome = nome;
          usuario.email = email;
          usuario.senha = senha;

          _cadastrarUsuario(usuario);
        } else {
          setState(() {
            _mensagemErro = "Preencha a senha. Ela deve ter ao menos 6 caracteres.";
            _mensagemSucesso = "";
          });
        }
      } else {
        setState(() {
          _mensagemErro = "Preencha o e-mail e/ou utilize o @.";
          _mensagemSucesso = "";
        });
      }
    } else {
      setState(() {
        _mensagemErro = "Preencha o nome.";
        _mensagemSucesso = "";
      });
    }
    
  }

  _cadastrarUsuario(Usuario usuario) {
    FirebaseAuth auth = FirebaseAuth.instance;

    auth.createUserWithEmailAndPassword(
      email: usuario.email,
      password: usuario.senha
    ).then((firebaseUser) {
      //salvar dados firebase
      FirebaseFirestore db = FirebaseFirestore.instance;
      db.collection("usuarios")
      .doc(firebaseUser.user?.uid)
      .set(usuario.toMap());
        Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);
      }).catchError((error) {
      setState(() {
            _mensagemErro = "Erro ao cadastrar usuário. Verifique os campos e tente novamente.";
          });
    }); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          "Cadastro",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
        backgroundColor: Color(0xff075E54),
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(color: Color(0xff075E54)),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Image.asset("assets/images/usuario.png", width: 200, height: 150,),
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
                    padding: EdgeInsets.only(bottom: 8),
                    child: TextField(
                      autofocus: false,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: 20
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "E-mail",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32)
                        )
                      ),
                      controller: _controllerEmail,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: TextField(
                      autofocus: false,
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                        fontSize: 20
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Senha",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32)
                        )
                      ),
                      controller: _controllerSenha,
                      obscureText: true,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _validarCampos();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.fromLTRB(32, 16, 32, 16)
                      ),
                      child: Text("Cadastrar", style: TextStyle(color: Colors.white, fontSize: 20)),
                    ),
                  ),
                  Center(
                    child: Text(_mensagemErro, style: TextStyle(color: Colors.red, fontSize: 20)),
                  ),
                  Center(
                    child: Text(_mensagemSucesso, style: TextStyle(color: Colors.green, fontSize: 20)),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}