import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinancesProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  double _weeklyEarnings = 0.0;
  List<Map<String, dynamic>> _dailyMetrics = [];
  double _activeHours = 0.0;

  bool get isLoading => _isLoading;
  double get weeklyEarnings => _weeklyEarnings;
  List<Map<String, dynamic>> get dailyMetrics => _dailyMetrics;
  double get activeHours => _activeHours;

  FinancesProvider() {
    fetchMetrics();
  }

  Future<void> fetchMetrics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Obtener Ganancias Semanales
      final finances = await _supabase
          .from('finances')
          .select('driver_earnings, created_at')
          .eq('driver_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

      _weeklyEarnings = 0.0;
      for (var f in finances) {
        _weeklyEarnings += (f['driver_earnings'] as num).toDouble();
      }

      // 2. Obtener Sesiones para calcular horas activas (Últimos 7 días)
      final sessions = await _supabase
          .from('driver_sessions')
          .select('session_start, session_end')
          .eq('driver_id', userId)
          .gte('session_start', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

      double totalHours = 0;
      for (var s in sessions) {
        if (s['session_end'] != null) {
          final start = DateTime.parse(s['session_start']);
          final end = DateTime.parse(s['session_end']);
          totalHours += end.difference(start).inMinutes / 60.0;
        }
      }
      _activeHours = totalHours;

      // Fake daily distribution for chart (In a real scenario, group the queries by day)
      _dailyMetrics = [
        {'day': 'Lun', 'val': 100.0},
        {'day': 'Mar', 'val': 250.0},
        {'day': 'Mié', 'val': 120.0},
        {'day': 'Jue', 'val': _weeklyEarnings * 0.2},
        {'day': 'Vie', 'val': _weeklyEarnings * 0.3},
        {'day': 'Sáb', 'val': _weeklyEarnings * 0.4},
        {'day': 'Hoy', 'val': _weeklyEarnings * 0.1},
      ];

    } catch (e) {
      debugPrint('Error fetching finances: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registra el inicio de un turno de trabajo
  Future<void> startSession() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('driver_sessions').insert({
        'driver_id': userId,
        'session_start': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error starting session: $e');
    }
  }

  /// Finaliza el turno de trabajo
  Future<void> endSession() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      // Buscar la sesión activa (sin session_end)
      final activeSession = await _supabase
          .from('driver_sessions')
          .select('id')
          .eq('driver_id', userId)
          .isFilter('session_end', null)
          .order('session_start', ascending: false)
          .limit(1)
          .maybeSingle();
          
      if (activeSession != null) {
        await _supabase.from('driver_sessions').update({
          'session_end': DateTime.now().toIso8601String(),
        }).eq('id', activeSession['id'] as String);
      }
    } catch (e) {
      debugPrint('Error ending session: $e');
    }
  }
}

