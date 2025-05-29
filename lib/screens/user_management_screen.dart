import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  Future<void> _deleteUser(String userId) async {
    try {
      setState(() => _isLoading = true);
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete user from Firebase Auth (requires admin privileges)
      // Note: This requires Firebase Admin SDK or Cloud Functions
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editUser(String userId, Map<String, dynamic> userData) async {
    try {
      setState(() => _isLoading = true);
      
      await _firestore.collection('users').doc(userId).update(userData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(Map<String, dynamic> userData, String userId) {
    final nameController = TextEditingController(text: userData['name']);
    final phoneController = TextEditingController(text: userData['phone']);
    final villageController = TextEditingController(text: userData['village']);
    final roleController = TextEditingController(text: userData['role']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: villageController,
                decoration: InputDecoration(
                  labelText: 'Village',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: userData['role'],
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem(value: 'member', child: Text('Church Member')),
                  DropdownMenuItem(value: 'pastor', child: Text('Pastor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  roleController.text = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedData = {
                'name': nameController.text,
                'phone': phoneController.text,
                'village': villageController.text,
                'role': roleController.text,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              _editUser(userId, updatedData);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sort Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Name'),
              leading: Radio<String>(
                value: 'name',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortAscending = true;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Role'),
              leading: Radio<String>(
                value: 'role',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortAscending = true;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Village'),
              leading: Radio<String>(
                value: 'village',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortAscending = true;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterAndSortUsers(List<QueryDocumentSnapshot> users) {
    // Filter users based on search query
    var filteredUsers = users.where((doc) {
      final userData = doc.data() as Map<String, dynamic>;
      final name = userData['name']?.toString().toLowerCase() ?? '';
      final role = userData['role']?.toString().toLowerCase() ?? '';
      final village = userData['village']?.toString().toLowerCase() ?? '';
      final searchLower = _searchQuery.toLowerCase();
      
      return name.contains(searchLower) ||
          role.contains(searchLower) ||
          village.contains(searchLower);
    }).toList();

    // Sort users
    filteredUsers.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      
      var aValue = aData[_sortBy]?.toString().toLowerCase() ?? '';
      var bValue = bData[_sortBy]?.toString().toLowerCase() ?? '';
      
      if (_sortAscending) {
        return aValue.compareTo(bValue);
      } else {
        return bValue.compareTo(aValue);
      }
    });

    return filteredUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
        backgroundColor: Colors.orange[700],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              children: [
                Icon(Icons.group, color: Colors.orange[700]),
                SizedBox(width: 8),
                Text(
                  "Users",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[700],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found.'));
                }
                final users = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // Show a bottom sheet with more user info or actions
                        showModalBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.orange[700], size: 32),
                                    SizedBox(width: 12),
                                    Text(
                                      user['name'] ?? 'No Name',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown[800],
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            user['role'] == 'admin'
                                                ? Icons.verified_user
                                                : user['role'] == 'pastor'
                                                    ? Icons.mic
                                                    : Icons.people,
                                            color: Colors.orange[700],
                                            size: 18,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            (user['role'] ?? '').toString().toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.phone, color: Colors.green[700]),
                                    SizedBox(width: 8),
                                    Text(user['phone'] ?? 'N/A'),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.location_city, color: Colors.blue[700]),
                                    SizedBox(width: 8),
                                    Text(user['village'] ?? 'N/A'),
                                  ],
                                ),
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Tooltip(
                                      message: 'Edit User',
                                      child: IconButton(
                                        icon: Icon(Icons.edit, color: Colors.orange[700]),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showEditDialog(user, users[index].id);
                                        },
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Delete User',
                                      child: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Delete User'),
                                              content: Text('Are you sure you want to delete this user?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _deleteUser(users[index].id);
                                                    Navigator.pop(context);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.orange[700]),
                                  SizedBox(width: 8),
                                  Text(
                                    user['name'] ?? 'No Name',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[800],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          user['role'] == 'admin'
                                              ? Icons.verified_user
                                              : user['role'] == 'pastor'
                                                  ? Icons.mic
                                                  : Icons.people,
                                          color: Colors.orange[700],
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          (user['role'] ?? '').toString().toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, color: Colors.green[700], size: 18),
                                  SizedBox(width: 6),
                                  Text("${user['phone'] ?? 'N/A'}"),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_city, color: Colors.blue[700], size: 18),
                                  SizedBox(width: 6),
                                  Text("${user['village'] ?? 'N/A'}"),
                                ],
                              ),
                              // Add more fields as needed
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Tooltip(
                                    message: 'Edit User',
                                    child: IconButton(
                                      icon: Icon(Icons.edit, color: Colors.orange[700]),
                                      onPressed: () => _showEditDialog(user, users[index].id),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Delete User',
                                    child: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Delete User'),
                                            content: Text('Are you sure you want to delete this user?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  _deleteUser(users[index].id);
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 