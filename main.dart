import 'package:flutter/material.dart';
import 'UserRegistrationPage.dart';
import 'loginpage.dart';
import 'ManagerDashborad.dart';
import 'AddTechnician.dart';
import 'PostService.dart';
import 'Ratings.dart';
import 'DeleteAccounts.dart';
import 'userdashboard.dart';
import 'techdashboard.dart';
import 'services.dart';
import 'rateservice.dart';
import 'Appointments.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physical Therapy Clinic',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.blueGrey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[800],
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/user-register': (context) => const UserRegistrationPage(),
        '/Manager_Dashboard': (context) => const MDashboardScreen(),
        '/PostSer': (context) => const PostService(),
        '/AddTech': (context) => const AddTechnician(),
        '/Ratings': (context) => const Ratings(),
        '/delete': (context) => const DeleteAccounts(),
        '/Ser': (context) => const Services(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        switch (settings.name) {
          case '/Tdash':
            if (args is Map<String, dynamic> && args.containsKey('technicianId')) {
              return MaterialPageRoute(
                builder: (_) => Techdashboard(
                  technicianId: args['technicianId'],
                ),
              );
            }
            break;

          case '/UDash':
            if (args is Map<String, dynamic> && args.containsKey('UserID')) {
              return MaterialPageRoute(
                builder: (_) => Userdashboard(
                  UserID: args['UserID'],
                ),
              );
            }
            break;

          case '/rate':
            if (args is Map<String, dynamic> && args.containsKey('userId')) {
              return MaterialPageRoute(
                builder: (_) => RateService(
                  userId: args['userId'],
                ),
              );
            }
            break;
          case '/appo':
            if (args is Map<String, dynamic> && args.containsKey('technicianId')) {
              return MaterialPageRoute(
                builder: (_) => TechnicianAppointmentPage(
                  technicianId: args['technicianId'],
                ),
              );
            }
            break;
        }

        // Fallback for unknown or missing parameters
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Route not found or missing parameters")),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
