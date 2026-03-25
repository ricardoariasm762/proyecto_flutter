import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text("Aquí irá el chat"),
      ),
    );
  }
}