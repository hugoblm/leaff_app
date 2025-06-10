import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ClimatiqService {
  final String apiKey;
  static const String _batchEndpoint = 'https://api.climatiq.io/data/v1/estimate/batch';
  static const String _singleEndpoint = 'https://beta3.api.climatiq.io/estimate';
  static const String _defaultActivityId = 'consumer_goods-type_unspecified'; // à adapter plus tard

  ClimatiqService({required this.apiKey});

  /// Batch estimation carbone pour une liste de transactions
  /// [transactions] : liste de maps { 'id': String, 'amount': double, 'currency': String }
  /// Retourne une map transactionId -> scoreCarbone (double?)
  Future<Map<String, double?>> estimateCarbonBatch(List<Map<String, dynamic>> transactions) async {
    debugPrint('[Climatiq] Batch request: ' + jsonEncode({
      "requests": transactions.map((tx) => {
        "emission_factor": {"activity_id": _defaultActivityId},
        "parameters": {"money": tx['amount'], "money_unit": tx['currency']},
        "custom_id": tx['id'],
      }).toList(),
    }));
    if (transactions.isEmpty) return {};
    final batchBody = transactions.map((tx) => {
      "emission_factor": {"activity_id": "consumer_goods-type_food_products_not_elsewhere_specified", "data_version": "22.22"},
      "parameters": {"money": tx['amount'], "money_unit": tx['currency']},
      "custom_id": tx['id'],
    }).toList();
    final response = await http.post(
      Uri.parse(_batchEndpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(batchBody),
    );
    debugPrint('[Climatiq] Batch response status: [32m${response.statusCode}[0m');
    debugPrint('[Climatiq] Batch response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = <String, double?>{};
      final List resultsList = data['results'] as List;
      for (var i = 0; i < resultsList.length; i++) {
        final item = resultsList[i];
        // Mapping par index si custom_id absent
        double? co2e;
        if (item.containsKey('co2e') && item['co2e'] is num) {
          co2e = (item['co2e'] as num).toDouble();
        } else {
          co2e = null;
        }
        // Récupère l'id envoyé à la même position
        if (transactions.length > i) {
          final txId = transactions[i]['id'].toString();
          results[txId] = co2e;
        }
      }
      return results;
    }
    return { for (var tx in transactions) tx['id'] as String : null };
  }

  Future<double?> estimateCarbon(String activityId, double amount, String unit) async {
    debugPrint('[Climatiq] Single request: ' + jsonEncode({
      "emission_factor": {"activity_id": activityId},
      "parameters": {"money": amount, "money_unit": unit}
    }));
    final response = await http.post(
      Uri.parse(_singleEndpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "emission_factor": {"activity_id": activityId},
        "parameters": {"money": amount, "money_unit": unit}
      }),
    );
    debugPrint('[Climatiq] Single response status: [32m${response.statusCode}[0m');
    debugPrint('[Climatiq] Single response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['co2e'] is num ? (data['co2e'] as num).toDouble() : null;
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
