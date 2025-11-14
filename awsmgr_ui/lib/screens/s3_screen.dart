import 'package:flutter/material.dart';
import '../services/api_service.dart';

class S3Screen extends StatefulWidget {
  const S3Screen({super.key});

  @override
  State<S3Screen> createState() => _S3ScreenState();
}

class _S3ScreenState extends State<S3Screen> {
  String _buckets = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBuckets();
  }

  Future<void> _loadBuckets() async {
    setState(() => _loading = true);
    try {
      final buckets = await ApiService.listS3Buckets();
      setState(() => _buckets = buckets);
    } catch (e) {
      _showError('Failed to load buckets: $e');
    } finally {
      setState(() => _loading = false);
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

  Future<void> _createBucket() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create S3 Bucket'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Bucket Name',
            hintText: 'my-bucket-name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await ApiService.createS3Bucket(result);
        _showSuccess('Bucket created successfully');
        _loadBuckets();
      } catch (e) {
        _showError('Failed to create bucket: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S3 Management'),
      ),
      body: Column(
        children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'S3 Buckets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _createBucket,
                icon: const Icon(Icons.add),
                label: const Text('Create Bucket'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadBuckets,
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(_buckets.isEmpty ? 'No buckets found' : _buckets),
                ),
        ),
        ],
      ),
    );
  }
}
