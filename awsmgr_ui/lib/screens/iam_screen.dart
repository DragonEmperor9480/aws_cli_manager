import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/aws_config_dialog.dart';
import '../widgets/loading_animation.dart';

class IAMScreen extends StatefulWidget {
  const IAMScreen({super.key});

  @override
  State<IAMScreen> createState() => _IAMScreenState();
}

class _IAMScreenState extends State<IAMScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _users = [];
  List<dynamic> _groups = [];
  bool _loading = false;
  bool _operationInProgress = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final users = await ApiService.listIAMUsers();
      final groups = await ApiService.listIAMGroups();
      setState(() {
        _users = users;
        _groups = groups;
      });
    } catch (e) {
      _showError('Failed to load data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (message.contains('AWS credentials not configured')) {
      _showAWSConfigDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAWSConfigDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AWSConfigDialog(),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _createUser() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.blue),
            SizedBox(width: 8),
            Text('Create IAM User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              autofocus: true,
            ),
          ],
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
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _operationInProgress = true);
      try {
        await ApiService.createIAMUser(result);
        _showSuccess('User "$result" created successfully');
        await _loadData();
      } catch (e) {
        _showError('Failed to create user: $e');
      } finally {
        setState(() => _operationInProgress = false);
      }
    }
  }

  Future<void> _deleteUser(String username) async {
    // First check dependencies
    setState(() => _operationInProgress = true);
    late Map<String, dynamic> dependencies;
    
    try {
      dependencies = await ApiService.checkUserDependencies(username);
    } catch (e) {
      setState(() => _operationInProgress = false);
      _showError('Failed to check user dependencies: $e');
      return;
    }
    
    setState(() => _operationInProgress = false);

    final hasDeps = (dependencies['groups'] as List?)?.isNotEmpty == true ||
                    (dependencies['managed_policies'] as List?)?.isNotEmpty == true ||
                    (dependencies['inline_policies'] as List?)?.isNotEmpty == true ||
                    (dependencies['access_keys'] as List?)?.isNotEmpty == true ||
                    dependencies['has_login_profile'] == true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(hasDeps ? Icons.warning : Icons.delete, 
                 color: hasDeps ? Colors.orange : Colors.red),
            const SizedBox(width: 8),
            const Text('Delete User'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "$username"?'),
              const SizedBox(height: 8),
              if (hasDeps) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'User has dependencies:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if ((dependencies['groups'] as List?)?.isNotEmpty == true) ...[
                        const Text('Groups:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...(dependencies['groups'] as List).map((g) => Text('  • $g')),
                        const SizedBox(height: 4),
                      ],
                      if ((dependencies['managed_policies'] as List?)?.isNotEmpty == true) ...[
                        const Text('Managed Policies:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...(dependencies['managed_policies'] as List).map((p) => Text('  • $p')),
                        const SizedBox(height: 4),
                      ],
                      if ((dependencies['inline_policies'] as List?)?.isNotEmpty == true) ...[
                        const Text('Inline Policies:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...(dependencies['inline_policies'] as List).map((p) => Text('  • $p')),
                        const SizedBox(height: 4),
                      ],
                      if ((dependencies['access_keys'] as List?)?.isNotEmpty == true) ...[
                        const Text('Access Keys:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...(dependencies['access_keys'] as List).map((k) => Text('  • $k')),
                        const SizedBox(height: 4),
                      ],
                      if (dependencies['has_login_profile'] == true) ...[
                        const Text('• Has login profile', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'All dependencies will be removed automatically.',
                  style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: Text(hasDeps ? 'Remove All & Delete' : 'Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _operationInProgress = true);
      try {
        await ApiService.deleteIAMUser(username, force: hasDeps);
        _showSuccess('User "$username" deleted successfully');
        await _loadData();
      } catch (e) {
        _showError('Failed to delete user: $e');
      } finally {
        setState(() => _operationInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _operationInProgress,
      message: 'Processing...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IAM Management'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Users', icon: Icon(Icons.person)),
              Tab(text: 'Groups', icon: Icon(Icons.group)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUsersTab(),
            _buildGroupsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade100),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.people, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IAM Users',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${_users.length} users found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _createUser,
                icon: const Icon(Icons.add),
                label: const Text('Create User'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
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
              ? const LoadingAnimation(message: 'Loading users...')
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first IAM user',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _createUser,
                            icon: const Icon(Icons.add),
                            label: const Text('Create User'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              user['username'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.fingerprint,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      user['user_id'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (user['create_date'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Created: ${user['create_date']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              tooltip: 'Delete user',
                              onPressed: () => _deleteUser(user['username']),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.green.shade100),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.group, color: Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IAM Groups',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${_groups.length} groups found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
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
              ? const LoadingAnimation(message: 'Loading groups...')
              : _groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_outlined,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No groups found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.group,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              group['groupname'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.fingerprint,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      group['group_id'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
