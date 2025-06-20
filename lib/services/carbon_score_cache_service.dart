import 'package:shared_preferences/shared_preferences.dart';

typedef TransactionId = String;

class CarbonScoreCacheService {
  static const String _prefix = 'carbon_score_';
  static CarbonScoreCacheService? _instance;
  late SharedPreferences _prefs;

  CarbonScoreCacheService._internal();

  static Future<CarbonScoreCacheService> getInstance() async {
    if (_instance == null) {
      _instance = CarbonScoreCacheService._internal();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<double?> getScore(TransactionId transactionId) async {
    final key = _prefix + transactionId;
    if (!_prefs.containsKey(key)) return null;
    return _prefs.getDouble(key);
  }

  Future<void> setScore(TransactionId transactionId, double score) async {
    final key = _prefix + transactionId;
    await _prefs.setDouble(key, score);
  }

  Future<void> removeScore(TransactionId transactionId) async {
    final key = _prefix + transactionId;
    await _prefs.remove(key);
  }

  Future<void> clearAllScores() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  Future<void> clearScoresForConnection(List<String> transactionIds) async {
    for (final txId in transactionIds) {
      await removeScore(txId);
    }
  }
}
