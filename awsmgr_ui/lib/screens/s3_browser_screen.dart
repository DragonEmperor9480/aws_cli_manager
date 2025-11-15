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

enum SortOption { nameAsc, nameDesc, sizeAsc, sizeDesc, dateAsc, dateDesc }

class _S3BrowserScreenState extends State<S3BrowserScreen> {
  List<S3Item> _items = [];
  List<S3Item> _filteredItems = [];
  String _currentPrefix = '';
  bool _loading = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.nameAsc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _breadcrumbs {
    if (_currentPrefix.isEmpty) return [];
    final parts = _currentPrefix.split('/').where((p) => p.isNotEmpty).toList();
    return parts;
  }

  void _navigateToBreadcrumb(int index) {
    final parts = _breadcrumbs;
    if (index < 0 || index >= parts.length) return;
    
    final newPath = parts.sublist(0, index + 1).join('/') + '/';
    setState(() => _currentPrefix = newPath);
    _loadItems();
  }

  void _filterAndSortItems() {
    List<S3Item> filtered = _items;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.nameAsc:
        filtered.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        });
        break;
      case SortOption.nameDesc:
        filtered.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return b.displayName.toLowerCase().compareTo(a.displayName.toLowerCase());
        });
        break;
      case SortOption.sizeAsc:
        filtered.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return a.size.compareTo(b.size);
        });
        break;
      case SortOption.sizeDesc:
        filtered.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return b.size.compareTo(a.size);
        });
        break;
      case SortOption.dateAsc:
        filtered.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return a.lastModified.compareTo(b.lastModified);
        });
        break;
      case SortOption.dateDesc:
        filtered.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return b.lastModified.compareTo(a.lastModified);
        });
        break;
    }

    setState(() => _filteredItems = filtered);
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.listS3ItemsWithPrefix(
        widget.bucketName,
        _currentPrefix,
      );
      setState(() {
        _items = items;
        _searchQuery = '';
        _searchController.clear();
      });
      _filterAndSortItems();
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

  Widget _buildBreadcrumbs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() => _currentPrefix = '');
              _loadItems();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _currentPrefix.isEmpty 
                    ? AppTheme.s3Color.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home,
                    size: 16,
                    color: _currentPrefix.isEmpty 
                        ? AppTheme.s3Color 
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.bucketName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _currentPrefix.isEmpty 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      color: _currentPrefix.isEmpty 
                          ? AppTheme.s3Color 
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_breadcrumbs.isNotEmpty) ...[
            for (int i = 0; i < _breadcrumbs.length; i++) ...[
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
              InkWell(
                onTap: () => _navigateToBreadcrumb(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: i == _breadcrumbs.length - 1
                        ? AppTheme.s3Color.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _breadcrumbs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == _breadcrumbs.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i == _breadcrumbs.length - 1
                          ? AppTheme.s3Color
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(widget.bucketName),
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
            if (_currentPrefix.isNotEmpty || _breadcrumbs.isNotEmpty)
              _buildBreadcrumbs(),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.s3Color.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: AppTheme.s3Color.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.s3Color.withValues(alpha: 0.2),
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
                              '${_filteredItems.length} items${_searchQuery.isNotEmpty ? " (filtered from ${_items.length})" : ""}',
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search files and folders...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      _filterAndSortItems();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _filterAndSortItems();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<SortOption>(
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.sort, size: 20),
                        ),
                        tooltip: 'Sort by',
                        onSelected: (option) {
                          setState(() => _sortOption = option);
                          _filterAndSortItems();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: SortOption.nameAsc,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_by_alpha,
                                  size: 18,
                                  color: _sortOption == SortOption.nameAsc
                                      ? AppTheme.primaryPurple
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Name (A-Z)',
                                  style: TextStyle(
                                    fontWeight: _sortOption == SortOption.nameAsc
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: SortOption.nameDesc,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_by_alpha,
                                  size: 18,
                                  color: _sortOption == SortOption.nameDesc
                                      ? AppTheme.primaryPurple
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Name (Z-A)',
                                  style: TextStyle(
                                    fontWeight: _sortOption == SortOption.nameDesc
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: SortOption.sizeAsc,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  size: 18,
                                  color: _sortOption == SortOption.sizeAsc
                                      ? AppTheme.primaryPurple
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Size (Smallest)',
                                  style: TextStyle(
                                    fontWeight: _sortOption == SortOption.sizeAsc
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: SortOption.sizeDesc,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  size: 18,
                                  color: _sortOption == SortOption.sizeDesc
                                      ? AppTheme.primaryPurple
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Size (Largest)',
                                  style: TextStyle(
                                    fontWeight: _sortOption == SortOption.sizeDesc
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: SortOption.dateDesc,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: _sortOption == SortOption.dateDesc
                                      ? AppTheme.primaryPurple
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Date (Newest)',
                                  style: TextStyle(
                                    fontWeight: _sortOption == SortOption.dateDesc
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: SortOption.dateAsc,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: _sortOption == SortOption.dateAsc
                                      ? AppTheme.primaryPurple
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Date (Oldest)',
                                  style: TextStyle(
                                    fontWeight: _sortOption == SortOption.dateAsc
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingAnimation(message: 'Loading items...')
                  : _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty 
                                    ? Icons.search_off 
                                    : Icons.folder_open_outlined,
                                size: 80, 
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty 
                                    ? 'No matching items' 
                                    : 'No items found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty 
                                    ? 'Try a different search term' 
                                    : 'Upload files or create folders',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
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
                                          color: item.iconColor.withValues(alpha: 0.1),
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
                                                AppTheme.primaryPurple.withValues(alpha: 0.1),
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
                                              AppTheme.errorRed.withValues(alpha: 0.1),
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
