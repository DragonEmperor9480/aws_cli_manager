import 'api_service.dart';

class EmailConfigService {
  static Future<void> saveEmailConfig({
    required String smtpHost,
    required int smtpPort,
    required String senderEmail,
    required String senderPass,
    required String senderName,
  }) async {
    await ApiService.saveEmailConfig(
      smtpHost: smtpHost,
      smtpPort: smtpPort,
      senderEmail: senderEmail,
      senderPass: senderPass,
      senderName: senderName,
    );
  }

  static Future<Map<String, dynamic>?> getEmailConfig() async {
    try {
      final config = await ApiService.getEmailConfig();
      return config;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasEmailConfig() async {
    try {
      final config = await ApiService.getEmailConfig();
      return config['configured'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> deleteEmailConfig() async {
    await ApiService.deleteEmailConfig();
  }
}
