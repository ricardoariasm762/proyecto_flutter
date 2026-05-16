import 'package:flutter/material.dart';
import '../services/groq_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final GroqService _aiService = GroqService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': '¡Hola! Soy el asistente de soporte de Ride Match Pasto. ¿Tienes alguna queja, sugerencia o necesitas ayuda con un precio? Estoy aquí para escucharte.'
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();

    final prompt = """
    Actúa como un agente de servicio al cliente de Ride Match en Pasto. 
    Si el usuario reporta una queja, sé empático y dile que registrarás el caso. 
    Si pregunta por precios, recuerda: Mínima 5000, Ordinaria 7500.
    Usuario dice: $text
    """;

    final response = await _aiService.preguntar(prompt);

    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isLoading = false;
    });
  }

  Future<void> _quickAction(String action) async {
    setState(() => _isLoading = true);
    String response = "";
    
    if (action == 'price') {
      response = await _aiService.sugerirPrecio(5.0, 2); // Ejemplo base
    } else if (action == 'safety') {
      response = await _aiService.obtenerConsejoSeguridad();
    } else if (action == 'icebreaker') {
      response = await _aiService.obtenerIceBreaker();
    }

    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Match AI'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Acciones rápidas
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.attach_money,
                    label: 'Precio',
                    onTap: () => _quickAction('price'),
                  ),
                  _ActionButton(
                    icon: Icons.security,
                    label: 'Seguridad',
                    onTap: () => _quickAction('safety'),
                  ),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Romper Hielo',
                    onTap: () => _quickAction('icebreaker'),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAi ? colorScheme.secondaryContainer : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: Text(msg['text']!),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Pregúntame algo...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}
