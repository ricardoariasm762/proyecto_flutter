import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> preguntar(String mensaje) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {
              "role": "system",
              "content":
                  """Eres Ride Match AI, un asistente inteligente de viajes compartidos en Pasto, Colombia. 
              Tu tarea es calcular precios de forma REALISTA, JUSTA y COHERENTE.
              
              REGLAS:
              1. Ride Match es MÁS BARATO que un taxi (Taxi mínima: \$7.500).
              2. Usa COP. Los trayectos cortos deben ser bajos.
              3. Considera distancia, tráfico, hora, clima y pasajeros.
              4. FORMATO DE RESPUESTA OBLIGATORIO:
                 Precio estimado: \$XXXX COP
                 Tiempo aproximado: XX minutos
                 Recomendación: texto corto""",
            },
            {"role": "user", "content": mensaje},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Error de la IA (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      return 'Error de conexión: $e';
    }
  }

  /// Método especializado para sugerir un precio basado en la tarifa de Pasto
  Future<String> sugerirPrecio(double distanciaKm, int numPasajeros) async {
    return preguntar(
      "Calcula un precio justo para un viaje de $distanciaKm km con $numPasajeros pasajeros en Pasto, sabiendo que la mínima es \$7.500.",
    );
  }

  /// Método para obtener consejos de seguridad
  Future<String> obtenerConsejoSeguridad() async {
    return preguntar(
      "Dame un consejo de seguridad corto para compartir viaje en Pasto.",
    );
  }

  /// Método para romper el hielo
  Future<String> obtenerIceBreaker() async {
    return preguntar(
      "Sugiere un tema de conversación cultural sobre Pasto para romper el hielo en un viaje.",
    );
  }
}
