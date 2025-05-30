import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeleteAccounts extends StatefulWidget {
  const DeleteAccounts({super.key});

  @override
  _DeleteAccountsState createState() => _DeleteAccountsState();
}

class _DeleteAccountsState extends State<DeleteAccounts> {

  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedUser;
  Timer? _debounceTimer;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _selectedUser = null;
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        _searchUsers();
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _searchUsers() async {
    setState(() => _isSearching = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/clinic_api/search_users.php'),
        body: {'email': _searchController.text.trim()},
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _searchResults = data['users'];
          _isSearching = false;
        });
      } else {
        throw Exception(data['error'] ?? 'Failed to search users');
      }
    } catch (e) {
      setState(() => _isSearching = false);
      _showError('Search error: ${e.toString()}');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (_selectedUser == null) {
      _showError('Please select a user first');
      return;
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'This will permanently delete ${_selectedUser!['Name']}\'s account (${_selectedUser!['Email']}). Continue?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUserAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserAccount() async {
    if (_selectedUser == null) return;

    try {
      final token = await _storage.read(key: 'auth_token') ?? '';
      final response = await http.post(
        Uri.parse('http://10.0.2.2/clinic_api/delete_user.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': _selectedUser!['UserID']}),
      );

      // First check if response is valid JSON
      final responseBody = response.body;
      debugPrint('Response body: $responseBody');

      try {
        final data = jsonDecode(responseBody);
        if (response.statusCode == 200 && data['success'] == true) {
          _showSuccess('User deleted successfully!');
          _resetForm();
        } else {
          throw Exception(data['error'] ?? 'Deletion failed');
        }
      } catch (e) {
        // If JSON parsing fails, show the raw response
        throw Exception('Invalid response: $responseBody');
      }
    } catch (e) {
      _showError('Error: ${e.toString().replaceAll('Exception: ', '')}');
      debugPrint('Error details: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete User Accounts'),
        actions: [
          if (_selectedUser != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _resetForm,
              tooltip: 'Reset Form',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Section
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by email',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Search Results
            if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        title: Text(user['Name']),
                        subtitle: Text(user['Email']),
                        trailing: _selectedUser?['UserID'] == user['UserID']
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () => setState(() => _selectedUser = user),
                      ),
                    );
                  },
                ),
              ),

            // Selected User Card
            if (_selectedUser != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              _selectedUser!['Name'][0],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedUser!['Name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _selectedUser!['Email'],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _confirmDelete(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}