import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/loading_animation.dart';

class IAMUserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const IAMUserProfileScreen({super.key, required this.user});

  @override
  State<IAMUserProfileScreen> createState() => _IAMUserProfileScreenState();
}

class _IAMUserProfileScreenState extends State<IAMUserProfileScreen> {
  Map<String, dynamic>? _dependencies;
  List<dynamic> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _loading = true);
    try {
      final username = widget.user['username'];
      final deps = await ApiService.checkUserDependencies(username);
      final groups = await ApiService.getUserGroups(username);
      
      setState(() {
        _dependencies = deps;
        _groups = groups;
      });
    } catch (e) {
      _showError('Failed to load user details: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
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

  @override
  Widget build(BuildContext context) {
    final username = widget.user['username'] ?? '';
    final userId = widget.user['user_id'] ?? '';
    final createDate = widget.user['create_date'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        elevation: 0,
      ),
      body: _loading
          ? const LoadingAnimation(message: 'Loading user details...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'IAM User',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User Info Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('User Information'),
                        const SizedBox(height: 12),
                        _buildInfoCard([
                          _buildInfoRow(
                            Icons.fingerprint,
                            'User ID',
                            userId,
                          ),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Created',
                            createDate,
                          ),
                          _buildInfoRow(
                            Icons.login,
                            'Login Profile',
                            _dependencies?['has_login_profile'] == true
                                ? 'Enabled'
                                : 'Disabled',
                            valueColor: _dependencies?['has_login_profile'] == true
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Groups Section
                        _buildSectionTitle('Groups (${_groups.length})'),
                        const SizedBox(height: 12),
                        if (_groups.isEmpty)
                          _buildEmptyState(
                            Icons.group_outlined,
                            'Not a member of any groups',
                          )
                        else
                          _buildInfoCard(
                            _groups.map((group) {
                              return _buildListItem(
                                Icons.group,
                                group['groupname'] ?? '',
                                subtitle: group['group_id'],
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),

                        // Access Keys Section
                        _buildSectionTitle(
                          'Access Keys (${(_dependencies?['access_keys'] as List?)?.length ?? 0})',
                        ),
                        const SizedBox(height: 12),
                        if ((_dependencies?['access_keys'] as List?)?.isEmpty ?? true)
                          _buildEmptyState(
                            Icons.vpn_key_outlined,
                            'No access keys',
                          )
                        else
                          _buildInfoCard(
                            (_dependencies!['access_keys'] as List).map((key) {
                              return _buildListItem(
                                Icons.vpn_key,
                                key.toString(),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),

                        // Managed Policies Section
                        _buildSectionTitle(
                          'Managed Policies (${(_dependencies?['managed_policies'] as List?)?.length ?? 0})',
                        ),
                        const SizedBox(height: 12),
                        if ((_dependencies?['managed_policies'] as List?)?.isEmpty ?? true)
                          _buildEmptyState(
                            Icons.policy_outlined,
                            'No managed policies attached',
                          )
                        else
                          _buildInfoCard(
                            (_dependencies!['managed_policies'] as List).map((policy) {
                              return _buildListItem(
                                Icons.policy,
                                policy.toString(),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),

                        // Inline Policies Section
                        _buildSectionTitle(
                          'Inline Policies (${(_dependencies?['inline_policies'] as List?)?.length ?? 0})',
                        ),
                        const SizedBox(height: 12),
                        if ((_dependencies?['inline_policies'] as List?)?.isEmpty ?? true)
                          _buildEmptyState(
                            Icons.description_outlined,
                            'No inline policies',
                          )
                        else
                          _buildInfoCard(
                            (_dependencies!['inline_policies'] as List).map((policy) {
                              return _buildListItem(
                                Icons.description,
                                policy.toString(),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
