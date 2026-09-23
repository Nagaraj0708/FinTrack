import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final bool isDarkMode;
  final String? profileImagePath;
  final String userName;
  final String userEmail;
  final String? appPin;
  final bool isBiometricEnabled;
  final bool isTwoFactorEnabled;
  final bool isLoggedIn;
  final bool isNotificationsEnabled;

  SettingsState({
    this.isDarkMode = false,
    this.profileImagePath,
    this.userName = '',
    this.userEmail = '',
    this.appPin,
    this.isBiometricEnabled = false,
    this.isTwoFactorEnabled = false,
    this.isLoggedIn = false,
    this.isNotificationsEnabled = true,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? profileImagePath,
    String? userName,
    String? userEmail,
    String? appPin,
    bool? isBiometricEnabled,
    bool? isTwoFactorEnabled,
    bool? isLoggedIn,
    bool? isNotificationsEnabled,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      appPin: appPin != null && appPin.isEmpty ? null : (appPin ?? this.appPin),
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _keyIsDarkMode = 'is_dark_mode';
  static const _keyProfileImagePath = 'profile_image_path';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyAppPin = 'app_pin';
  static const _keyBiometric = 'is_biometric_enabled';
  static const _keyTwoFactor = 'is_two_factor_enabled';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyIsNotifications = 'is_notifications';

  late SharedPreferences _prefs;

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);

    return SettingsState(
      isDarkMode: _prefs.getBool(_keyIsDarkMode) ?? false,
      profileImagePath: _prefs.getString(_keyProfileImagePath),
      userName: _prefs.getString(_keyUserName) ?? '',
      userEmail: _prefs.getString(_keyUserEmail) ?? '',
      appPin: _prefs.getString(_keyAppPin),
      isBiometricEnabled: _prefs.getBool(_keyBiometric) ?? false,
      isTwoFactorEnabled: _prefs.getBool(_keyTwoFactor) ?? false,
      isLoggedIn: _prefs.getBool(_keyIsLoggedIn) ?? false,
      isNotificationsEnabled: _prefs.getBool(_keyIsNotifications) ?? true,
    );
  }

  void toggleDarkMode(bool isDark) {
    _prefs.setBool(_keyIsDarkMode, isDark);
    state = state.copyWith(isDarkMode: isDark);
  }

  void updateProfileImage(String path) {
    _prefs.setString(_keyProfileImagePath, path);
    state = state.copyWith(profileImagePath: path);
  }

  void updatePersonalInfo(String name, String email) {
    _prefs.setString(_keyUserName, name);
    _prefs.setString(_keyUserEmail, email);
    state = state.copyWith(userName: name, userEmail: email);
  }

  void updateAppPin(String? pin) {
    if (pin == null || pin.isEmpty) {
      _prefs.remove(_keyAppPin);
      // Disable biometrics if PIN is removed
      _prefs.setBool(_keyBiometric, false);
      state = state.copyWith(appPin: '', isBiometricEnabled: false);
    } else {
      _prefs.setString(_keyAppPin, pin);
      state = state.copyWith(appPin: pin);
    }
  }

  void toggleBiometric(bool enabled) {
    _prefs.setBool(_keyBiometric, enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  void toggleTwoFactor(bool enabled) {
    _prefs.setBool(_keyTwoFactor, enabled);
    state = state.copyWith(isTwoFactorEnabled: enabled);
  }

  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
    state = state.copyWith(isLoggedIn: value);
  }

  void toggleNotifications(bool value) {
    _prefs.setBool(_keyIsNotifications, value);
    state = state.copyWith(isNotificationsEnabled: value);
  }

  Future<void> logout() async {
    // Clear auth state but keep dark mode preference and profile image
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyAppPin);
    await _prefs.remove(_keyBiometric);
    state = SettingsState(
      isDarkMode: state.isDarkMode,
      profileImagePath: state.profileImagePath,
    );
  }
}
