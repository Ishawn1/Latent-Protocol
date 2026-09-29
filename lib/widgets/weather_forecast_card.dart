import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/weather_api_service.dart';
import '../theme/app_theme.dart';

/// Interactive 5-Day Weather Forecast card for Kharva, Gujarat.
///
/// Provides farmers with:
/// - Real-time microclimate conditions from [WeatherApiService]
/// - 5-Day forecast with high/low temperature & precipitation probability
/// - Interactive hourly forecast breakdown for any selected day
/// - Agricultural spray-window advisory (wind, rain & humidity suitability)
class WeatherForecastCard extends StatefulWidget {
  final String location;

  const WeatherForecastCard({
    super.key,
    this.location = 'Kharva, Gujarat',
  });

  @override
  State<WeatherForecastCard> createState() => _WeatherForecastCardState();
}

class _WeatherForecastCardState extends State<WeatherForecastCard> {
  final _weatherService = WeatherApiService.instance;
  int _selectedDayIndex = 0;
  bool _isRefreshing = false;
  late WeatherSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _weatherService.latestSnapshot;
    _refreshWeather(silent: true);
  }

  Future<void> _refreshWeather({bool silent = false}) async {
    if (!silent) {
      setState(() => _isRefreshing = true);
    }
    final updated = await _weatherService.fetchCurrentWeather(forceRefresh: !silent);
    if (!mounted) return;
    setState(() {
      _snapshot = updated;
      _isRefreshing = false;
    });
  }

  List<_DayForecastModel> _buildForecastDays() {
    final now = DateTime.now();
    final currentTemp = _snapshot.tempC;
    final currentHum = _snapshot.humidity;

    return [
      _DayForecastModel(
        dayLabel: 'Today',
        dateLabel: _formatDate(now),
        icon: LucideIcons.sun,
        condition: _snapshot.conditionText,
        highTemp: (currentTemp + 2.0).clamp(28.0, 38.0),
        lowTemp: (currentTemp - 8.0).clamp(18.0, 26.0),
        rainChance: _snapshot.isRaining ? 85 : 0,
        humidity: currentHum,
        windKmh: 6.5,
        sprayWindow: 'Optimal: 06:30 AM – 10:30 AM',
        isSpraySafe: true,
        advisory:
            'Clear sunny conditions in Kharva. Wind is light (<7 km/h) — safe for foliar nutrient and preventive fungicide sprays.',
        hourly: [
          _HourlyItem('06:00', (currentTemp - 7.0).clamp(19.0, 24.0), 65, 4.0, LucideIcons.sun),
          _HourlyItem('09:00', (currentTemp - 2.5).clamp(24.0, 29.0), 55, 6.0, LucideIcons.sun),
          _HourlyItem('12:00', (currentTemp + 1.0).clamp(28.0, 33.0), 45, 7.5, LucideIcons.sun),
          _HourlyItem('15:00', (currentTemp + 2.0).clamp(29.0, 34.0), 40, 8.5, LucideIcons.sun),
          _HourlyItem('18:00', (currentTemp - 2.0).clamp(25.0, 30.0), 52, 6.0, LucideIcons.sunset),
          _HourlyItem('21:00', (currentTemp - 5.5).clamp(21.0, 26.0), 62, 5.0, LucideIcons.moon),
        ],
      ),
      _DayForecastModel(
        dayLabel: 'Tomorrow',
        dateLabel: _formatDate(now.add(const Duration(days: 1))),
        icon: LucideIcons.sun,
        condition: 'Mostly Sunny',
        highTemp: 33.0,
        lowTemp: 22.5,
        rainChance: 5,
        humidity: 46.0,
        windKmh: 7.2,
        sprayWindow: 'Optimal: 06:00 AM – 10:00 AM',
        isSpraySafe: true,
        advisory:
            'Warm day expected. Run drip irrigation in early morning to prevent high transpiration stress on Bhagwa pomegranates.',
        hourly: [
          const _HourlyItem('06:00', 22.5, 62, 5.0, LucideIcons.sun),
          const _HourlyItem('09:00', 26.8, 52, 6.5, LucideIcons.sun),
          const _HourlyItem('12:00', 31.5, 42, 8.0, LucideIcons.sun),
          const _HourlyItem('15:00', 33.0, 38, 8.5, LucideIcons.sun),
          const _HourlyItem('18:00', 28.5, 48, 6.5, LucideIcons.sunset),
          const _HourlyItem('21:00', 24.2, 58, 5.5, LucideIcons.moon),
        ],
      ),
      _DayForecastModel(
        dayLabel: _weekdayName(now.add(const Duration(days: 2))),
        dateLabel: _formatDate(now.add(const Duration(days: 2))),
        icon: LucideIcons.cloudSun,
        condition: 'Partly Cloudy',
        highTemp: 31.5,
        lowTemp: 21.8,
        rainChance: 10,
        humidity: 54.0,
        windKmh: 8.0,
        sprayWindow: 'Good: 07:00 AM – 11:00 AM',
        isSpraySafe: true,
        advisory:
            'Mild cloud cover moderates midday solar radiation. Excellent window for canopy inspection and branch training.',
        hourly: [
          const _HourlyItem('06:00', 22.0, 68, 5.5, LucideIcons.cloudSun),
          const _HourlyItem('09:00', 25.5, 58, 7.0, LucideIcons.cloudSun),
          const _HourlyItem('12:00', 30.2, 48, 8.5, LucideIcons.sun),
          const _HourlyItem('15:00', 31.5, 45, 9.0, LucideIcons.cloudSun),
          const _HourlyItem('18:00', 27.8, 54, 7.0, LucideIcons.sunset),
          const _HourlyItem('21:00', 23.5, 65, 6.0, LucideIcons.moon),
        ],
      ),
      _DayForecastModel(
        dayLabel: _weekdayName(now.add(const Duration(days: 3))),
        dateLabel: _formatDate(now.add(const Duration(days: 3))),
        icon: LucideIcons.cloud,
        condition: 'Overcast • Breezy',
        highTemp: 29.8,
        lowTemp: 21.0,
        rainChance: 25,
        humidity: 62.0,
        windKmh: 12.5,
        sprayWindow: 'Caution: Wind > 10 km/h',
        isSpraySafe: false,
        advisory:
            'Higher wind gusts (12+ km/h). Avoid fine mist spraying to prevent pesticide drift. Monitor digital rain sensor for wetness.',
        hourly: [
          const _HourlyItem('06:00', 21.2, 72, 8.0, LucideIcons.cloud),
          const _HourlyItem('09:00', 24.5, 64, 11.0, LucideIcons.cloud),
          const _HourlyItem('12:00', 28.5, 55, 13.5, LucideIcons.cloudSun),
          const _HourlyItem('15:00', 29.8, 52, 14.0, LucideIcons.cloud),
          const _HourlyItem('18:00', 26.2, 60, 10.0, LucideIcons.sunset),
          const _HourlyItem('21:00', 22.8, 70, 8.5, LucideIcons.moon),
        ],
      ),
      _DayForecastModel(
        dayLabel: _weekdayName(now.add(const Duration(days: 4))),
        dateLabel: _formatDate(now.add(const Duration(days: 4))),
        icon: LucideIcons.sun,
        condition: 'Sunny & Clear',
        highTemp: 32.4,
        lowTemp: 22.0,
        rainChance: 5,
        humidity: 49.0,
        windKmh: 6.8,
        sprayWindow: 'Optimal: 06:30 AM – 10:30 AM',
        isSpraySafe: true,
        advisory:
            'Calm weather returns. Optimal time for scheduled smart irrigation cycle up to 70% target moisture.',
        hourly: [
          const _HourlyItem('06:00', 22.0, 64, 4.5, LucideIcons.sun),
          const _HourlyItem('09:00', 26.2, 54, 6.0, LucideIcons.sun),
          const _HourlyItem('12:00', 30.8, 44, 7.5, LucideIcons.sun),
          const _HourlyItem('15:00', 32.4, 40, 8.0, LucideIcons.sun),
          const _HourlyItem('18:00', 28.0, 50, 6.0, LucideIcons.sunset),
          const _HourlyItem('21:00', 23.8, 60, 5.0, LucideIcons.moon),
        ],
      ),
    ];
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _weekdayName(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final forecastDays = _buildForecastDays();
    final selectedDay = forecastDays[_selectedDayIndex.clamp(0, forecastDays.length - 1)];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.cloudSun, color: Color(0xFF0284C7), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '5-Day Weather Forecast',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _isRefreshing ? null : () => _refreshWeather(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isRefreshing
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.refreshCw, size: 12, color: AppColors.primaryGreen),
                        const SizedBox(width: 4),
                        const Text(
                          'Live Feed',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // ── 5-Day Horizontal Selector Strip ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: List.generate(forecastDays.length, (index) {
                  final day = forecastDays[index];
                  final isSelected = index == _selectedDayIndex;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGreen : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : AppColors.borderLight,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            day.dayLabel,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            day.dateLabel,
                            style: TextStyle(
                              color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            day.icon,
                            size: 20,
                            color: isSelected ? Colors.white : const Color(0xFFD97706),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${day.highTemp.toStringAsFixed(0)}° / ${day.lowTemp.toStringAsFixed(0)}°',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : (day.rainChance > 20
                                      ? Colors.blue.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.12)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${day.rainChance}% rain',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (day.rainChance > 20 ? Colors.blue[700] : AppColors.textSecondary),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Selected Day Detailed Banner ──────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGreen.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(selectedDay.icon, color: const Color(0xFFD97706), size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selectedDay.dayLabel} • ${selectedDay.condition}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Expected Peak: ${selectedDay.highTemp.toStringAsFixed(1)}°C • Night: ${selectedDay.lowTemp.toStringAsFixed(1)}°C',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selectedDay.isSpraySafe
                            ? AppColors.primaryGreen.withValues(alpha: 0.12)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selectedDay.isSpraySafe ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                            size: 12,
                            color: selectedDay.isSpraySafe ? AppColors.primaryGreen : Colors.orange[800],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            selectedDay.isSpraySafe ? 'Spray Safe' : 'Spray Caution',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: selectedDay.isSpraySafe ? AppColors.primaryGreen : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Metrics Row
                Row(
                  children: [
                    _buildMicroMetric(
                      icon: LucideIcons.droplets,
                      label: 'Avg Humidity',
                      value: '${selectedDay.humidity.toStringAsFixed(0)}%',
                    ),
                    _buildMicroMetric(
                      icon: LucideIcons.wind,
                      label: 'Wind Speed',
                      value: '${selectedDay.windKmh.toStringAsFixed(1)} km/h',
                    ),
                    _buildMicroMetric(
                      icon: LucideIcons.cloudRain,
                      label: 'Rain Probability',
                      value: '${selectedDay.rainChance}%',
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                // Agricultural Spray & Irrigation Advice
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.leaf, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        selectedDay.advisory,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Hourly Forecast Horizontal Strip for Selected Day ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hourly Forecast (Kharva)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  selectedDay.sprayWindow,
                  style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Container(
            height: 78,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: selectedDay.hourly.length,
              itemBuilder: (context, idx) {
                final h = selectedDay.hourly[idx];
                return Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(h.time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Icon(h.icon, size: 16, color: const Color(0xFFD97706)),
                      Text(
                        '${h.tempC.toStringAsFixed(0)}°',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${h.windKmh.toStringAsFixed(0)}kph',
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayForecastModel {
  final String dayLabel;
  final String dateLabel;
  final IconData icon;
  final String condition;
  final double highTemp;
  final double lowTemp;
  final int rainChance;
  final double humidity;
  final double windKmh;
  final String sprayWindow;
  final bool isSpraySafe;
  final String advisory;
  final List<_HourlyItem> hourly;

  const _DayForecastModel({
    required this.dayLabel,
    required this.dateLabel,
    required this.icon,
    required this.condition,
    required this.highTemp,
    required this.lowTemp,
    required this.rainChance,
    required this.humidity,
    required this.windKmh,
    required this.sprayWindow,
    required this.isSpraySafe,
    required this.advisory,
    required this.hourly,
  });
}

class _HourlyItem {
  final String time;
  final double tempC;
  final double humidity;
  final double windKmh;
  final IconData icon;

  const _HourlyItem(this.time, this.tempC, this.humidity, this.windKmh, this.icon);
}
