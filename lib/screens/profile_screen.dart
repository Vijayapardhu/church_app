import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../screens/user_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _churchController = TextEditingController();
  final _experienceController = TextEditingController();
  final _sermonCountController = TextEditingController();
  final _congregationSizeController = TextEditingController();
  final _specializationController = TextEditingController();
  final List<TextEditingController> _familyMemberControllers = [TextEditingController()];
  File? _profileImage;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _selectedRole;
  String? _profileImageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool _isPastor = false;

  // Pastor-specific fields
  List<String> _selectedSpecializations = [];
  List<String> _availableSpecializations = [
    'Marriage Counseling',
    'Youth Ministry',
    'Children\'s Ministry',
    'Worship Leading',
    'Biblical Teaching',
    'Community Outreach',
    'Missions',
    'Church Administration',
    'Pastoral Care',
    'Evangelism'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkPastorRole();
  }

  Future<void> _loadUserProfile() async {
      if (user != null) {
      final doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _villageController.text = data['village'] ?? '';
          _churchController.text = data['church'] ?? '';
          _experienceController.text = data['experience'] ?? '';
          _sermonCountController.text = data['sermonCount'] ?? '';
          _congregationSizeController.text = data['congregationSize'] ?? '';
          _specializationController.text = data['specialization'] ?? '';
          _selectedRole = data['role'];
          _profileImageUrl = data['profileImageUrl'];
          _selectedSpecializations = List<String>.from(data['specializations'] ?? []);
          if (data['familyMembers'] != null) {
            _familyMemberControllers.clear();
            for (var member in data['familyMembers']) {
              _familyMemberControllers.add(TextEditingController(text: member));
            }
          }
        });
        }
      }
  }

  Future<void> _checkPastorRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc['role'] == 'pastor') {
        setState(() {
          _isPastor = true;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final imageUrl = await storageService.pickAndUploadImage();
    if (imageUrl != null) {
      setState(() {
        _profileImageUrl = imageUrl;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

    try {
      final familyMembers = _familyMemberControllers
            .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList();

        final profileData = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'village': _villageController.text,
          'role': _selectedRole,
          'profileImageUrl': _profileImageUrl,
          'familyMembers': familyMembers,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_selectedRole == 'pastor') {
          profileData.addAll({
            'church': _churchController.text,
            'experience': _experienceController.text,
            'sermonCount': _sermonCountController.text,
            'congregationSize': _congregationSizeController.text,
            'specialization': _specializationController.text,
            'specializations': _selectedSpecializations,
          });
        }

        await _firestore.collection('users').doc(user!.uid).set(
          profileData,
          SetOptions(merge: true),
        );

        setState(() {
          _isEditing = false;
        });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
      );
    } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPastorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _churchController,
          decoration: InputDecoration(
            labelText: 'Church Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.orange[50],
            prefixIcon: Icon(Icons.church, color: Colors.orange[700]),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your church name';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _experienceController,
          decoration: InputDecoration(
            labelText: 'Years of Experience',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.orange[50],
            prefixIcon: Icon(Icons.timeline, color: Colors.orange[700]),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your experience';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _sermonCountController,
          decoration: InputDecoration(
            labelText: 'Number of Sermons',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.orange[50],
            prefixIcon: Icon(Icons.menu_book, color: Colors.orange[700]),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of sermons';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _congregationSizeController,
          decoration: InputDecoration(
            labelText: 'Congregation Size',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.orange[50],
            prefixIcon: Icon(Icons.people, color: Colors.orange[700]),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter congregation size';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        Text(
          'Areas of Specialization',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSpecializations.map((specialization) {
            final isSelected = _selectedSpecializations.contains(specialization);
            return FilterChip(
              label: Text(specialization),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSpecializations.add(specialization);
                  } else {
                    _selectedSpecializations.remove(specialization);
                  }
                });
              },
              backgroundColor: Colors.orange[50],
              selectedColor: Colors.orange[200],
              checkmarkColor: Colors.orange[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.orange[700] : Colors.brown[700],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoRow('Name', _nameController.text),
                _buildInfoRow('Phone', _phoneController.text),
                _buildInfoRow('Village', _villageController.text),
                _buildInfoRow('Role', _selectedRole?.toUpperCase() ?? ''),
                if (_selectedRole == 'pastor') ...[
                  _buildInfoRow('Church', _churchController.text),
                  _buildInfoRow('Experience', '${_experienceController.text} years'),
                  _buildInfoRow('Sermons', _sermonCountController.text),
                  _buildInfoRow('Congregation', _congregationSizeController.text),
                  if (_selectedSpecializations.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Areas of Specialization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSpecializations.map((specialization) {
                        return Chip(
                          label: Text(specialization),
                          backgroundColor: Colors.orange[100],
                          labelStyle: TextStyle(color: Colors.orange[700]),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        if (_familyMemberControllers.isNotEmpty) ...[
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  ..._familyMemberControllers.map((controller) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      controller.text,
                      style: TextStyle(fontSize: 16),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.orange[700],
        leading: _isPastor
            ? IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
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
                          ElevatedButton.icon(
                            icon: Icon(Icons.group, color: Colors.orange[700]),
                            label: Text('Manage Users', style: TextStyle(color: Colors.orange[700])),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[50],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserManagementScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : null,
        actions: [
            IconButton(
            icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            ),
        ],
      ),
      body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
              // Profile Image
              Stack(
                        children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange[700]!,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: _profileImageUrl != null
                          ? Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.orange[300],
                                );
                              },
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.orange[300],
                            ),
                    ),
                  ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        shape: BoxShape.circle,
                      ),
                                child: IconButton(
                                  icon: Icon(Icons.camera_alt, color: Colors.white),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                        ],
                      ),
              SizedBox(height: 24),
              if (_isPastor || _selectedRole == 'admin') ...[
                ElevatedButton.icon(
                  icon: Icon(Icons.system_update_alt, color: Colors.white),
                  label: Text('Upload New APK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _uploadNewApk,
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.announcement, color: Colors.white),
                  label: Text('Set Church Banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _setChurchBanner,
                    ),
                    SizedBox(height: 24),
              ],
              if (_isEditing) ...[
                // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      ),
                    filled: true,
                    fillColor: Colors.orange[50],
                    prefixIcon: Icon(Icons.person, color: Colors.orange[700]),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                    ),
                    SizedBox(height: 16),
                // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      ),
                    filled: true,
                    fillColor: Colors.orange[50],
                    prefixIcon: Icon(Icons.phone, color: Colors.orange[700]),
                  ),
                      keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                    ),
                    SizedBox(height: 16),
                // Village Field
                    TextFormField(
                      controller: _villageController,
                      decoration: InputDecoration(
                        labelText: 'Village',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      ),
                    filled: true,
                    fillColor: Colors.orange[50],
                    prefixIcon: Icon(Icons.location_on, color: Colors.orange[700]),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your village';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Role Dropdown
                if (_isPastor) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.work, color: Colors.orange[700]),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'member',
                          child: Text('Church Member'),
                        ),
                        DropdownMenuItem(
                          value: 'pastor',
                          child: Text('Pastor'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                    ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a role';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                if (_selectedRole == 'pastor') ...[
                  SizedBox(height: 16),
                  _buildPastorFields(),
                ],
                    SizedBox(height: 24),
                // Family Members
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Family Members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                    ),
                    if (_isPastor)
                      ElevatedButton.icon(
                        icon: Icon(Icons.group, color: Colors.orange[700]),
                        label: Text('Manage Users', style: TextStyle(color: Colors.orange[700])),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserManagementScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                    ),
                    SizedBox(height: 8),
                    ..._familyMemberControllers.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  labelText: 'Family Member ${entry.key + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.orange[50],
                            ),
                          ),
                        ),
                        if (entry.key > 0)
                              IconButton(
                                icon: Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _familyMemberControllers.removeAt(entry.key);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _familyMemberControllers.add(TextEditingController());
                          });
                        },
                  icon: Icon(Icons.add, color: Colors.orange[700]),
                  label: Text(
                    'Add Family Member',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                      ),
                SizedBox(height: 32),
                // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                          padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                        ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Save Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                      ),
              ] else
                _buildViewMode(),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _uploadNewApk() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['apk']);
      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        final file = File(result.files.single.path!);
        final fileName = 'latest.apk';
        final ref = FirebaseStorage.instance.ref().child('app_updates').child(fileName);
        final uploadTask = await ref.putFile(file);
        final apkUrl = await uploadTask.ref.getDownloadURL();
        // Optionally, get version info from user
        await FirebaseFirestore.instance.collection('app_updates').doc('latest').set({
          'url': apkUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('APK uploaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading APK: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setChurchBanner() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isLoading = true);
        final file = File(picked.path);
        final ref = FirebaseStorage.instance.ref().child('church_banner').child('banner.jpg');
        final uploadTask = await ref.putFile(file);
        final bannerUrl = await uploadTask.ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('church_banner').doc('current').set({
          'url': bannerUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banner uploaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading banner: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _churchController.dispose();
    _experienceController.dispose();
    _sermonCountController.dispose();
    _congregationSizeController.dispose();
    _specializationController.dispose();
    for (var controller in _familyMemberControllers) {
      controller.dispose();
    }
    super.dispose();
  }
} 