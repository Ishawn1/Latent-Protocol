import 'package:flutter/foundation.dart';

/// User interface presentation mode
enum AppUserMode {
  /// Simple, visual, zero-jargon mode designed for Indian smallholder farmers.
  farmer,

  /// Full telemetry mode with raw sensor metrics, DSV, VPD, and engineering parameters.
  expert,
}

/// Service managing the active presentation mode of the application.
class UserModeService extends ChangeNotifier {
  static final UserModeService instance = UserModeService._internal();

  UserModeService._internal();

  AppUserMode _mode = AppUserMode.farmer; // Default to Farmer Mode!

  AppUserMode get mode => _mode;
  bool get isFarmerMode => _mode == AppUserMode.farmer;
  bool get isExpertMode => _mode == AppUserMode.expert;

  void setMode(AppUserMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }

  void toggleMode() {
    _mode = (_mode == AppUserMode.farmer) ? AppUserMode.expert : AppUserMode.farmer;
    notifyListeners();
  }
}
