import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

 final _formKey = GlobalKey<FormState>();
  bool _isEmailLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Email validation regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone validation (basic)
  bool _isValidPhone(String phone) {
    return phone.length >= 8; // Adjust based on your requirements
  }


  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final uri = Uri.parse('http://10.0.2.2/clinic_api/login.php');
      final headers = {'Content-Type': 'application/json'};

       final body = jsonEncode({
     if(_isEmailLogin) 'email': _emailController.text.trim(),
     if(!_isEmailLogin) 'phone':_phoneController.text.trim(),
         'password': _passwordController.text,
       });
       final response = await http.post(
         uri,
         headers: headers,
         body: body,
       ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success']) {
        final storage = FlutterSecureStorage();
        await storage.write(key: 'auth_token', value: data['token']);
        final String? role = data['role'];
        if(role=='manager'){
        Navigator.pushNamed(context, '/Manager_Dashboard'); // }Add this
      } else if(role=='technician'){
          Navigator.pushNamed(
            context,
            '/Tdash',
            arguments: {'technicianId': data['userID']},
          );
        }else{
          Navigator.pushNamed(context, '/UDash',arguments: {'UserID' :data['userID']} );
        }

      } else {
        throw Exception(data['error'] ?? 'Login failed');
      }
    } on FormatException catch (e) {
      print('JSON Decode Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid server response format')),
      );
    } catch (e) {
      print('Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset(
                'assets/logo.png',
                width: double.infinity,
                height: 225,
                fit: BoxFit.contain,
              )
,
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Radio<bool>(
                    value: true,
                    groupValue: _isEmailLogin,
                    onChanged: (value) => setState(() { _isEmailLogin = value!; _phoneController.clear();}),
                  ),
                  const Text('Email'),
                  Radio<bool>(
                    value: false,
                    groupValue: _isEmailLogin,
                    onChanged: (value) => setState(() { _isEmailLogin = value!;_emailController.clear();}) ,
                  ),
                  const Text('Phone'),
                ],
              ),

              // Email/Phone field
              _isEmailLogin
                  ? TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!_isValidEmail(value)) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              )
                  : TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone';
                  }
                  if (!_isValidPhone(value)) {
                    return 'Invalid phone number';
                  }
                  return null;
                },
              ),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                value!.isEmpty ? 'Password required' : null,
              ),

              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),

              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/user-register'),

                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }


}