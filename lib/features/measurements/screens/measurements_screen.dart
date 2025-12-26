import 'package:flutter/material.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:reprise/features/measurements/screens/measurement_analytics_screen.dart';
import 'package:intl/intl.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  List<Measurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  void _loadMeasurements() {
    final saved = LocalStorageService.getSetting('measurements', defaultValue: []);
    if (saved is List) {
      setState(() {
        _measurements = saved
            .map((m) => Measurement.fromJson(Map<String, dynamic>.from(m)))
            .toList()
          ..sort((a, b) => b.date.compareTo(a. date));
      });
    }
  }

  void _saveMeasurements() {
    LocalStorageService.saveSetting(
      'measurements',
      _measurements.map((m) => m.toJson()).toList(),
    );
  }

  String _getWeightUnit() {
    return LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
  }

  double _convertWeight(double lbs) {
    final unit = _getWeightUnit();
    if (unit == 'kg') {
      return lbs * 0.453592;
    }
    return lbs;
  }

  double _convertWeightToLbs(double value) {
    final unit = _getWeightUnit();
    if (unit == 'kg') {
      return value / 0.453592;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Body Measurements', style: AppTextStyles.h2()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeasurementAnalyticsScreen(measurements: _measurements),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
        ],
      ),
      body: _measurements.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _measurements.length,
              itemBuilder: (context, index) {
                final measurement = _measurements[index];
                return _buildMeasurementCard(measurement, index);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMeasurementDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Measurement'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child:  Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons. straighten,
              size: 80,
              color: AppColors. textSecondaryLight. withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No Measurements Yet', style: AppTextStyles.h2()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Track your complete body measurements to see progress',
              style: AppTextStyles. body(color: AppColors.textSecondaryLight),
              textAlign:  TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(measurement.date),
                  style: AppTextStyles.h3(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: AppColors.primary,
                      onPressed: () => _showEditMeasurementDialog(measurement, index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.error,
                      onPressed: () => _showDeleteConfirmation(measurement, index),
                      padding: EdgeInsets. zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Primary', style: AppTextStyles.h4()),
            const SizedBox(height: AppSpacing.sm),
            _buildMeasurementRow('Weight', '${_convertWeight(measurement.weight).toStringAsFixed(1)} ${_getWeightUnit()}'),
            if (measurement.bodyFat != null)
              _buildMeasurementRow('Body Fat', '${measurement.bodyFat}%'),
            if (measurement. muscleMass != null)
              _buildMeasurementRow('Muscle Mass', '${measurement.muscleMass}%'),
            if (measurement.bmi != null)
              _buildMeasurementRow('BMI', measurement.bmi! .toStringAsFixed(1)),

            if (_hasUpperBody(measurement)) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text('Upper Body', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              if (measurement.neck != null)
                _buildMeasurementRow('Neck', '${measurement.neck} in'),
              if (measurement.shoulders != null)
                _buildMeasurementRow('Shoulders', '${measurement.shoulders} in'),
              if (measurement.chest != null)
                _buildMeasurementRow('Chest', '${measurement.chest} in'),
              if (measurement.waist != null)
                _buildMeasurementRow('Waist', '${measurement.waist} in'),
              if (measurement.hips != null)
                _buildMeasurementRow('Hips', '${measurement.hips} in'),
            ],

            if (_hasArms(measurement)) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text('Arms', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              if (measurement.leftArm != null)
                _buildMeasurementRow('Left Arm', '${measurement.leftArm} in'),
              if (measurement.rightArm != null)
                _buildMeasurementRow('Right Arm', '${measurement.rightArm} in'),
              if (measurement.leftForearm != null)
                _buildMeasurementRow('Left Forearm', '${measurement.leftForearm} in'),
              if (measurement.rightForearm != null)
                _buildMeasurementRow('Right Forearm', '${measurement. rightForearm} in'),
            ],

            if (_hasLegs(measurement)) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text('Legs', style: AppTextStyles. h4()),
              const SizedBox(height: AppSpacing. sm),
              if (measurement. leftThigh != null)
                _buildMeasurementRow('Left Thigh', '${measurement.leftThigh} in'),
              if (measurement.rightThigh != null)
                _buildMeasurementRow('Right Thigh', '${measurement.rightThigh} in'),
              if (measurement. leftCalf != null)
                _buildMeasurementRow('Left Calf', '${measurement.leftCalf} in'),
              if (measurement.rightCalf != null)
                _buildMeasurementRow('Right Calf', '${measurement.rightCalf} in'),
            ],

            if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text('Notes:', style: AppTextStyles.caption()),
              Text(measurement.notes!, style: AppTextStyles.body()),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Measurement measurement, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Measurement', style: AppTextStyles.h3()),
        content: Text(
          'Are you sure you want to delete this measurement from ${DateFormat('MMM d, yyyy').format(measurement.date)}?',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _measurements.removeAt(index);
                _saveMeasurements();
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Measurement deleted'),
                  backgroundColor: AppColors.error,
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditMeasurementDialog(Measurement measurement, int index) {
    final weightController = TextEditingController(
      text: _convertWeight(measurement.weight).toStringAsFixed(1),
    );
    final bodyFatController = TextEditingController(
      text: measurement.bodyFat?. toString() ?? '',
    );
    final muscleMassController = TextEditingController(
      text:  measurement.muscleMass?.toString() ?? '',
    );
    final bmiController = TextEditingController(
      text: measurement. bmi?.toString() ?? '',
    );
    final neckController = TextEditingController(
      text: measurement.neck?. toString() ?? '',
    );
    final shouldersController = TextEditingController(
      text: measurement.shoulders?.toString() ?? '',
    );
    final chestController = TextEditingController(
      text: measurement.chest?.toString() ?? '',
    );
    final waistController = TextEditingController(
      text: measurement.waist?.toString() ?? '',
    );
    final hipsController = TextEditingController(
      text: measurement.hips?.toString() ?? '',
    );
    final leftArmController = TextEditingController(
      text: measurement. leftArm?.toString() ?? '',
    );
    final rightArmController = TextEditingController(
      text: measurement.rightArm?.toString() ?? '',
    );
    final leftForearmController = TextEditingController(
      text: measurement.leftForearm?.toString() ?? '',
    );
    final rightForearmController = TextEditingController(
      text: measurement.rightForearm?.toString() ?? '',
    );
    final leftThighController = TextEditingController(
      text: measurement.leftThigh?.toString() ?? '',
    );
    final rightThighController = TextEditingController(
      text: measurement.rightThigh?.toString() ?? '',
    );
    final leftCalfController = TextEditingController(
      text: measurement.leftCalf?.toString() ?? '',
    );
    final rightCalfController = TextEditingController(
      text: measurement.rightCalf?. toString() ?? '',
    );
    final notesController = TextEditingController(
      text: measurement.notes ??  '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Measurement', style: AppTextStyles.h3()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Primary Measurements', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (${_getWeightUnit()}) *',
                  prefixIcon: const Icon(Icons. monitor_weight),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller:  bodyFatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Body Fat %',
                  prefixIcon:  Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller:  muscleMassController,
                keyboardType: TextInputType. number,
                decoration: const InputDecoration(
                  labelText: 'Muscle Mass %',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller:  bmiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'BMI',
                  prefixIcon: Icon(Icons.analytics),
                ),
              ),

              const SizedBox(height:  AppSpacing.lg),
              const Divider(),
              Text('Upper Body', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: neckController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Neck (inches)',
                  prefixIcon:  Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: shouldersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Shoulders (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: chestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Chest (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height:  AppSpacing.sm),
              TextField(
                controller: waistController,
                keyboardType:  TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Waist (inches)',
                  prefixIcon: Icon(Icons. straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller:  hipsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hips (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),

              const SizedBox(height:  AppSpacing.lg),
              const Divider(),
              Text('Arms', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: leftArmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Left Arm (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height:  AppSpacing.sm),
              TextField(
                controller: rightArmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Right Arm (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: leftForearmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Left Forearm (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height:  AppSpacing.sm),
              TextField(
                controller: rightForearmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Right Forearm (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),

              const SizedBox(height:  AppSpacing.lg),
              const Divider(),
              Text('Legs', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: leftThighController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Left Thigh (inches)',
                  prefixIcon: Icon(Icons. straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller:  rightThighController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText:  'Right Thigh (inches)',
                  prefixIcon:  Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: leftCalfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Left Calf (inches)',
                  prefixIcon: Icon(Icons. straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller:  rightCalfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText:  'Right Calf (inches)',
                  prefixIcon:  Icon(Icons.straighten),
                ),
              ),

              const SizedBox(height:  AppSpacing.lg),
              const Divider(),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              if (weight == null || weight <= 0) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger. of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid weight'),
                    duration: Duration(milliseconds: 800),
                  ),
                );
                return;
              }

              final updatedMeasurement = Measurement(
                date: measurement.date,
                weight: _convertWeightToLbs(weight),
                bodyFat: double.tryParse(bodyFatController.text),
                muscleMass: double.tryParse(muscleMassController.text),
                bmi: double. tryParse(bmiController. text),
                neck: double. tryParse(neckController. text),
                shoulders: double. tryParse(shouldersController. text),
                chest: double. tryParse(chestController. text),
                waist: double.tryParse(waistController.text),
                hips: double.tryParse(hipsController.text),
                leftArm: double.tryParse(leftArmController.text),
                rightArm: double.tryParse(rightArmController. text),
                leftForearm: double.tryParse(leftForearmController.text),
                rightForearm: double. tryParse(rightForearmController.text),
                leftThigh: double.tryParse(leftThighController.text),
                rightThigh: double.tryParse(rightThighController. text),
                leftCalf:  double.tryParse(leftCalfController.text),
                rightCalf: double.tryParse(rightCalfController.text),
                notes: notesController. text. trim().isEmpty ? null : notesController. text. trim(),
              );

              setState(() {
                _measurements[index] = updatedMeasurement;
                _saveMeasurements();
              });

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger. of(context).showSnackBar(
                const SnackBar(
                  content: Text('Measurement updated ✓'),
                  backgroundColor: AppColors.success,
                  duration: Duration(milliseconds:  800),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  bool _hasUpperBody(Measurement m) {
    return m.neck != null || m.shoulders != null || m.chest != null || m.waist != null || m. hips != null;
  }

  bool _hasArms(Measurement m) {
    return m.leftArm != null || m.rightArm != null || m.leftForearm != null || m.rightForearm != null;
  }

  bool _hasLegs(Measurement m) {
    return m.leftThigh != null || m.rightThigh != null || m.leftCalf != null || m.rightCalf != null;
  }

  Widget _buildMeasurementRow(String label, String value) {
    return Padding(
      padding:  const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:  [
          Text(label, style: AppTextStyles.body()),
          Text(
            value,
            style: AppTextStyles.body(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMeasurementDialog() {
    final weightController = TextEditingController();
    final bodyFatController = TextEditingController();
    final muscleMassController = TextEditingController();
    final bmiController = TextEditingController();
    final neckController = TextEditingController();
    final shouldersController = TextEditingController();
    final chestController = TextEditingController();
    final waistController = TextEditingController();
    final hipsController = TextEditingController();
    final leftArmController = TextEditingController();
    final rightArmController = TextEditingController();
    final leftForearmController = TextEditingController();
    final rightForearmController = TextEditingController();
    final leftThighController = TextEditingController();
    final rightThighController = TextEditingController();
    final leftCalfController = TextEditingController();
    final rightCalfController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Measurement', style: AppTextStyles.h3()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Primary Measurements', style: AppTextStyles. h4()),
              const SizedBox(height: AppSpacing. sm),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (${_getWeightUnit()}) *',
                  prefixIcon: const Icon(Icons.monitor_weight),
                ),
                autofocus:  true,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: bodyFatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Body Fat %',
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: muscleMassController,
                keyboardType:  TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Muscle Mass %',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller:  bmiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'BMI',
                  prefixIcon: Icon(Icons.analytics),
                ),
              ),

              const SizedBox(height:  AppSpacing.lg),
              const Divider(),
              Text('Upper Body', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: neckController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Neck (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: shouldersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Shoulders (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height:  AppSpacing.sm),
              TextField(
                controller: chestController,
                keyboardType:  TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Chest (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: waistController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Waist (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: hipsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText:  'Hips (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              Text('Arms', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller:  leftArmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText:  'Left Arm (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: rightArmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Right Arm (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height:  AppSpacing.sm),
              TextField(
                controller: leftForearmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Left Forearm (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: rightForearmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Right Forearm (inches)',
                  prefixIcon: Icon(Icons. straighten),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              Text('Legs', style:  AppTextStyles.h4()),
              const SizedBox(height:  AppSpacing.sm),
              TextField(
                controller: leftThighController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Left Thigh (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing. sm),
              TextField(
                controller: rightThighController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Right Thigh (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height:  AppSpacing.sm),
              TextField(
                controller: leftCalfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Left Calf (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: AppSpacing. sm),
              TextField(
                controller: rightCalfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Right Calf (inches)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),

              const SizedBox(height:  AppSpacing.lg),
              const Divider(),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText:  'Notes',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed:  () {
              final weight = double.tryParse(weightController. text);
              if (weight == null || weight <= 0) {
                ScaffoldMessenger. of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid weight'),
                    duration: Duration(milliseconds: 800),
                  ),
                );
                return;
              }

              final measurement = Measurement(
                date:  DateTime.now(),
                weight: _convertWeightToLbs(weight),
                bodyFat: double.tryParse(bodyFatController.text),
                muscleMass: double.tryParse(muscleMassController.text),
                bmi: double. tryParse(bmiController. text),
                neck: double. tryParse(neckController. text),
                shoulders: double. tryParse(shouldersController. text),
                chest: double. tryParse(chestController. text),
                waist: double.tryParse(waistController.text),
                hips: double.tryParse(hipsController.text),
                leftArm: double.tryParse(leftArmController.text),
                rightArm: double.tryParse(rightArmController. text),
                leftForearm: double.tryParse(leftForearmController.text),
                rightForearm: double. tryParse(rightForearmController.text),
                leftThigh: double.tryParse(leftThighController.text),
                rightThigh: double.tryParse(rightThighController. text),
                leftCalf:  double.tryParse(leftCalfController.text),
                rightCalf: double.tryParse(rightCalfController.text),
                notes: notesController. text.trim().isEmpty ? null : notesController.text.trim(),
              );

              setState(() {
                _measurements.insert(0, measurement);
                _saveMeasurements();
              });

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Measurement added'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class Measurement {
  final DateTime date;
  final double weight;
  final double?  bodyFat;
  final double? muscleMass;
  final double? bmi;
  final double? neck;
  final double? shoulders;
  final double? chest;
  final double?  waist;
  final double?  hips;
  final double?  leftArm;
  final double? rightArm;
  final double? leftForearm;
  final double? rightForearm;
  final double? leftThigh;
  final double? rightThigh;
  final double?  leftCalf;
  final double? rightCalf;
  final String? notes;

  Measurement({
    required this.date,
    required this.weight,
    this.bodyFat,
    this.muscleMass,
    this.bmi,
    this.neck,
    this.shoulders,
    this.chest,
    this.waist,
    this.hips,
    this.leftArm,
    this.rightArm,
    this.leftForearm,
    this.rightForearm,
    this.leftThigh,
    this.rightThigh,
    this.leftCalf,
    this.rightCalf,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
      'bodyFat': bodyFat,
      'muscleMass': muscleMass,
      'bmi': bmi,
      'neck': neck,
      'shoulders':  shoulders,
      'chest': chest,
      'waist': waist,
      'hips':  hips,
      'leftArm': leftArm,
      'rightArm': rightArm,
      'leftForearm': leftForearm,
      'rightForearm': rightForearm,
      'leftThigh': leftThigh,
      'rightThigh': rightThigh,
      'leftCalf':  leftCalf,
      'rightCalf': rightCalf,
      'notes': notes,
    };
  }

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      date: DateTime.parse(json['date']),
      weight: json['weight']. toDouble(),
      bodyFat: json['bodyFat']?.toDouble(),
      muscleMass: json['muscleMass']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      neck: json['neck']?.toDouble(),
      shoulders: json['shoulders']?.toDouble(),
      chest: json['chest']?.toDouble(),
      waist: json['waist']?.toDouble(),
      hips: json['hips']?.toDouble(),
      leftArm: json['leftArm']?.toDouble(),
      rightArm: json['rightArm']?.toDouble(),
      leftForearm: json['leftForearm']?.toDouble(),
      rightForearm: json['rightForearm']?.toDouble(),
      leftThigh: json['leftThigh']?.toDouble(),
      rightThigh: json['rightThigh']?.toDouble(),
      leftCalf: json['leftCalf']?.toDouble(),
      rightCalf: json['rightCalf']?.toDouble(),
      notes: json['notes'],
    );
  }
}