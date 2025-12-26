import 'package:reprise/services/local_storage_service.dart';

class WeightUtils {
  // Convert stored weight (lbs) to display weight based on user setting
  static double convertToDisplayWeight(double weightInLbs) {
    final unit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    if (unit == 'kg') {
      return weightInLbs * 0.453592;
    }
    return weightInLbs;
  }

  // Convert user input weight to storage weight (lbs)
  static double convertToStorageWeight(double displayWeight) {
    final unit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    if (unit == 'kg') {
      return displayWeight / 0.453592;
    }
    return displayWeight;
  }

  // Get current weight unit
  static String getWeightUnit() {
    return LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
  }

  // Format weight for display with unit
  static String formatWeight(double weightInLbs, {int decimals = 1}) {
    final displayWeight = convertToDisplayWeight(weightInLbs);
    final unit = getWeightUnit();
    return '${displayWeight.toStringAsFixed(decimals)} $unit';
  }

  // Format weight for display without unit
  static String formatWeightValue(double weightInLbs, {int decimals = 1}) {
    final displayWeight = convertToDisplayWeight(weightInLbs);
    return displayWeight.toStringAsFixed(decimals);
  }
}