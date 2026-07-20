import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class FinancialTrackerService {
  static const MethodChannel _methodChannel = MethodChannel('com.ramzi.debit_credit_app/financial_tracker');
  static const EventChannel _eventChannel = EventChannel('com.ramzi.debit_credit_app/financial_tracker_events');

  /// Request Android Notification Listener Permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final bool result = await _methodChannel.invokeMethod('requestNotificationPermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to request permission: '${e.message}'.");
      return false;
    }
  }

  /// Get all past transactions from Android's local DB
  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final String jsonString = await _methodChannel.invokeMethod('getAllTransactions');
      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<Map<String, dynamic>>();
    } on PlatformException catch (e) {
      print("Failed to get transactions: '${e.message}'.");
      return [];
    }
  }

  /// Mark a transaction as classified to hide it from the inbox
  static Future<bool> markAsClassified(String referenceId, String category) async {
    try {
      final bool result = await _methodChannel.invokeMethod('markAsClassified', {
        'referenceId': referenceId,
        'category': category,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to mark as classified: '${e.message}'.");
      return false;
    }
  }

  /// Stream of real-time transactions arriving via notifications
  static Stream<Map<String, dynamic>> get transactionStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return jsonDecode(event.toString()) as Map<String, dynamic>;
    });
  }
}
