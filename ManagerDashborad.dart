import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class MDashboardScreen extends StatelessWidget {
  const MDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildActionCard(
              icon: FontAwesomeIcons.solidNoteSticky, // Service icon
              label: "Post New Service",
              onTap: () => Navigator.pushNamed(context, '/PostSer'),
            ),
            _buildActionCard(
              icon: FontAwesomeIcons.userGear, // Technician icon
              label: "Add Technician",
              onTap: () => Navigator.pushNamed(context, '/AddTech'),
            ),
            _buildActionCard(
              icon: FontAwesomeIcons.calendarMinus, // Schedule icon
              label: "Service Ratings",
              onTap: () => Navigator.pushNamed(context, '/Ratings'),
            ),
            _buildActionCard(
              icon: FontAwesomeIcons.userXmark, // Delete icon
              label: "Delete Accounts",
              onTap: () => Navigator.pushNamed(context, '/delete'),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 40, color: Colors.blue), // Using FaIcon
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}