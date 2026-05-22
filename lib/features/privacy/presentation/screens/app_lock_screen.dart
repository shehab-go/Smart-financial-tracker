import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/widgets/main_navigation.dart';
import '../../../../features/onboarding/presentation/screens/onboarding_screen.dart';

class AppLockChecker extends StatefulWidget {
  const AppLockChecker({super.key});

  @override
  State<AppLockChecker> createState() => _AppLockCheckerState();
}

class _AppLockCheckerState extends State<AppLockChecker> {
  bool _isLoading = true;
  bool _pinEnabled = false;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final onboardingDone = await OnboardingService.instance.isOnboardingCompleted();
    final enabled = await SecurityService.instance.isPinEnabled();
    setState(() {
      _onboardingCompleted = onboardingDone;
      _pinEnabled = enabled;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_onboardingCompleted) {
      return const OnboardingScreen();
    }

    if (_pinEnabled) {
      return AppLockScreen(
        onSuccess: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        },
      );
    }

    return const MainNavigation();
  }
}

class AppLockScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const AppLockScreen({super.key, required this.onSuccess});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  bool _biometricEnabled = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupBiometric();
  }

  Future<void> _setupBiometric() async {
    final bioEnabled = await SecurityService.instance.isBiometricEnabled();
    setState(() {
      _biometricEnabled = bioEnabled;
    });

    if (bioEnabled) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _triggerBiometric();
      });
    }
  }

  Future<void> _triggerBiometric() async {
    final success = await SecurityService.instance.authenticateBiometric();
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      widget.onSuccess();
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _onNumberPressed(String number) async {
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += number;
        _hasError = false;
      });

      if (_enteredPin.length == 4) {
        final isValid = await SecurityService.instance.verifyPin(_enteredPin);
        if (isValid) {
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 150), () {
            widget.onSuccess();
          });
        } else {
          HapticFeedback.vibrate();
          Future.delayed(const Duration(milliseconds: 150), () {
            setState(() {
              _enteredPin = '';
              _hasError = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('الرمز المدخل غير صحيح، حاول مجدداً'),
                backgroundColor: AppTheme.errorColor,
                duration: Duration(seconds: 2),
              ),
            );
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Premium App Branding Bento Badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 54,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'التطبيق محمي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'يرجى إدخال رمز الـ PIN الخاص بك للمتابعة',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),

                // PIN indicator circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError
                            ? AppTheme.errorColor
                            : (isFilled ? AppTheme.primaryColor : Colors.white),
                        border: Border.all(
                          color: _hasError
                              ? AppTheme.errorColor
                              : (isFilled ? AppTheme.primaryColor : AppTheme.dividerColor),
                          width: 2,
                        ),
                        boxShadow: isFilled && !_hasError
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.25),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                const Spacer(flex: 2),

                // Numeric Keyboard (Num Pad)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      if (_biometricEnabled) {
                        return InkWell(
                          onTap: _triggerBiometric,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              size: 28,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    if (index == 11) {
                      return InkWell(
                        onTap: _onDeletePressed,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.cardShadow,
                            border: Border.all(
                              color: AppTheme.dividerColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.backspace_outlined,
                            size: 22,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    }

                    final number = index == 10 ? '0' : (index + 1).toString();
                    return InkWell(
                      onTap: () => _onNumberPressed(number),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(
                            color: AppTheme.dividerColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            number,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
