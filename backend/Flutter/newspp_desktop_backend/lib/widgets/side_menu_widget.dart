import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/models/screens.dart';
import 'package:newspp_desktop_backend/services/auth_service.dart';

class SideMenuWidget extends StatefulWidget {
  final List<ScreenItem> screens; // Pass screens
  final Function(String) onMenuSelected;
  const SideMenuWidget({
    super.key,
    required this.screens,
    required this.onMenuSelected,
  });

  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget> {
  String _activeMenu = "Dashboard";

  final authService = AuthService();
  Map<String, dynamic> adminData = {'name': 'John Doe'};

  bool hasPermission = true;

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    Map<String, dynamic> getAdminData = await authService.getAdminData();
    if (getAdminData['status']) {
      setState(() {
        adminData['name'] = getAdminData['name'];
        adminData['role'] = getAdminData['role'];
        hasPermission =
            getAdminData['role'] == 'EDITOR' || getAdminData['role'] == 'ADMIN';
        // adminData['name'] = getAdminData['name'];
        // adminData['name'] = getAdminData['name'];
      });
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return Colors.redAccent;
      case 'EDITOR':
        return Colors.blueAccent;
      case 'VIEWER':
        return Colors.grey;
      default:
        return Colors.black45;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF1E1F25),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard, color: Colors.yellow[600], size: 28),
              const SizedBox(width: 8),
              Text(
                "Business Unusual",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Profile Section
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey[700],
            child: Icon(Icons.person, size: 40, color: Colors.grey[300]),
          ),
          const SizedBox(height: 12),
          Text(
            adminData['name'],
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4), // Spacing between name and role
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(adminData['role']),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              adminData['role'] ?? '',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // TextButton(
          //   onPressed: () {},
          //   style: TextButton.styleFrom(
          //     backgroundColor: const Color(0xFF2A2B31),
          //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(6),
          //     ),
          //   ),
          //   child: Text(
          //     "Edit",
          //     style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          //   ),
          // ),
          const SizedBox(height: 30),
          // Menu Buttons
          // Dynamically build menu buttons from screens
          ...widget.screens
              .where((screenItem) {
                if (screenItem.title == 'Article') return false;
                if (!hasPermission && screenItem.title == 'New Article')
                  return false;
                return true;
              })
              .map((screenItem) {
                final label = screenItem.title;
                final icon = screenItem.icon;
                final isActive = _activeMenu == label;
                return _buildMenuButton(icon, label, isActive);
              }),

          const Spacer(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2A2B31) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[400],
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : Colors.grey[400],
            fontSize: 15,
          ),
        ),
        onTap: () {
          setState(() {
            _activeMenu = label; // Update UI
          });
          widget.onMenuSelected(label); // Notify main screen
        },
      ),
    );
  }
}
