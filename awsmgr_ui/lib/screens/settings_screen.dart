import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _deviceNameController = TextEditingController();
  final _deviceArnController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMFADevice();
  }

  Future<void> _loadMFADevice() async {
    setState(() => _loading = true);
    try {
      final device = await ApiService.getMFADevice();
      if (device != null) {
        _deviceNameController.text = device['device_name'] ?? '';
        _deviceArnController.text = device['device_arn'] ?? '';
      }
    } catch (e) {
      // No device configured yet
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveMFADevice() async {
    if (_deviceNameController.text.isEmpty || _deviceArnController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      await ApiService.saveMFADevice(
        _deviceNameController.text,
        _deviceArnController.text,
      );
      _showSuccess('MFA device saved successfully');
    } catch (e) {
      _showError('Failed to save: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MFA Device Configuration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    hintText: 'My Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _deviceArnController,
                  decoration: const InputDecoration(
                    labelText: 'Device ARN',
                    hintText: 'arn:aws:iam::123456789012:mfa/user',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveMFADevice,
                    child: const Text('Save MFA Device'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceArnController.dispose();
    super.dispose();
  }
}
