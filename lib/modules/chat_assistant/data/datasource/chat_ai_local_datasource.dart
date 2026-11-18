import 'package:shared_preferences/shared_preferences.dart';

/// Contador local de mensagens com IA por dia (SharedPreferences).
class ChatAiLocalDatasource {
  static const _dayKey = 'chat_ai_usage_day';
  static const _countKey = 'chat_ai_usage_count';

  /// Quantidade usada em [day] (`yyyy-MM-dd`); outro dia → 0.
  Future<int> usageOf(String day) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dayKey) == day ? prefs.getInt(_countKey) ?? 0 : 0;
  }

  Future<void> saveUsage(String day, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dayKey, day);
    await prefs.setInt(_countKey, count);
  }
}
