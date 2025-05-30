import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:calendar_events/calendar_events.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
class Services extends StatefulWidget {
  const Services({super.key});

  @override
  State<Services> createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  final _storage = const FlutterSecureStorage();
  final _locationController = TextEditingController();
  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _specializationOptions = [
    'Orthopedic PT',
    'Neurological PT',
    'Sports PT',
    'Pediatric PT',
    'Manual Therapy',
    'Therapeutic Massage',
    'General PT'
  ];

  List<dynamic> _services = [];
  final Map<int, List<Map<String, dynamic>>> _technicianSchedules = {};
  bool _isLoading = true;
  String? _selectedGender;
  String? _selectedSpecialization;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;


  @override
  void initState() {
    super.initState();
    _fetchServices();
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
  }
  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('http://10.0.2.2/clinic_api/get_services.php').replace(
        queryParameters: {
          if (_selectedGender != null) 'gender': _selectedGender,
          if (_selectedSpecialization != null) 'specialization': _selectedSpecialization,
        },
      );
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _services = data['services'];
          _isLoading = false;
        });

      } else {
        throw Exception(data['error'] ?? 'Failed to load services');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(int technicianId) async {
    final slots = await _fetchTechnicianSchedule(technicianId);
    _technicianSchedules[technicianId] = slots;
    setState(() {});

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTechnicianSchedule(int technicianId) async {
    final uri = Uri.parse('http://10.0.2.2/clinic_api/get_technician_schedule.php?technician_id=$technicianId');
    final response = await http.get(uri);
    final data = jsonDecode(response.body);
    print('Technician schedule response: $data');

    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['schedule']);

    } else {
      return [];
    }
  }

  Future<void> _bookService(int serviceId, int technicianId) async {
    if (_locationController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final response = await http.post(
      Uri.parse('http://10.0.2.2/clinic_api/book_service.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'technician_id': technicianId,
        'location': _locationController.text.trim(),
        'datetime': appointmentDateTime.toIso8601String(),
      }),
    );

    final data = jsonDecode(response.body);
    if (data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Booking successful.')),
      );
      _locationController.clear();
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${data['error']}')),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Services'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                decoration: const InputDecoration(labelText: 'Specialization'),
                items: _specializationOptions.map((spec) {
                  return DropdownMenuItem(
                    value: spec,
                    child: Text(spec),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSpecialization = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchServices();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
          ? const Center(child: Text('No services available.'))
          : ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          final technicianId =service['technician_id'] ;

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(service['description'] ?? ''),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    service['averageRating'].toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${service['ratingCount']} reviews)',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectDate,
                          child: Text(_selectedDate == null
                              ? 'Select Date'
                              : DateFormat('MMM d, yyyy').format(_selectedDate!)),
                        ),
                      ),

              const SizedBox(width: 8),

                      Expanded(

                        child: ElevatedButton(
                            onPressed: () => _selectTime(technicianId),
                          child: Text(_selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _bookService(service['id'], technicianId),
                    child: const Text('Book Service'),
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
