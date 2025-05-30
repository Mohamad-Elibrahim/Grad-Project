import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RateService extends StatefulWidget {
  final int userId;
  const RateService({super.key, required this.userId});

  @override
  State<RateService> createState() => _RateServiceState();
}

class _RateServiceState extends State<RateService> {
  List<Map<String, dynamic>> _completedServices = [];
  bool _isLoading = true;
  final Map<int, int> _ratings = {};
  final Map<int, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchCompletedServices();
  }

  Future<void> _fetchCompletedServices() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/clinic_api/get_completed_services.php?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _completedServices = List<Map<String, dynamic>>.from(data['services']);
            // Initialize controllers and ratings
            for (var service in _completedServices) {
              _commentControllers[service['ServiceID']] = TextEditingController();
              _ratings[service['ServiceID']] = 0;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching services: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRating(int serviceId) async {
    final rating = _ratings[serviceId];
    final comment = _commentControllers[serviceId]?.text ?? '';

    if (rating == null || rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating between 1-5')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/clinic_api/submit_rating.php'),
        body: json.encode({
          'user_id': widget.userId,
          'service_id': serviceId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!')),
        );
        // Remove the rated service from the list
        setState(() {
          _completedServices.removeWhere((s) => s['ServiceID'] == serviceId);
        });
      }
    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

  Widget _buildRatingStars(int serviceId, int rating) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _ratings[serviceId] = index + 1;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Completed Services')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedServices.isEmpty
          ? const Center(child: Text('You haven\'t had any sessions yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedServices.length,
        itemBuilder: (context, index) {
          final service = _completedServices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['Name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(service['Description'] ?? ''),
                  const SizedBox(height: 16),
                  _buildRatingStars(service['ServiceID'], _ratings[service['ServiceID']] ?? 0),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentControllers[service['ServiceID']],
                    decoration: const InputDecoration(
                      labelText: 'Add a comment (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _submitRating(service['ServiceID']),
                    child: const Text('Submit Rating'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    _commentControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}