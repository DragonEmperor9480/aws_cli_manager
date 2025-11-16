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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );

    if (result != null && result['username'] != null) {
      setState(() => _operationInProgress = true);
      try {
        await ApiService.createIAMUser(
          result['username'],
          password: result['password'],
          requireReset: result['require_reset'] ?? false,
        );
        
        if (result['password'] != null && result['password'].isNotEmpty) {
          _showSuccess('User "${result['username']}" created with password');
        } else {
          _showSuccess('User "${result['username']}" created successfully');
        }
        await _loadData();
      } catch (e) {
        _showError('Failed to create user: $e');
      } finally {
        setState(() => _operationInProgress = false);
      }
    }
  }

  Future<void> _createMultipleUsers() async {
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => const BatchCreateUsersDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _operationInProgress = true);
      try {
        final response = await ApiService.createMultipleIAMUsers(result);
        
        final successCount = response['success_count'] ?? 0;
        final failureCount = response['failure_count'] ?? 0;
        final results = response['results'] as List;
        
        // Show detailed results dialog
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => BatchResultsDialog(
              successCount: successCount,
              failureCount: failureCount,
              results: results,
            ),
          );
        }
        
        await _loadData();
      } catch (e) {
        _showError('Failed to create users: $e');
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
              ElevatedButton.icon(
                onPressed: _createMultipleUsers,
                icon: const Icon(Icons.group_add),
                label: const Text('Batch Create'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
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


// Create User Dialog with password validation
class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _setPassword = false;
  bool _requireReset = false;
  bool _obscurePassword = true;
  
  // Password validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  
  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }
  
  bool get _isPasswordValid =>
      !_setPassword || (_hasMinLength && _hasUppercase && _hasLowercase && _hasNumber);
  
  bool get _canCreate =>
      _usernameController.text.isNotEmpty && _isPasswordValid;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Colors.blue),
          SizedBox(width: 8),
          Text('Create IAM User'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username field
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username *',
                hintText: 'Enter username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            
            // Set password checkbox
            CheckboxListTile(
              value: _setPassword,
              onChanged: (value) {
                setState(() {
                  _setPassword = value ?? false;
                  if (!_setPassword) {
                    _passwordController.clear();
                    _requireReset = false;
                  }
                });
              },
              title: const Text('Set initial password'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            // Password field (shown only if checkbox is checked)
            if (_setPassword) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Password requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password Requirements:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRequirement('At least 8 characters', _hasMinLength),
                    _buildRequirement('One uppercase letter (A-Z)', _hasUppercase),
                    _buildRequirement('One lowercase letter (a-z)', _hasLowercase),
                    _buildRequirement('One number (0-9)', _hasNumber),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Require reset checkbox
              CheckboxListTile(
                value: _requireReset,
                onChanged: (value) {
                  setState(() => _requireReset = value ?? false);
                },
                title: const Text('Require password reset at first login'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _canCreate
              ? () {
                  Navigator.pop(context, {
                    'username': _usernameController.text,
                    'password': _setPassword ? _passwordController.text : null,
                    'require_reset': _requireReset,
                  });
                }
              : null,
          icon: const Icon(Icons.add),
          label: const Text('Create'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : Colors.grey.shade600,
              fontWeight: met ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}


// Batch Create Users Dialog
class BatchCreateUsersDialog extends StatefulWidget {
  const BatchCreateUsersDialog({super.key});

  @override
  State<BatchCreateUsersDialog> createState() => _BatchCreateUsersDialogState();
}

class _BatchCreateUsersDialogState extends State<BatchCreateUsersDialog> {
  final List<_UserEntry> _users = [_UserEntry()];
  final _scrollController = ScrollController();

  void _addUser() {
    setState(() => _users.add(_UserEntry()));
    // Scroll to bottom after adding
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeUser(int index) {
    if (_users.length > 1) {
      setState(() => _users.removeAt(index));
    }
  }

  bool get _canCreate {
    return _users.every((user) => user.isValid);
  }

  List<Map<String, dynamic>> _getUsersData() {
    return _users.map((user) => user.toJson()).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var user in _users) {
      user.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.group_add, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Create Users',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Create multiple IAM users at once',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Users list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  return _UserEntryWidget(
                    key: ValueKey(_users[index]),
                    entry: _users[index],
                    index: index,
                    canRemove: _users.length > 1,
                    onRemove: () => _removeUser(index),
                    onChanged: () => setState(() {}),
                  );
                },
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _addUser,
                    icon: const Icon(Icons.add),
                    label: const Text('Add User'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_users.length} user(s)',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _canCreate
                        ? () => Navigator.pop(context, _getUsersData())
                        : null,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// User Entry Model
class _UserEntry {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool setPassword = false;
  bool requireReset = false;
  bool obscurePassword = true;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;

  bool get isValid {
    if (usernameController.text.isEmpty) return false;
    if (setPassword) {
      return _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;
    }
    return true;
  }

  void validatePassword() {
    final password = passwordController.text;
    _hasMinLength = password.length >= 8;
    _hasUppercase = password.contains(RegExp(r'[A-Z]'));
    _hasLowercase = password.contains(RegExp(r'[a-z]'));
    _hasNumber = password.contains(RegExp(r'[0-9]'));
  }

  Map<String, dynamic> toJson() {
    return {
      'username': usernameController.text,
      if (setPassword) 'password': passwordController.text,
      if (setPassword) 'require_reset': requireReset,
    };
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }
}

// User Entry Widget
class _UserEntryWidget extends StatefulWidget {
  final _UserEntry entry;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _UserEntryWidget({
    super.key,
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_UserEntryWidget> createState() => _UserEntryWidgetState();
}

class _UserEntryWidgetState extends State<_UserEntryWidget> {
  @override
  void initState() {
    super.initState();
    widget.entry.passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    widget.entry.validatePassword();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${widget.index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.entry.usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username *',
                      hintText: 'Enter username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person, size: 20),
                      isDense: true,
                    ),
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                if (widget.canRemove) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: widget.onRemove,
                    tooltip: 'Remove',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: widget.entry.setPassword,
              onChanged: (value) {
                setState(() {
                  widget.entry.setPassword = value ?? false;
                  if (!widget.entry.setPassword) {
                    widget.entry.passwordController.clear();
                    widget.entry.requireReset = false;
                  }
                });
                widget.onChanged();
              },
              title: const Text('Set password', style: TextStyle(fontSize: 14)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            if (widget.entry.setPassword) ...[
              TextField(
                controller: widget.entry.passwordController,
                obscureText: widget.entry.obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      widget.entry.obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        widget.entry.obscurePassword =
                            !widget.entry.obscurePassword;
                      });
                    },
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChip('8+ chars', widget.entry._hasMinLength),
                  _buildChip('A-Z', widget.entry._hasUppercase),
                  _buildChip('a-z', widget.entry._hasLowercase),
                  _buildChip('0-9', widget.entry._hasNumber),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: widget.entry.requireReset,
                onChanged: (value) {
                  setState(() => widget.entry.requireReset = value ?? false);
                  widget.onChanged();
                },
                title: const Text('Require reset', style: TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool met) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: met ? Colors.green : Colors.grey,
        ),
      ),
      avatar: Icon(
        met ? Icons.check_circle : Icons.cancel,
        size: 14,
        color: met ? Colors.green : Colors.grey,
      ),
      backgroundColor: met ? Colors.green.shade50 : Colors.grey.shade100,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

// Batch Results Dialog
class BatchResultsDialog extends StatelessWidget {
  final int successCount;
  final int failureCount;
  final List results;

  const BatchResultsDialog({
    super.key,
    required this.successCount,
    required this.failureCount,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            failureCount == 0 ? Icons.check_circle : Icons.info,
            color: failureCount == 0 ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          const Text('Batch Creation Results'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Total', results.length, Colors.blue),
                  _buildStat('Success', successCount, Colors.green),
                  if (failureCount > 0)
                    _buildStat('Failed', failureCount, Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Results list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  final success = result['Success'] ?? false;
                  final username = result['Username'] ?? '';
                  final error = result['Error'] ?? '';
                  
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      success ? Icons.check_circle : Icons.error,
                      color: success ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    title: Text(username),
                    subtitle: !success ? Text(error, style: const TextStyle(fontSize: 12)) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
