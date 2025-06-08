import 'package:http/http.dart' as http;
import 'dart:convert';

class ClimatiqService {
  final String apiKey;

  ClimatiqService({required this.apiKey});

  Future<double?> estimateCarbon(String activityId, double amount, String unit) async {
    final response = await http.post(
      Uri.parse('https://beta3.api.climatiq.io/estimate'),
      headers: {
        'Authorization': 'Bearer ',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "emission_factor": {"activity_id": activityId},
        "parameters": {"money": amount, "money_unit": unit}
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['co2e'] as double?;
    }
    return null;
  }

  // Simule le calcul d'empreinte carbone par catégorie (POC)
  Future<double> estimateCarbonByCategory({required double amount, required String category}) async {
    // Pour le POC, retourne un score arbitraire basé sur la catégorie
    await Future.delayed(const Duration(milliseconds: 500));
    switch (category) {
      case 'Transport bas carbone':
        return 0.5;
      case 'Transport individuel fossile':
        return 5.0;
      case 'Alimentation conventionnelle':
        return 2.0;
      default:
        return 1.0;
    }
  }
}
