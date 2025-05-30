import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:calendar_events/calendar_events.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
class TechnicianAppointmentPage extends StatefulWidget {

  final int technicianId;
  const TechnicianAppointmentPage({super.key, required this.technicianId});

  @override
  _TechnicianAppointmentPageState createState() => _TechnicianAppointmentPageState();
}

class _TechnicianAppointmentPageState extends State<TechnicianAppointmentPage> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }


  Future<bool> _addToCalendar({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    required String location,
  }) async {
    try {
      // For Android only
      if (Platform.isAndroid) {
        final status = await Permission.calendar.status;
        if (!status.isGranted) {
          await Permission.calendar.request();
        }

        if (!await Permission.calendar.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calendar permission denied')),
          );
          return false;
        }
      }

      final event = CalendarEvent(
        calendarId: '0',
        title: title,
        description: description,
        location: location,
        start: start,
        end: end,
      );

      final calendar = CalendarEvents();
      final success = await calendar.addEvent(event);
      if(success!=null &&success.trim()!=" " ){
      return true ;}
      else{
        return false ;}
    } catch (e) {
      print('Calendar Error: $e');
      return false;
    }
  }Future<void> fetchAppointments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = 'http://10.0.2.2/clinic_api/get_appointment.php?user_id=${widget.technicianId}';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          appointments = List<Map<String, dynamic>>.from(data['appointments']);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Failed to load appointments.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> confirmAppointment(int index) async {

    final appointment = appointments[index];

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/clinic_api/confirmAppointment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'request_id': appointment['RequestID'],
          'status': 'confirmed',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          appointments[index]['Status'] = 'confirmed';

        });
        final date = DateTime.parse(appointment['Date']);
        final timeParts = appointment['Time'].split(':');
        final startTime = DateTime.utc(
          date.year,
          date.month,
          date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        ).toLocal();
        final endTime = startTime.add(const Duration(hours: 1));// Convert to local time if needed

        // In confirmAppointment method:
        final calendarResult = await _addToCalendar(
          title: 'PT Session with ${appointment['TechnicianName']}',
          description: 'Physical Therapy Session',
          start: startTime,
          end: endTime,
          location: appointment['Location'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(calendarResult
                ? 'Appointment confirmed! Added to calendar'
                : 'Confirmed but calendar add failed'
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to confirm.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> cancelAppointment(int index) async {
    final appointment = appointments[index];
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for cancellation',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a cancellation reason')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Send cancel request with reason
      try {

        final response = await http.post(
          Uri.parse('http://10.0.2.2/clinic_api/cancelAppointment.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'request_id': appointment['RequestID'],
            'status': 'cancelled',
            'reason': result,
          }),

        );
        final data = json.decode(response.body);
         if (response.statusCode == 200 && data['success'] == true) {
          setState(() {
            appointments[index]['Status'] = 'cancelled';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled and user notified!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to cancel appointment.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return "--:--";
    final parts = timeStr.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute).format(context);
  }

  String _calculateEndTime(String? timeStr) {
    if (timeStr == null) return "--:--";
    final parts = timeStr.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: (hour + 1) % 24, minute: minute).format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technician Appointments')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : appointments.isEmpty
          ? const Center(child: Text('No pending appointments.'))
          : ListView.builder(

        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appt = appointments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(_formatDate(appt['Date']),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Time: ${_formatTime(appt['Time'])} - ${_calculateEndTime(appt['Time'])}"),
                  const SizedBox(height: 8),
                  Text("Status: ${appt['Status']}",
                      style: TextStyle(
                        color: appt['Status'] == 'confirmed'
                            ? Colors.green
                            : appt['Status'] == 'cancelled'
                            ? Colors.red
                            : Colors.orange,
                      )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: appt['Status'] == 'confirmed' || appt['Status'] == 'cancelled'
                            ? null
                            : () => confirmAppointment(index),
                        child: const Text('Confirm'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: appt['Status'] == 'confirmed' || appt['Status'] == 'cancelled'
                            ? null
                            : () => cancelAppointment(index),
                        child: const Text('Cancel'),
                      ),
                    ],

                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
