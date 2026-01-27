import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/plant.dart';
import '../../data/models/note.dart';
import '../../data/repositories/plant_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../core/utils/health_calculator.dart';
import 'notification_service.dart';

class NotificationScheduler {
  final NotificationService _notificationService;
  final PlantRepository _plantRepository;
  final NoteRepository _noteRepository;
  
  NotificationScheduler({
    required NotificationService notificationService,
    required PlantRepository plantRepository,
    required NoteRepository noteRepository,
  })  : _notificationService = notificationService,
        _plantRepository = plantRepository,
        _noteRepository = noteRepository;
  
  /// Initialize and schedule all notifications
  Future<void> initializeNotifications() async {
    await _notificationService.init();
    await scheduleMorningDew();
    await scheduleWiltWarnings();
    await scheduleReminders();
  }
  
  /// Schedule the daily Morning Dew notification
  Future<void> scheduleMorningDew() async {
    await _notificationService.scheduleMorningDew();
  }
  
  /// Check and schedule Wilt Warnings for all plants
  Future<void> scheduleWiltWarnings() async {
    final plants = await _plantRepository.getAllPlantsSortedByHealth();
    
    for (final plant in plants) {
      await updateWiltWarningForPlant(plant);
    }
  }
  
  /// Update Wilt Warning for a specific plant
  Future<void> updateWiltWarningForPlant(Plant plant) async {
    // Cancel existing warning
    await _notificationService.cancelWiltWarning(plant.id);
    
    // Don't schedule if archived or snoozed
    if (plant.isArchived) return;
    if (plant.snoozedUntil != null && 
        DateTime.now().isBefore(plant.snoozedUntil!)) {
      return;
    }
    
    // Only schedule if approaching critical (currently thirsty or wilting)
    if (plant.healthState != PlantHealthState.thirsty &&
        plant.healthState != PlantHealthState.wilting) {
      return;
    }
    
    // Calculate time until critical
    final timeUntilCritical = HealthCalculator.timeUntilNextState(
      currentHealth: plant.currentHealth,
      difficultyLevel: plant.difficultyLevel,
    );
    
    if (timeUntilCritical == null) return;
    
    // Schedule warning 1 hour before critical
    final warningDelay = timeUntilCritical - const Duration(hours: 1);
    
    if (warningDelay.isNegative) {
      // Already past warning time, show now
      await _notificationService.scheduleWiltWarning(
        plant,
        const Duration(minutes: 5),
      );
    } else {
      await _notificationService.scheduleWiltWarning(plant, warningDelay);
    }
  }
  
  /// Schedule all upcoming reminders
  Future<void> scheduleReminders() async {
    final reminders = await _noteRepository.getUpcomingReminders();
    
    for (final note in reminders) {
      final plant = await _plantRepository.getPlant(note.plantId);
      if (plant != null) {
        await _notificationService.scheduleReminder(
          note: note,
          plantName: plant.displayName,
        );
      }
    }
  }
  
  /// Schedule a specific reminder
  Future<void> scheduleReminder(Note note, String plantName) async {
    await _notificationService.scheduleReminder(
      note: note,
      plantName: plantName,
    );
  }
  
  /// Cancel a specific reminder
  Future<void> cancelReminder(int noteId) async {
    await _notificationService.cancelReminder(noteId);
  }
  
  /// Reschedule notifications after a plant is watered
  Future<void> onPlantWatered(int plantId) async {
    final plant = await _plantRepository.getPlant(plantId);
    if (plant != null) {
      // Cancel existing Wilt Warning since plant is now healthier
      await _notificationService.cancelWiltWarning(plantId);
      
      // Schedule new warning based on new health
      await updateWiltWarningForPlant(plant);
    }
  }
  
  /// Cancel all notifications for a plant (e.g., when archived)
  Future<void> cancelNotificationsForPlant(int plantId) async {
    await _notificationService.cancelWiltWarning(plantId);
  }
  
  /// Trigger immediate Morning Dew check
  Future<void> triggerMorningDewNow() async {
    final thirstyPlants = await _plantRepository.getThirstiestPlants(5);
    final needsWater = thirstyPlants.where((p) => 
      p.healthState != PlantHealthState.thriving
    ).toList();
    
    if (needsWater.isNotEmpty) {
      await _notificationService.showMorningDewNow(needsWater);
    }
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    notificationService: ref.watch(notificationServiceProvider),
    plantRepository: ref.watch(plantRepositoryProvider),
    noteRepository: ref.watch(noteRepositoryProvider),
  );
});
