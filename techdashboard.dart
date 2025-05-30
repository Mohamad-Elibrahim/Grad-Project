import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Techdashboard extends StatefulWidget {
  final int technicianId;

  const Techdashboard({Key? key, required this.technicianId}) : super(key: key);

  @override
  _TechdashboardState createState() => _TechdashboardState();
}

class _TechdashboardState extends State<Techdashboard> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Timer? _timer;
  int _lastNotificationId = 0;

  @override
  void initState() {
    super.initState();

    // Initialize notification plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initSettings);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    // Start polling
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {

      checkForNotifications();
    });

    // Check once on load
    checkForNotifications();
  }

  Future<void> checkForNotifications() async {
    try {

      final response = await http.get(Uri.parse(
        'http://10.0.2.2/clinic_api/notifications.php?user_id=${widget.technicianId}',
      ));

      if (response.statusCode == 200) {
        final List notifications = json.decode(response.body);

        for (var notif in notifications) {
          int id = notif['id'];
          String message = notif['message'];

          if (id > _lastNotificationId) {
            _lastNotificationId = id;
            showNotification(id, message);
          }
        }
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error checking notifications: $e");
    }
  }

  Future<void> showNotification(int id, String message) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'New Bookings',
      channelDescription: 'Channel for booking alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id,
      'New Appointment',
      message,
      platformDetails,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technician Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildActionCard(
              icon: FontAwesomeIcons.spa,
              label: "Confirm Appointments",
              onTap: () => Navigator.pushNamed(context, '/appo',arguments: {'technicianId': widget.technicianId},),
            ),
            _buildActionCard(
              icon: FontAwesomeIcons.rankingStar,
              label: "Services Ratings",
              onTap: () => Navigator.pushNamed(context, '/Ratings'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
