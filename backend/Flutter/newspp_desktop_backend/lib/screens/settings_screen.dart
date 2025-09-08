import 'package:flutter/material.dart';
import 'package:newspp_desktop_backend/screens/landing_screen.dart';
import 'package:newspp_desktop_backend/services/auth_service.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final toastHelper = ToastService();
  final authHelper = AuthService();

  bool hasPermissions = false;
  bool isLoading = false;

  final TextEditingController _newUsernameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  Future<void> _showChangePasswordDialog() async {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Change Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Current Password",
                  ),
                ),
                TextField(
                  controller: _newPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New Password"),
                ),
                TextField(
                  controller: _confirmPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm New Password",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (_newPassController.text != '' &&
                      _oldPasswordController.text != '' &&
                      _confirmPassController.text != '') {
                    if (_newPassController.text ==
                        _confirmPassController.text) {
                      setState(() {
                        isLoading = true;
                      });
                      Navigator.pop(context);

                      bool hasChangedPass = await authHelper.changePassword(
                        _oldPasswordController.text,
                        _newPassController.text,
                      );
                      if (hasChangedPass) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LandingScreen(),
                          ),
                        );
                      } else {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    } else {
                      toastHelper.showWarningtoast('Passwords don\'t match');
                    }
                  } else {
                    toastHelper.showWarningtoast('Please fill in all fields');
                  }
                },
                child: const Text("Change"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
    );
  }

  Future<void> _showCreateUserDialog() async {
    final List<String> _roles = ['ADMIN', 'EDITOR', 'VIEWER'];
    String _selectedRole = 'VIEWER'; // default role
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Create New User"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newEmailController,
                  decoration: const InputDecoration(labelText: "User email"),
                ),
                TextField(
                  controller: _newUsernameController,
                  decoration: const InputDecoration(labelText: "User name"),
                ),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items:
                      _roles.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                  decoration: const InputDecoration(labelText: 'Role'),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Validate input
                  if (_newEmailController.text.isEmpty ||
                      _newUsernameController.text.isEmpty ||
                      _newPasswordController.text.isEmpty) {
                    toastHelper.showWarningtoast('Please fill in all fields');
                    return;
                  }
                    Navigator.pop(context); // Close the dialog

                  setState(() {
                    isLoading = true;
                  });

                  // Prepare user data
                  Map<String, dynamic> newAdminData = {
                    'name': _newUsernameController.text.trim(),
                    'email': _newEmailController.text.trim(),
                    'password': _newPasswordController.text,
                    'role': _selectedRole,
                  };

                  // Try creating the user
                  bool createdUser = await authHelper.createNewAdmin(
                    newAdminData,
                  );

                  setState(() {
                    isLoading = false;
                  });

                  if (createdUser) {
                    toastHelper.showSuccesstoast('User created successfully');
                  } else {
                    toastHelper.showErrortoast('Failed to create user');
                  }
                },
                child: const Text("Create"),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    initPref();
  }

  Future<void> initPref() async {
    final prefs = await SharedPreferences.getInstance();
    String role = prefs.getString('adminRole') ?? '';
    setState(() {
      hasPermissions = role == 'ADMIN';
    });
  }

  @override
  void dispose() {
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    _oldPasswordController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildButtonTile(
              icon: Icons.lock,
              label: "Change Password",
              onTap: _showChangePasswordDialog,
            ),
            if (hasPermissions)
              _buildButtonTile(
                icon: Icons.person_add,
                label: "Create New User",
                onTap: _showCreateUserDialog,
              ),
            if (hasPermissions) buildAdmins(context),
          ],
        ),
        if (isLoading)
          Container(
            color: const Color.fromARGB(255, 236, 233, 233).withOpacity(0.7),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildButtonTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        color: Colors.white, // Button background color
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.black),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAdmins(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: authHelper.getAdmins(),
      builder: (
        BuildContext context,
        AsyncSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final response = snapshot.data;

        if (response == null || response['status'] != true) {
          // Handle failure (response might have a message field)
          final message = response?['error'] ?? 'Failed to load admins';
          return Center(child: Text('Error: $message'));
        }

        final List<dynamic> admins = response['admins'];

        if (admins.isEmpty) {
          return const Center(child: Text('No admins found.'));
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: Colors.white,
          ),
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Center(child: Text('Accounts', style: TextStyle(fontSize: 24))),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: admins.length,
                itemBuilder: (context, index) {
                  final admin = admins[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.admin_panel_settings),
                          title: Text(admin['name'] ?? 'No name'),
                          subtitle: Text(admin['email'] ?? 'No email'),
                          trailing: Text(admin['role'] ?? 'No role'),
                        ),
                        buildAccountButtons(context, admin),
                        const SizedBox(height: 10,),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildAccountButtons(BuildContext context, Map<String, dynamic> admin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Change Password Button
        ElevatedButton.icon(
          icon: const Icon(Icons.lock),
          label: const Text("Change Password"),
          onPressed: () => _showChangeAdminPasswordDialog(context, admin),
        ),

        // Update Role Button
        ElevatedButton.icon(
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text("Update Role"),
          onPressed: () => _showUpdateRoleDialog(context, admin),
        ),

        // Delete User Button
        ElevatedButton.icon(
          icon: const Icon(Icons.delete),
          label: const Text("Delete"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _showDeleteConfirmation(context, admin),
        ),
      ],
    );
  }

  Future<void> _showChangeAdminPasswordDialog(
    BuildContext context,
    Map<String, dynamic> admin,
  ) async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (passwordController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                final confirm = await _showFinalConfirmation(
                  context,
                  "Change this user's password?",
                );
                if (confirm) {
                  Navigator.pop(context); // Close password dialog
                  // Call loading and password update function
                  _setLoading(true);
                  await authHelper.updateAccount(
                    admin['id'],
                    'password',
                    passwordController.text,
                  );
                  _setLoading(false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUpdateRoleDialog(
    BuildContext context,
    Map<String, dynamic> admin,
  ) async {
    String selectedRole = admin['role']; 

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Role'),
          content: DropdownButton<String>(
            isExpanded: true,
            value: selectedRole,
            items:
                ['ADMIN', 'USER', 'EDITOR'].map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                selectedRole = value;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () async {
                final confirm = await _showFinalConfirmation(
                  context,
                  "Update role to $selectedRole?",
                );
                if (confirm) {
                  Navigator.pop(context); // Close role dialog
                  _setLoading(true);
                  await authHelper.updateAccount(
                    admin['id'],
                    'role',
                    selectedRole,
                  );
                  _setLoading(false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> admin,
  ) async {
    final confirm = await _showFinalConfirmation(
      context,
      "Are you sure you want to delete this user?",
    );
    if (confirm) {
      _setLoading(true);
      await authHelper.deleteAcount(admin['id']);
      _setLoading(false);
    }
  }

  Future<bool> _showFinalConfirmation(
    BuildContext context,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Action'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }
}
