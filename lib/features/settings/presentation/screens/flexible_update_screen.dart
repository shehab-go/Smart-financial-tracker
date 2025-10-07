import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class FlexibleUpdateScreen extends StatefulWidget {
  const FlexibleUpdateScreen({super.key});

  @override
  State<FlexibleUpdateScreen> createState() => _FlexibleUpdateScreenState();
}

class _FlexibleUpdateScreenState extends State<FlexibleUpdateScreen> {
  bool _flexibleUpdateAvailable = false;
  bool _isDownloading = false;
  String _statusMessage = 'Checking for updates...';

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }



  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      setState(() {
        _flexibleUpdateAvailable = updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
            updateInfo.flexibleUpdateAllowed;
        if (_flexibleUpdateAvailable) {
          _statusMessage = 'Update available! Tap to start download.';
        } else {
          _statusMessage = 'Your app is up to date.';
        }
      });

      if (_flexibleUpdateAvailable) {
        _startFlexibleUpdate();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking for updates: $e';
      });
    }
  }

  Future<void> _startFlexibleUpdate() async {
    try {
      setState(() {
        _isDownloading = true;
        _statusMessage = 'Downloading update...';
      });

      await InAppUpdate.startFlexibleUpdate();
      
      // After starting the flexible update, show the install snackbar
      // In a real scenario, you might want to periodically check the status
      // or use a timer to simulate the download completion
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _statusMessage = 'Update downloaded. Ready to install.';
        _isDownloading = false;
      });
      
      _showUpdateReadySnackBar();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting update: $e';
        _isDownloading = false;
      });
    }
  }

  void _showUpdateReadySnackBar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded. Ready to install!'),
        duration: const Duration(days: 1), // Persistent SnackBar
        action: SnackBarAction(
          label: 'INSTALL',
          onPressed: _completeFlexibleUpdate,
        ),
      ),
    );
  }

  Future<void> _completeFlexibleUpdate() async {
    try {
      // Hide the SnackBar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      setState(() {
        _statusMessage = 'Installing update...';
      });

      // Complete the flexible update installation
      await InAppUpdate.completeFlexibleUpdate();
      
      setState(() {
        _statusMessage = 'Update completed! App will restart.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error completing update: $e';
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Update'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isDownloading)
                const CircularProgressIndicator()
              else if (_flexibleUpdateAvailable)
                const Icon(
                  Icons.system_update,
                  size: 64,
                  color: Colors.blue,
                )
              else
                const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!_isDownloading && !_flexibleUpdateAvailable)
                ElevatedButton(
                  onPressed: _checkForUpdate,
                  child: const Text('Check Again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}