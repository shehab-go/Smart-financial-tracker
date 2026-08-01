import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';

class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String metaPinEnabled = 'security_pin_enabled';
  static const String metaPinHash = 'security_pin_hash';
  static const String metaBiometricEnabled = 'security_biometric_enabled';

  /// Check if a PIN is set and enabled
  Future<bool> isPinEnabled() async {
    final val = await DatabaseHelper().getMetaValue(metaPinEnabled);
    return val == 'true';
  }

  /// Enable or disable PIN lock
  Future<void> setPinEnabled(bool enabled) async {
    await DatabaseHelper().setMetaValue(metaPinEnabled, enabled ? 'true' : 'false');
    if (!enabled) {
      // Clear hash if disabled
      await DatabaseHelper().setMetaValue(metaPinHash, '');
      await setBiometricEnabled(false); // Can't have biometric without PIN fallback
    }
  }

  /// Check if Biometric lock is enabled
  Future<bool> isBiometricEnabled() async {
    final val = await DatabaseHelper().getMetaValue(metaBiometricEnabled);
    return val == 'true';
  }

  /// Enable or disable biometric lock
  Future<void> setBiometricEnabled(bool enabled) async {
    await DatabaseHelper().setMetaValue(metaBiometricEnabled, enabled ? 'true' : 'false');
  }

  /// Set new PIN (stores SHA-256 hash)
  Future<void> setPin(String pin) async {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    await DatabaseHelper().setMetaValue(metaPinHash, digest.toString());
    await setPinEnabled(true);
  }

  /// Verify entered PIN
  Future<bool> verifyPin(String pin) async {
    final savedHash = await DatabaseHelper().getMetaValue(metaPinHash);
    if (savedHash == null || savedHash.isEmpty) return false;

    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString() == savedHash;
  }

  /// Check if biometric hardware exists and is configured on device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  /// Authenticate user via biometric (Face ID / Fingerprint)
  Future<bool> authenticateBiometric() async {
    final isAvailable = await isBiometricAvailable();
    if (!isAvailable) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: 'يرجى تأكيد هويتك لفتح التطبيق',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
