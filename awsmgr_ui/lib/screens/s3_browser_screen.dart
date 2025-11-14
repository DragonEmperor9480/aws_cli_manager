import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/s3_service.dart';
import '../widgets/loading_animation.dart';
import '../widgets/progress_dialog.dart';
import '../theme/app_theme.dart';

class S3BrowserScreen extends StatefulWidget {
  final String bucketName;

  const S3BrowserScreen({super.key, required this.bucketName});

  @override
  State<S3BrowserScreen> createState() => _S3BrowserScreenState();
}

class S3Item {
  final String key;
  final int size;
  final String lastModified;
  final bool isFolder;

  S3Item({
    required this.key,
    required this.size,
    required this.lastModified,
    required this.isFolder,
  });

  factory S3Item.fromJson(Map<String, dynamic> json) {
    return S3Item(
      key: json['Key'] ?? '',
      size: json['Size'] ?? 0,
      lastModified: json['LastModified'] ?? '',
      isFolder: json['IsFolder'] ?? false,
    );
  }

  String get displayName {
    if (key.isEmpty) return '';
    final parts = key.split('/');
    if (isFolder) {
      return parts.length > 1 ? parts[parts.length - 2] : parts[0];
    }
    return parts.last;
  }

  String get formattedSize {
    if (isFolder) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData get icon {
    if (isFolder) return Icons.folder;
    
    final ext = key.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'json':
      case 'xml':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get iconColor {
    if (isFolder) return Colors.amber;
    
    final ext = key.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'zip':
      case 'rar':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple;
      case 'mp4':
      case 'avi':
        return Colors.blue;
      case 'mp3':
      case 'wav':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _S3BrowserScreenState extends State<S3BrowserScreen> {
  List<S3Item> _items = [];
  String _currentPrefix = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.listS3ItemsWithPrefix(
        widget.bucketName,
        _currentPrefix,
      );
      setState(() => _items = items);
    } catch (e) {
      _showError('Failed to load items: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _navigateToFolder(String folderKey) {
    setState(() => _currentPrefix = folderKey);
    _loadItems();
  }

  void _navigateBack() {
    if (_currentPrefix.isEmpty) return;
    
    final parts = _currentPrefix.split('/');
    parts.removeLast(); // Remove empty string after last /
    if (parts.isNotEmpty) {
      parts.removeLast(); // Remove current folder
      setState(() => _currentPrefix = parts.isEmpty ? '' : '${parts.join('/')}/');
    } else {
      setState(() => _currentPrefix = '');
    }
    _loadItems();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final fileSize = await file.length();

      // Create progress stream controller
      final progressController = StreamController<double>();

      // Show animated progress dialog with real progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AnimatedProgressDialog(
          title: 'Uploading File',
          message: '$fileName (${_formatBytes(fileSize)})',
          progressStream: progressController.stream,
        ),
      );

      await S3Service.uploadWithProgress(
        widget.bucketName,
        _currentPrefix + fileName,
        file,
        (sent, total) {
          if (total > 0) {
            progressController.add(sent / total);
          }
        },
      );

      // Close progress stream
      await progressController.close();

      // Hide progress dialog
      if (mounted) Navigator.of(context).pop();

      _showSuccess('Uploaded: $fileName');
      await _loadItems();
    } catch (e) {
      // Hide progress dialog if showing
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showError('Upload failed: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _downloadFile(S3Item item) async {
    // Create progress stream controller
    final progressController = StreamController<double>();

    // Show animated progress dialog with real progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedProgressDialog(
        title: 'Downloading File',
        message: '${item.displayName} (${item.formattedSize})',
        progressStream: progressController.stream,
      ),
    );

    try {
      final bytes = await S3Service.downloadWithProgress(
        widget.bucketName,
        item.key,
        (received, total) {
          if (total > 0) {
            progressController.add(received / total);
          }
        },
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access downloads folder');
      }

      final filePath = '${directory.path}/${item.displayName}';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Close progress stream
      await progressController.close();

      // Hide progress dialog
      if (mounted) Navigator.of(context).pop();

      _showSuccess('Downloaded: ${item.displayName}');
    } catch (e) {
      // Close progress stream
      await progressController.close();
      
      // Hide progress dialog if showing
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showError('Download failed: $e');
    }
  }

  Future<void> _deleteItem(S3Item item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Delete Item'),
          ],
        ),
        content: Text('Are you sure you want to delete "${item.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show animated progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AnimatedProgressDialog(
          title: 'Deleting Item',
          message: item.displayName,
        ),
      );

      try {
        await ApiService.deleteS3Object(widget.bucketName, item.key);

        // Hide progress dialog
        if (mounted) Navigator.of(context).pop();

        _showSuccess('Deleted: ${item.displayName}');
        await _loadItems();
      } catch (e) {
        // Hide progress dialog if showing
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _showError('Delete failed: $e');
      }
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder, color: AppTheme.s3Color),
            SizedBox(width: 8),
            Text('Create Folder'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Folder Name',
            hintText: 'my-folder',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.folder),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, controller.text),
            icon: const Icon(Icons.add),
            label: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Show animated progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AnimatedProgressDialog(
          title: 'Creating Folder',
          message: result,
        ),
      );

      try {
        await ApiService.createS3Folder(
          widget.bucketName,
          _currentPrefix + result,
        );

        // Hide progress dialog
        if (mounted) Navigator.of(context).pop();

        _showSuccess('Created folder: $result');
        await _loadItems();
      } catch (e) {
        // Hide progress dialog if showing
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _showError('Create folder failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.bucketName),
              if (_currentPrefix.isNotEmpty)
                Text(
                  '/$_currentPrefix',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          actions: [
            if (_currentPrefix.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: _navigateBack,
                tooltip: 'Go back',
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadItems,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.s3Color.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: AppTheme.s3Color.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.s3Color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_open, color: AppTheme.s3Color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'S3 Browser',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_items.length} items',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _uploadFile,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _createFolder,
                    icon: const Icon(Icons.create_new_folder, size: 18),
                    label: const Text('Folder'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingAnimation(message: 'Loading items...')
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_outlined,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No items found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload files or create folders',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: item.isFolder
                                    ? () => _navigateToFolder(item.key)
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: item.iconColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: item.iconColor,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                if (!item.isFolder) ...[
                                                  Icon(Icons.storage,
                                                      size: 12, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    item.formattedSize,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                ],
                                                if (item.lastModified.isNotEmpty) ...[
                                                  Icon(Icons.access_time,
                                                      size: 12, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      item.lastModified,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!item.isFolder) ...[
                                        IconButton(
                                          icon: const Icon(Icons.download),
                                          color: AppTheme.primaryPurple,
                                          tooltip: 'Download',
                                          onPressed: () => _downloadFile(item),
                                          style: IconButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryPurple.withOpacity(0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: AppTheme.errorRed,
                                        tooltip: 'Delete',
                                        onPressed: () => _deleteItem(item),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.errorRed.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      if (item.isFolder) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
    );
  }
}
