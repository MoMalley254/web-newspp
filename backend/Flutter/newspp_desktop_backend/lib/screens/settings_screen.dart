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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  print('Create user');
                  if (_newEmailController.text.isEmpty ||
                      _newUsernameController.text.isEmpty ||
                      _newPasswordController.text.isEmpty) {
                    toastHelper.showWarningtoast('Please fill in all fields');
                  } else {
                    setState(() {
                      isLoading = true;
                    });
                    Map<String, dynamic> newAdminData = {
                      'name': _newUsernameController.text,
                      'email': _newEmailController.text,
                      'password': _newPasswordController.text,
                    };
                    bool createdUser = await authHelper.createNewAdmin(
                      newAdminData,
                    );

                    setState(() {
                      isLoading = false;
                    });
                    if (createdUser) {
                      Navigator.pop(context);
                    }
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
      // hasPermissions = role == 'ADMIN';
      hasPermissions = role == 'ADMIN' || role == 'EDITOR';
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
}
