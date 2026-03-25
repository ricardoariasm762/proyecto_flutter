import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final List<String> mensajes = [
    "Hola!",
    "Vas a un lugar cerca a la universidad?",
    "Sí, vamos juntos"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: mensajes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(mensajes[index]),
          );
        },
      ),
    );
  }
}