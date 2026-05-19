import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class SmartReminderDialog extends StatefulWidget {
  final AccountModel account;
  final double netBalance;
  final String currency;

  const SmartReminderDialog({
    super.key,
    required this.account,
    required this.netBalance,
    required this.currency,
  });

  @override
  State<SmartReminderDialog> createState() => _SmartReminderDialogState();
}

class _SmartReminderDialogState extends State<SmartReminderDialog> {
  int _selectedTemplateIndex = 0;
  bool _useWhatsApp = true;
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _messageFocusNode = FocusNode();
  bool _phoneHasFocus = false;
  bool _messageHasFocus = false;

  final List<Map<String, String>> _templates = [
    {
      'title': 'تذكير لطيف 🌸',
      'body': 'مرحباً يا [العضو]، أتمنى أن تكون بخير. أردت فقط تذكيرك بالرصيد المتبقي وقدره [المبلغ] [العملة]. يرجى إفادتي عند السداد. تحياتي لكم!',
    },
    {
      'title': 'تذكير رسمي 💼',
      'body': 'عزيزي العميل [العضو]، إشارةً إلى المعاملات المالية المشتركة بيننا، فإن صافي المبلغ المتبقي هو [المبلغ] [العملة]. يرجى تسوية الحساب في أقرب فرصة. وشكراً لتعاونكم الدائم.',
    },
    {
      'title': 'تذكير عاجل ⏳',
      'body': 'تنويه هام: الأخ [العضو]، يرجى العمل على تسديد الرصيد المتبقي وقدره [المبلغ] [العملة] في أقرب وقت ممكن. شكراً لتفهمكم وسرعة الاستجابة.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.account.phone ?? '');
    _updateMessage();
    
    _phoneFocusNode.addListener(() {
      setState(() {
        _phoneHasFocus = _phoneFocusNode.hasFocus;
      });
    });
    
    _messageFocusNode.addListener(() {
      setState(() {
        _messageHasFocus = _messageFocusNode.hasFocus;
      });
    });
  }

  void _updateMessage() {
    final template = _templates[_selectedTemplateIndex]['body']!;
    final formattedAmount = NumberFormat('#,##0').format(widget.netBalance.abs());
    final message = template
        .replaceAll('[العضو]', widget.account.name)
        .replaceAll('[المبلغ]', formattedAmount)
        .replaceAll('[العملة]', widget.currency);
    _messageController = TextEditingController(text: message);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    _phoneFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendReminder() async {
    String phone = _phoneController.text.trim();
    final message = Uri.encodeComponent(_messageController.text.trim());

    if (phone.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال رقم الهاتف أولاً لإرسال التذكير',
            style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!phone.startsWith('+') && !phone.startsWith('00')) {
      phone = phone.replaceAll(RegExp(r'\s+'), '');
    }

    Uri url;
    if (_useWhatsApp) {
      String whatsappPhone = phone;
      if (whatsappPhone.startsWith('+')) {
        whatsappPhone = whatsappPhone.substring(1);
      } else if (whatsappPhone.startsWith('00')) {
        whatsappPhone = whatsappPhone.substring(2);
      }
      url = Uri.parse('https://wa.me/$whatsappPhone?text=$message');
    } else {
      url = Uri.parse('sms:$phone?body=$message');
    }

    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        HapticFeedback.mediumImpact();
        if (mounted) Navigator.pop(context);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'عذراً، تعذر فتح التطبيق المطلوب: $e',
              style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color channelColor = _useWhatsApp ? Colors.green : AppTheme.primaryColor;
    
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: channelColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _useWhatsApp ? Icons.chat_rounded : Icons.sms_rounded,
                        color: channelColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'إرسال تذكير ذكي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content Area
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected Channel Switcher
                      const Text(
                        'قناة الإرسال',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _useWhatsApp = true);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _useWhatsApp ? Colors.green.shade50 : AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _useWhatsApp ? Colors.green : AppTheme.dividerColor.withOpacity(0.3),
                                    width: _useWhatsApp ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_outlined,
                                      color: _useWhatsApp ? Colors.green : Colors.grey.shade500,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'واتساب',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _useWhatsApp ? Colors.green.shade800 : Colors.grey.shade700,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _useWhatsApp = false);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_useWhatsApp ? AppTheme.primaryColor.withOpacity(0.08) : AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: !_useWhatsApp ? AppTheme.primaryColor : AppTheme.dividerColor.withOpacity(0.3),
                                    width: !_useWhatsApp ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sms_outlined,
                                      color: !_useWhatsApp ? AppTheme.primaryColor : Colors.grey.shade500,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'رسالة SMS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: !_useWhatsApp ? AppTheme.primaryColor : Colors.grey.shade700,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Phone Input Field
                      const Text(
                        'رقم الهاتف المستلم',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _phoneHasFocus 
                                ? AppTheme.primaryColor 
                                : AppTheme.dividerColor.withOpacity(0.3),
                            width: _phoneHasFocus ? 1.5 : 1,
                          ),
                          boxShadow: _phoneHasFocus
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: TextFormField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                          decoration: const InputDecoration(
                            hintText: 'مثال: 967770000000',
                            hintStyle: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
                            prefixIcon: Icon(Icons.phone_iphone_rounded, size: 18, color: AppTheme.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Templates Selection Chips
                      const Text(
                        'اختر أسلوب الرسالة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_templates.length, (index) {
                          final selected = _selectedTemplateIndex == index;
                          return ChoiceChip(
                            label: Text(
                              _templates[index]['title']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                            selected: selected,
                            selectedColor: channelColor,
                            backgroundColor: AppTheme.surfaceColor,
                            disabledColor: AppTheme.surfaceColor,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: selected ? channelColor : AppTheme.dividerColor.withOpacity(0.3),
                              ),
                            ),
                            onSelected: (val) {
                              if (val) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _selectedTemplateIndex = index;
                                  _updateMessage();
                                });
                              }
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Message Text Field
                      const Text(
                        'نص الرسالة (يمكنك تعديلها)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _messageHasFocus 
                                ? AppTheme.primaryColor 
                                : AppTheme.dividerColor.withOpacity(0.3),
                            width: _messageHasFocus ? 1.5 : 1,
                          ),
                          boxShadow: _messageHasFocus
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: TextFormField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          maxLines: 4,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppTheme.textPrimary,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Calendar due date integration Card (No-Line UI)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.dividerColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'حفظ موعد الاستحقاق بالتقويم',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppTheme.primaryColor,
                                          onPrimary: Colors.white,
                                          onSurface: AppTheme.textPrimary,
                                        ),
                                        textTheme: const TextTheme(
                                          labelLarge: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  final formattedAmount = NumberFormat('#,##0').format(widget.netBalance.abs());
                                  final event = Event(
                                    title: 'موعد استحقاق سداد: ${widget.account.name}',
                                    description: 'تذكير مستحق الدفع بمبلغ $formattedAmount ${widget.currency} في تطبيق الديون والائتمان.',
                                    location: 'الهاتف المحمول',
                                    startDate: picked,
                                    endDate: picked.add(const Duration(hours: 2)),
                                    allDay: false,
                                    iosParams: const IOSParams(
                                      reminder: Duration(minutes: 30),
                                    ),
                                    androidParams: const AndroidParams(),
                                  );
                                  await Add2Calendar.addEvent2Cal(event);
                                  HapticFeedback.mediumImpact();
                                }
                              },
                              icon: Icon(Icons.calendar_month_rounded, size: 16, color: channelColor),
                              label: Text(
                                'إضافة للتقويم 📅',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold, 
                                  color: channelColor,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          backgroundColor: Colors.grey.shade50,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _sendReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: channelColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _useWhatsApp ? 'إرسال واتساب' : 'إرسال رسالة SMS',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
