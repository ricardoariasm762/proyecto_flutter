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
          return Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(mensajes[index]),
          );
          
        },
      ),
    );
  }
}