import 'package:flutter/material.dart';
import 'localization.dart';
import 'schedule_screen.dart';

void main() {
  runApp(const CercaniasScheduleApp());
}

class CercaniasScheduleApp extends StatelessWidget {
  const CercaniasScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: t('es', 'appTitle'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScheduleScreen(),
    );
  }
}
