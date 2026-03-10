import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const CatsCommuteApp());
}

class CatsCommuteApp extends StatelessWidget {
  const CatsCommuteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cat's Commute",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
