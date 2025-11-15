import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/aws_credentials_service.dart';
import '../services/backend_service.dart';
import 'credentials_setup_screen.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasCredentials = false;
  bool _loading = true;
  String? _region;
  String _version = 'Loading...';
  String _osName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadCredentialStatus();
    _loadVersionInfo();
  }

  Future<void> _loadCredentialStatus() async {
    setState(() => _loading = true);
    try {
      final hasCredentials = await AWSCredentialsService.hasCredentials();
      if (hasCredentials) {
        final creds = await AWSCredentialsService.getCredentials();
        setState(() {
          _hasCredentials = true;
          _region = creds['region'];
        });
      } else {
        setState(() => _hasCredentials = false);
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadVersionInfo() async {
    try {
      final response = await http.get(
        Uri.parse('${BackendService.baseUrl}/api/version'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _version = data['version'] ?? 'Unknown';
          _osName = data['os_name'] ?? 'Unknown';
        });
      }
    } catch (e) {
      debugPrint('Error loading version: $e');
      setState(() {
        _version = '1.0.0';
        _osName = 'Unknown';
      });
    }
  }

  Future<void> _updateCredentials() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CredentialsSetupScreen(),
      ),
    );
    
    if (result == true || mounted) {
      _loadCredentialStatus();
    }
  }

  Future<void> _deleteCredentials() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credentials'),
        content: const Text(
          'Are you sure you want to delete your AWS credentials? '
          'You will need to re-enter them to use AWS services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AWSCredentialsService.deleteCredentials();
        setState(() {
          _hasCredentials = false;
          _region = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Credentials deleted'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete credentials: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // AWS Credentials Section
                _buildSectionHeader('AWS Credentials'),
                const SizedBox(height: 16),
                _buildCredentialsCard(),
                
                const SizedBox(height: 32),
                
                // About Section
                _buildSectionHeader('About'),
                const SizedBox(height: 16),
                _buildAboutCard(),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _hasCredentials
                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                      : AppTheme.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _hasCredentials ? Icons.check_circle : Icons.warning_amber,
                  color: _hasCredentials
                      ? AppTheme.successGreen
                      : AppTheme.warningAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasCredentials ? 'Credentials Configured' : 'No Credentials',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hasCredentials
                          ? 'Region: ${_region ?? 'Unknown'}'
                          : 'Configure your AWS credentials',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_hasCredentials) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _updateCredentials,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Update'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryPurple,
                      side: BorderSide(color: AppTheme.primaryPurple),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleteCredentials,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(color: AppTheme.errorRed),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateCredentials,
                icon: const Icon(Icons.add),
                label: const Text('Add Credentials'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.primaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AWS Manager',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version $_version',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.computer, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                _osName,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Manage your AWS infrastructure with ease',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
