import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/login.dart';
import 'package:whatsapp/routegenerator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Inicializa a ligação de widgets
  await Firebase.initializeApp(); // Inicializa o Firebase
  runApp(MaterialApp(
    home: Login(),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.green,
        accentColor: Color(0xff25D366)
      ),
      appBarTheme: AppBarTheme(
        color: Color(0xff075E54), // Cor do AppBar
        iconTheme: IconThemeData(color: Colors.white), // Cor dos ícones
        titleTextStyle: TextStyle(
          color: Colors.white, // Cor do texto do título
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      )
    ),
    initialRoute: "/",
    onGenerateRoute: RouteGenerator.generateRoute,
    debugShowCheckedModeBanner: false,
  ));
}