import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostService extends StatefulWidget {
  const PostService({super.key});

  @override
  _PostServiceState createState() => _PostServiceState();
}

class _PostServiceState extends State<PostService> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int? _selectedTechnicianId;
  List<Map<String, dynamic>> _technicians = [];
  bool _isLoading = false;
  bool _fetchingTechnicians = true;

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _fetchTechnicians() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/clinic_api/get_technicians.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is! Map<String, dynamic>) {
          throw Exception('Invalid response format');
        }

        if (data['success'] == true) {
          setState(() {
            _technicians = List<Map<String, dynamic>>.from(data['technicians'] ?? [])
                .map((tech) => {
              'TechnicianID': int.tryParse(tech['TechnicianID'].toString()) ?? 0,
              'Name': tech['Name'] ?? 'Unnamed Technician'
            })
                .toList();
            _fetchingTechnicians = false;
          });

          if (_technicians.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No technicians available - cannot create service')),
            );
          }
        } else {
          throw Exception(data['error'] ?? 'Failed to load technicians');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _fetchingTechnicians = false;
      });
    }
  }

  Future<void> _postService() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTechnicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a technician')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/clinic_api/post_service.php'),
        body: {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'technician_id': _selectedTechnicianId.toString(),
        },
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service posted successfully!')),
        );
        // Clear the form
        _nameController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedTechnicianId = null;
        });
      } else {
        throw Exception(data['error'] ?? 'Failed to post service');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a New Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Service Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Assign Technician *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _fetchingTechnicians
                  ? const CircularProgressIndicator()
                  : _technicians.isEmpty
                  ? const Text(
                'No technicians available',
                style: TextStyle(color: Colors.red),
              )
                  : DropdownButtonFormField<int>(
                value: _selectedTechnicianId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  errorStyle: TextStyle(height: 0),
                ),
                items: _technicians.map((tech) {
                  return DropdownMenuItem<int>(
                    value: tech['TechnicianID'],
                    child: Text(tech['Name']),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Required' : null,
                onChanged: (value) {
                  setState(() {
                    _selectedTechnicianId = value;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _technicians.isEmpty ? null : _postService,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                    'Post Service',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}