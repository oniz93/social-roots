import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/plant.dart';
import 'database_service.dart';

class VacationModeService {
  final Isar _isar;

  static const _vacationEndKey = 'vacation_mode_end';

  VacationModeService(this._isar);

  /// Check if vacation mode is active
  Future<bool> isVacationModeActive() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMs = prefs.getInt(_vacationEndKey);

    if (endTimeMs == null) return false;

    final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMs);
    return DateTime.now().isBefore(endTime);
  }

  /// Get vacation mode end time
  Future<DateTime?> getVacationEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMs = prefs.getInt(_vacationEndKey);

    if (endTimeMs == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(endTimeMs);
  }

  /// Activate vacation mode for all plants
  Future<void> activateVacationMode(Duration duration) async {
    final endTime = DateTime.now().add(duration);

    // Save end time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_vacationEndKey, endTime.millisecondsSinceEpoch);

    // Update all plants
    await _isar.writeTxn(() async {
      final plants = await _isar.plants
          .filter()
          .isArchivedEqualTo(false)
          .findAll();

      for (final plant in plants) {
        plant.snoozedUntil = endTime;
        await _isar.plants.put(plant);
      }
    });
  }

  /// Deactivate vacation mode
  Future<void> deactivateVacationMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vacationEndKey);

    // Clear snooze from all plants
    await _isar.writeTxn(() async {
      final plants = await _isar.plants
          .filter()
          .isArchivedEqualTo(false)
          .findAll();

      for (final plant in plants) {
        plant.snoozedUntil = null;
        await _isar.plants.put(plant);
      }
    });
  }

  /// Get remaining vacation time
  Future<Duration?> getRemainingVacationTime() async {
    final endTime = await getVacationEndTime();
    if (endTime == null) return null;

    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}

final vacationModeServiceProvider = Provider<VacationModeService>((ref) {
  final isar = ref.watch(isarProvider);
  return VacationModeService(isar);
});

final vacationModeActiveProvider = FutureProvider<bool>((ref) {
  final service = ref.watch(vacationModeServiceProvider);
  return service.isVacationModeActive();
});
