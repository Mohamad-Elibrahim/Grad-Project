import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Ratings extends StatefulWidget {
  const Ratings({super.key});

  @override
  State<Ratings> createState() => _RatingsState();
}

class _RatingsState extends State<Ratings> {
  List<dynamic> _services = [];

  Future<void> _fetchServices() async {
    try {
      final uri = Uri.parse('http://10.0.2.2/clinic_api/get_services.php');
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _services = data['services'];
        });
      } else {
        throw Exception(data['error'] ?? 'Failed to load services');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings'),
      ),
      body: ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          final average = service['averageRating']?.toDouble() ?? 0.0;
          final roundedAverage = (average * 2).round() / 2;
          final fullStars = roundedAverage.floor();
          final hasHalfStar = (roundedAverage - fullStars) >= 0.5;

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(service['description'] ?? ''),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (starIndex) {
                          if (starIndex < fullStars) {
                            return const Icon(Icons.star,
                                color: Colors.amber, size: 20);
                          } else if (hasHalfStar && starIndex == fullStars) {
                            return const Icon(Icons.star_half,
                                color: Colors.amber, size: 20);
                          } else {
                            return const Icon(Icons.star_border,
                                color: Colors.amber, size: 20);
                          }
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${average.toStringAsFixed(1)}',
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