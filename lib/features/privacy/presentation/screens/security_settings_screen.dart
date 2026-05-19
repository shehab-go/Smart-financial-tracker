import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pinEnabled = await SecurityService.instance.isPinEnabled();
    final bioEnabled = await SecurityService.instance.isBiometricEnabled();
    final bioAvailable = await SecurityService.instance.isBiometricAvailable();

    if (mounted) {
      setState(() {
        _pinEnabled = pinEnabled;
        _biometricEnabled = bioEnabled;
        _biometricAvailable = bioAvailable;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePin(bool value) async {
    HapticFeedback.lightImpact();
    if (value) {
      final newPin = await _showPinCreationDialog(context);
      if (newPin != null) {
        await SecurityService.instance.setPin(newPin);
        setState(() {
          _pinEnabled = true;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل رمز القفل بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        setState(() {
          _pinEnabled = false;
        });
      }
    } else {
      final confirm = await _showConfirmDisableDialog();
      if (confirm == true) {
        await SecurityService.instance.setPinEnabled(false);
        setState(() {
          _pinEnabled = false;
          _biometricEnabled = false;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء تفعيل رمز القفل'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    HapticFeedback.lightImpact();
    if (value) {
      final authenticated = await SecurityService.instance.authenticateBiometric();
      if (authenticated) {
        await SecurityService.instance.setBiometricEnabled(true);
        setState(() {
          _biometricEnabled = true;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل القفل البيومتري بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _biometricEnabled = false;
        });
      }
    } else {
      await SecurityService.instance.setBiometricEnabled(false);
      setState(() {
        _biometricEnabled = false;
      });
    }
  }

  Future<void> _changePin() async {
    HapticFeedback.lightImpact();
    final verified = await _showPinVerificationDialog(context);
    if (verified == true) {
      final newPin = await _showPinCreationDialog(context, title: 'رمز PIN الجديد');
      if (newPin != null) {
        await SecurityService.instance.setPin(newPin);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير رمز القفل بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmDisableDialog() async {
    HapticFeedback.vibrate();
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'إلغاء قفل التطبيق؟',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في إلغاء قفل التطبيق؟ سيؤدي هذا إلى إلغاء الحماية البيومترية أيضاً.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, false);
              },
              child: const Text('تراجع', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'إعدادات الأمان والحماية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppTheme.primaryColor,
          iconSize: 20,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Bento card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, size: 40, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'حماية البيانات المالية',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'قم بتأمين حساباتك لمنع المتطفلين من تصفح التطبيق في حال ترك الهاتف مفتوحاً.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.9), height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security options Bento
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor),
                            title: const Text('قفل التطبيق برمز PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('طلب رمز رقمي عند فتح التطبيق', style: TextStyle(fontSize: 11)),
                            value: _pinEnabled,
                            onChanged: _togglePin,
                            activeColor: AppTheme.primaryColor,
                          ),
                          if (_pinEnabled) ...[
                            Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),
                            ListTile(
                              leading: const Icon(Icons.password_rounded, color: AppTheme.primaryColor),
                              title: const Text('تغيير رمز الـ PIN الحالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('قم بتعديل رمز القفل الخاص بك', style: TextStyle(fontSize: 11)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              onTap: _changePin,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Biometric options Bento
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryColor),
                            title: const Text('القفل البيومتري', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              _biometricAvailable
                                  ? 'فتح التطبيق باستخدام بصمة الإصبع أو الوجه'
                                  : 'البصمة غير متوفرة أو غير مفعّلة في جهازك',
                              style: const TextStyle(fontSize: 11),
                            ),
                            value: _biometricEnabled,
                            onChanged: _pinEnabled && _biometricAvailable ? _toggleBiometric : null,
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: AppTheme.successColor, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'تشفير آمن محلي 100%',
                            style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Dialog for PIN Creation / Confirmation
  Future<String?> _showPinCreationDialog(BuildContext context, {String title = 'إنشاء رمز PIN الجديد'}) async {
    String firstPin = '';
    String currentText = '';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void onNumberPressed(String number) {
              if (currentText.length < 4) {
                HapticFeedback.lightImpact();
                setDialogState(() {
                  currentText += number;
                });

                if (currentText.length == 4) {
                  if (firstPin.isEmpty) {
                    Future.delayed(const Duration(milliseconds: 250), () {
                      setDialogState(() {
                        firstPin = currentText;
                        currentText = '';
                      });
                    });
                  } else {
                    if (currentText == firstPin) {
                      Future.delayed(const Duration(milliseconds: 250), () {
                        Navigator.pop(context, currentText);
                      });
                    } else {
                      HapticFeedback.vibrate();
                      Future.delayed(const Duration(milliseconds: 250), () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرموز غير متطابقة، يرجى المحاولة مرة أخرى'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        setDialogState(() {
                          firstPin = '';
                          currentText = '';
                        });
                      });
                    }
                  }
                }
              }
            }

            void onDeletePressed() {
              if (currentText.isNotEmpty) {
                HapticFeedback.lightImpact();
                setDialogState(() {
                  currentText = currentText.substring(0, currentText.length - 1);
                });
              }
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                backgroundColor: AppTheme.backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        firstPin.isEmpty ? title : 'تأكيد رمز PIN',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        firstPin.isEmpty
                            ? 'أدخل رمزاً مكوناً من 4 أرقام لتأمين التطبيق'
                            : 'أعد إدخال الرمز لتأكيده',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isFilled = index < currentText.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled ? AppTheme.primaryColor : Colors.white,
                              border: Border.all(
                                color: isFilled ? AppTheme.primaryColor : AppTheme.dividerColor,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Num Pad Bento
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          if (index == 9) {
                            return TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context, null);
                              },
                              child: const Text('إلغاء', style: TextStyle(color: AppTheme.errorColor, fontSize: 14, fontWeight: FontWeight.bold)),
                            );
                          }
                          if (index == 11) {
                            return IconButton(
                              onPressed: onDeletePressed,
                              icon: const Icon(Icons.backspace_outlined, color: AppTheme.primaryColor),
                            );
                          }
                          final number = index == 10 ? '0' : (index + 1).toString();
                          return ElevatedButton(
                            onPressed: () => onNumberPressed(number),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.textPrimary,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5)),
                              ),
                            ),
                            child: Text(number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Dialog for PIN Verification (before changing PIN)
  Future<bool?> _showPinVerificationDialog(BuildContext context) async {
    String currentText = '';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void onNumberPressed(String number) async {
              if (currentText.length < 4) {
                HapticFeedback.lightImpact();
                setDialogState(() {
                  currentText += number;
                });

                if (currentText.length == 4) {
                  final isValid = await SecurityService.instance.verifyPin(currentText);
                  if (isValid) {
                    HapticFeedback.mediumImpact();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      Navigator.pop(context, true);
                    });
                  } else {
                    HapticFeedback.vibrate();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرمز المدخل غير صحيح، حاول مجدداً'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      setDialogState(() {
                        currentText = '';
                      });
                    });
                  }
                }
              }
            }

            void onDeletePressed() {
              if (currentText.isNotEmpty) {
                HapticFeedback.lightImpact();
                setDialogState(() {
                  currentText = currentText.substring(0, currentText.length - 1);
                });
              }
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: AppTheme.backgroundColor,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'تأكيد رمز PIN الحالي',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'أدخل رمز الـ PIN الحالي للمتابعة',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isFilled = index < currentText.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled ? AppTheme.primaryColor : Colors.white,
                              border: Border.all(
                                color: isFilled ? AppTheme.primaryColor : AppTheme.dividerColor,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Num Pad Bento
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          if (index == 9) {
                            return TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context, false);
                              },
                              child: const Text('إلغاء', style: TextStyle(color: AppTheme.errorColor, fontSize: 14, fontWeight: FontWeight.bold)),
                            );
                          }
                          if (index == 11) {
                            return IconButton(
                              onPressed: onDeletePressed,
                              icon: const Icon(Icons.backspace_outlined, color: AppTheme.primaryColor),
                            );
                          }
                          final number = index == 10 ? '0' : (index + 1).toString();
                          return ElevatedButton(
                            onPressed: () => onNumberPressed(number),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.textPrimary,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5)),
                              ),
                            ),
                            child: Text(number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
