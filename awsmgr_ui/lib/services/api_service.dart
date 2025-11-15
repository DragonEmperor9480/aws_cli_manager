import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/s3_browser_screen.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  // IAM Users
  static Future<List<dynamic>> listIAMUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/iam/users'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['users'] ?? [];
    }
    throw Exception('Failed to load users');
  }

  static Future<void> createIAMUser(String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/iam/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create user');
    }
  }

  static Future<Map<String, dynamic>> checkUserDependencies(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/iam/users/$username/dependencies'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to check dependencies');
  }

  static Future<void> deleteIAMUser(String username, {bool force = false}) async {
    final url = force 
        ? '$baseUrl/iam/users/$username?force=true'
        : '$baseUrl/iam/users/$username';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  // IAM Groups
  static Future<List<dynamic>> listIAMGroups() async {
    final response = await http.get(Uri.parse('$baseUrl/iam/groups'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['groups'] ?? [];
    }
    throw Exception('Failed to load groups');
  }

  static Future<void> createIAMGroup(String groupname) async {
    final response = await http.post(
      Uri.parse('$baseUrl/iam/groups'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'groupname': groupname}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create group');
    }
  }

  // S3 Buckets
  static Future<String> listS3Buckets() async {
    final response = await http.get(Uri.parse('$baseUrl/s3/buckets'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['buckets'] ?? '';
    }
    throw Exception('Failed to load buckets');
  }

  static Future<void> createS3Bucket(String bucketname) async {
    final response = await http.post(
      Uri.parse('$baseUrl/s3/buckets'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'bucketname': bucketname}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create bucket');
    }
  }

  static Future<void> deleteS3Bucket(String bucketname) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/s3/buckets/$bucketname'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete bucket');
    }
  }

  static Future<String> listS3Objects(String bucketname) async {
    final response = await http.get(
      Uri.parse('$baseUrl/s3/buckets/$bucketname/objects'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['objects'] ?? '';
    }
    throw Exception('Failed to load objects');
  }

  static Future<String> getBucketVersioning(String bucketname) async {
    final response = await http.get(
      Uri.parse('$baseUrl/s3/buckets/$bucketname/versioning'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] ?? '';
    }
    throw Exception('Failed to get versioning status');
  }

  static Future<List<int>> downloadS3Object(
    String bucketname,
    String objectkey, {
    Function(int received, int total)? onProgress,
  }) async {
    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/s3/buckets/$bucketname/objects/$objectkey'),
    );

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to download object');
    }

    final contentLength = response.contentLength ?? 0;
    final bytes = <int>[];
    int received = 0;

    await for (var chunk in response.stream) {
      bytes.addAll(chunk);
      received += chunk.length;
      onProgress?.call(received, contentLength);
    }

    return bytes;
  }

  static Future<List<S3Item>> listS3ItemsWithPrefix(String bucketname, String prefix) async {
    final uri = Uri.parse('$baseUrl/s3/buckets/$bucketname/items').replace(
      queryParameters: {'prefix': prefix},
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'];
      if (items == null) {
        return [];
      }
      return (items as List).map((item) => S3Item.fromJson(item)).toList();
    }
    throw Exception('Failed to load items');
  }

  static Future<void> uploadS3Object(String bucketname, String key, dynamic file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/s3/buckets/$bucketname/upload'),
    );
    request.fields['key'] = key;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    
    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload file');
    }
  }

  static Future<void> deleteS3Object(String bucketname, String objectkey) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/s3/buckets/$bucketname/objects/$objectkey'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete object');
    }
  }

  static Future<void> createS3Folder(String bucketname, String folderPath) async {
    final response = await http.post(
      Uri.parse('$baseUrl/s3/buckets/$bucketname/folder'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'folder_path': folderPath}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create folder');
    }
  }

  // Settings
  static Future<Map<String, dynamic>?> getMFADevice() async {
    final response = await http.get(Uri.parse('$baseUrl/settings/mfa'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  static Future<void> saveMFADevice(String deviceName, String deviceArn) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings/mfa'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'device_name': deviceName,
        'device_arn': deviceArn,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save MFA device');
    }
  }

  // AWS Configuration
  static Future<Map<String, dynamic>> getAWSConfig() async {
    final response = await http.get(Uri.parse('$baseUrl/aws/config'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get AWS config');
  }

  static Future<void> configureAWS(String accessKeyId, String secretAccessKey, String region) async {
    final response = await http.post(
      Uri.parse('$baseUrl/aws/config'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'access_key_id': accessKeyId,
        'secret_access_key': secretAccessKey,
        'region': region,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to configure AWS: ${response.body}');
    }
  }
}
