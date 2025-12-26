import 'package:flutter/material.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/measurements/screens/measurements_screen.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class MeasurementAnalyticsScreen extends StatefulWidget {
  final List<Measurement> measurements;

  const MeasurementAnalyticsScreen({super.key, required this.measurements});

  @override
  State<MeasurementAnalyticsScreen> createState() => _MeasurementAnalyticsScreenState();
}

class _MeasurementAnalyticsScreenState extends State<MeasurementAnalyticsScreen> {
  String _selectedMetric = 'weight';
  List<String> _trackedMetrics = ['weight', 'bodyFat', 'chest', 'waist'];

  @override
  void initState() {
    super.initState();
    _loadTrackedMetrics();
  }

  void _loadTrackedMetrics() {
    final saved = LocalStorageService.getSetting('trackedMetrics', defaultValue: ['weight', 'bodyFat', 'chest', 'waist']);
    if (saved is List) {
      setState(() {
        _trackedMetrics = List<String>.from(saved);
        if (! _trackedMetrics.contains(_selectedMetric)) {
          _selectedMetric = _trackedMetrics.first;
        }
      });
    }
  }

  void _saveTrackedMetrics() {
    LocalStorageService.saveSetting('trackedMetrics', _trackedMetrics);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Measurement Analytics', style: AppTextStyles.h2()),
        actions: [
          IconButton(
            icon: const Icon(Icons. filter_list),
            onPressed:  _showMetricSelector,
            tooltip: 'Select Metrics to Track',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracked Metrics Row
            if (_trackedMetrics.isNotEmpty) ...[
              Row(
                children: [
                  Text('Tracking', style: AppTextStyles.h4()),
                  const Spacer(),
                  Text('${_trackedMetrics.length} metrics', style: AppTextStyles.caption()),
                ],
              ),
              const SizedBox(height: AppSpacing. sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _trackedMetrics.map((metric) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _buildMetricChip(metric),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
            ],

            _buildProgressChart(),

            const SizedBox(height:  AppSpacing.xl),

            _buildStatsSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String value) {
    final isSelected = _selectedMetric == value;
    final hasData = _hasDataForMetric(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetric = value;
        });
      },
      child:  Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ?  AppColors.primary : AppColors. surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors. primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getMetricLabel(value),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : hasData
                        ? AppColors. textPrimaryLight
                        : AppColors. textSecondaryLight,
                fontWeight: isSelected ? FontWeight. w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (! hasData) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 12,
                color: isSelected ? Colors.white70 : AppColors.textSecondaryLight,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMetricSelector() {
    final allMetrics = {
      'Primary': ['bodyFat', 'muscleMass', 'bmi'], // Weight removed - always tracked
      'Upper Body': ['neck', 'shoulders', 'chest', 'waist', 'hips'],
      'Arms': ['leftArm', 'rightArm', 'leftForearm', 'rightForearm'],
      'Legs':  ['leftThigh', 'rightThigh', 'leftCalf', 'rightCalf'],
    };

    showModalBottomSheet(
      context:  context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Select Metrics to Track', style: AppTextStyles. h2()),
                        const Spacer(),
                        TextButton(
                          onPressed:  () {
                            setState(() {
                              _trackedMetrics = ['weight', 'bodyFat', 'chest', 'waist'];
                              _selectedMetric = 'weight';
                            });
                            _saveTrackedMetrics();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors. info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                        border: Border.all(color: AppColors.info. withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: AppColors.info),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Weight is always tracked.  Select additional metrics below.',
                              style: AppTextStyles.bodySmall(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${_trackedMetrics.length} metrics selected',
                      style: AppTextStyles.caption(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: allMetrics. entries.map((entry) {
                          return Column(
                            crossAxisAlignment:  CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                child: Text(entry.key, style: AppTextStyles.h4()),
                              ),
                              ... entry.value.map((metric) {
                                final isTracked = _trackedMetrics. contains(metric);
                                return CheckboxListTile(
                                  title: Text(_getMetricLabel(metric)),
                                  subtitle: Text(_getMetricUnit(metric)),
                                  value: isTracked,
                                  onChanged: (value) {
                                    setModalState(() {
                                      if (value == true) {
                                        if (!_trackedMetrics.contains(metric)) {
                                          _trackedMetrics.add(metric);
                                        }
                                      } else {
                                        _trackedMetrics. remove(metric);
                                        if (_selectedMetric == metric && _trackedMetrics.isNotEmpty) {
                                          _selectedMetric = _trackedMetrics.first;
                                        }
                                      }
                                    });
                                    setState(() {});
                                    _saveTrackedMetrics();
                                  },
                                );
                              }),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    
                    SizedBox(
                      width:  double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _hasDataForMetric(String metric) {
    return _getMetricData(metric).length >= 2;
  }

  Widget _buildProgressChart() {
    final data = _getMetricData(_selectedMetric);
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius. circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: AppColors. textSecondaryLight. withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No ${_getMetricLabel(_selectedMetric)} Data', style: AppTextStyles.h3()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add at least 2 measurements with ${_getMetricLabel(_selectedMetric)} to see progress',
              style: AppTextStyles.body(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (data.length == 1) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing. lg),
        decoration: BoxDecoration(
          color: AppColors. surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: AppColors.info),
            const SizedBox(height: AppSpacing.md),
            Text('Only 1 ${_getMetricLabel(_selectedMetric)} Entry', style: AppTextStyles.h3()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Current: ${_convertValue(data.first. value, _selectedMetric).toStringAsFixed(1)} ${_getMetricUnit(_selectedMetric, weightUnit:  weightUnit)}',
              style:  AppTextStyles.h2(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add another measurement to track progress',
              style: AppTextStyles.body(color: AppColors. textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final convertedData = data. map((d) => 
      _ChartData(d.date, _convertValue(d.value, _selectedMetric))
    ).toList();

    final minValue = convertedData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxValue = convertedData. map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final change = convertedData.last.value - convertedData.first.value;
    final changePercent = convertedData.first.value != 0 ? (change / convertedData.first.value * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing. md),
      decoration: BoxDecoration(
        color: AppColors. surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getMetricLabel(_selectedMetric), style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '${convertedData.last.value.toStringAsFixed(1)} ${_getMetricUnit(_selectedMetric, weightUnit:  weightUnit)}',
                style:  AppTextStyles.h1(color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing. xs,
                ),
                decoration: BoxDecoration(
                  color: (change >= 0 ? AppColors.success : AppColors.error).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      change >= 0 ?  Icons.trending_up : Icons. trending_down,
                      size: 16,
                      color: change >= 0 ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change >= 0 ? "+" : ""}${change.toStringAsFixed(1)} (${changePercent.toStringAsFixed(1)}%)',
                      style: AppTextStyles.bodySmall(
                        color: change >= 0 ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _SimpleLineChartPainter(convertedData, minValue, maxValue),
              child: Container(),
            ),
          ),
          const SizedBox(height:  AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMM d').format(convertedData.first.date), style: AppTextStyles.caption()),
              Text('${convertedData.length} entries', style: AppTextStyles.caption()),
              Text(DateFormat('MMM d').format(convertedData.last.date), style: AppTextStyles.caption()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final data = _getMetricData(_selectedMetric);
    if (data.length < 2) return const SizedBox. shrink();

    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue:  'lbs');
    final convertedData = data.map((d) => _convertValue(d.value, _selectedMetric)).toList();

    final minValue = convertedData. reduce((a, b) => a < b ? a : b);
    final maxValue = convertedData. reduce((a, b) => a > b ? a : b);
    final avgValue = convertedData.reduce((a, b) => a + b) / convertedData.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics', style: AppTextStyles.h3()),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Min', minValue.toStringAsFixed(1), AppColors.info, weightUnit),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard('Avg', avgValue.toStringAsFixed(1), AppColors.secondary, weightUnit),
            ),
            const SizedBox(width:  AppSpacing.md),
            Expanded(
              child: _buildStatCard('Max', maxValue.toStringAsFixed(1), AppColors.warning, weightUnit),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, String weightUnit) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h3(color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption()),
        ],
      ),
    );
  }

  double _convertValue(double value, String metric) {
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    
    // Convert weight if needed
    if (metric == 'weight' && weightUnit == 'kg') {
      return value * 0.453592; // lbs to kg
    }
    
    return value;
  }

  List<_ChartData> _getMetricData(String metric) {
    final sorted = List<Measurement>.from(widget.measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    switch (metric) {
      case 'weight':
        return sorted. map((m) => _ChartData(m.date, m. weight)).toList();
      case 'bodyFat':
        return sorted.where((m) => m.bodyFat != null).map((m) => _ChartData(m. date, m.bodyFat! )).toList();
      case 'muscleMass':
        return sorted.where((m) => m.muscleMass != null).map((m) => _ChartData(m.date, m.muscleMass!)).toList();
      case 'bmi':
        return sorted.where((m) => m.bmi != null).map((m) => _ChartData(m.date, m.bmi!)).toList();
      case 'neck':
        return sorted.where((m) => m.neck != null).map((m) => _ChartData(m. date, m.neck!)).toList();
      case 'shoulders':
        return sorted.where((m) => m.shoulders != null).map((m) => _ChartData(m.date, m.shoulders!)).toList();
      case 'chest':
        return sorted.where((m) => m.chest != null).map((m) => _ChartData(m.date, m.chest! )).toList();
      case 'waist':
        return sorted.where((m) => m.waist != null).map((m) => _ChartData(m.date, m.waist! )).toList();
      case 'hips':
        return sorted.where((m) => m.hips != null).map((m) => _ChartData(m.date, m.hips! )).toList();
      case 'leftArm':
        return sorted.where((m) => m.leftArm != null).map((m) => _ChartData(m.date, m.leftArm!)).toList();
      case 'rightArm': 
        return sorted.where((m) => m.rightArm != null).map((m) => _ChartData(m.date, m.rightArm!)).toList();
      case 'leftForearm':
        return sorted.where((m) => m.leftForearm != null).map((m) => _ChartData(m.date, m.leftForearm!)).toList();
      case 'rightForearm':
        return sorted.where((m) => m.rightForearm != null).map((m) => _ChartData(m.date, m.rightForearm!)).toList();
      case 'leftThigh':
        return sorted.where((m) => m.leftThigh != null).map((m) => _ChartData(m. date, m.leftThigh! )).toList();
      case 'rightThigh':
        return sorted.where((m) => m.rightThigh != null).map((m) => _ChartData(m.date, m.rightThigh!)).toList();
      case 'leftCalf': 
        return sorted.where((m) => m.leftCalf != null).map((m) => _ChartData(m.date, m.leftCalf!)).toList();
      case 'rightCalf':
        return sorted. where((m) => m.rightCalf != null).map((m) => _ChartData(m.date, m.rightCalf!)).toList();
      default:
        return [];
    }
  }

  String _getMetricLabel(String metric) {
    switch (metric) {
      case 'weight':  return 'Weight';
      case 'bodyFat': return 'Body Fat';
      case 'muscleMass': return 'Muscle Mass';
      case 'bmi': return 'BMI';
      case 'neck': return 'Neck';
      case 'shoulders': return 'Shoulders';
      case 'chest': return 'Chest';
      case 'waist': return 'Waist';
      case 'hips': return 'Hips';
      case 'leftArm': return 'Left Arm';
      case 'rightArm': return 'Right Arm';
      case 'leftForearm': return 'Left Forearm';
      case 'rightForearm': return 'Right Forearm';
      case 'leftThigh': return 'Left Thigh';
      case 'rightThigh': return 'Right Thigh';
      case 'leftCalf': return 'Left Calf';
      case 'rightCalf':  return 'Right Calf';
      default: return '';
    }
  }

  String _getMetricUnit(String metric, {String? weightUnit}) {
    final unit = weightUnit ?? LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    
    switch (metric) {
      case 'weight': 
        return unit;
      case 'bodyFat':
      case 'muscleMass': 
        return '%';
      case 'bmi':
        return '';
      default:
        return 'in';
    }
  }
}

class _ChartData {
  final DateTime date;
  final double value;
  _ChartData(this.date, this.value);
}

class _SimpleLineChartPainter extends CustomPainter {
  final List<_ChartData> data;
  final double minValue;
  final double maxValue;

  _SimpleLineChartPainter(this.data, this.minValue, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      .. strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final path = Path();
    final range = maxValue - minValue;
    final padding = range * 0.1;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i]. value - minValue + padding) / (range + 2 * padding);
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 6, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}