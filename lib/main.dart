import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'localization.dart';
import 'schedule_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // or your preferred color
      statusBarIconBrightness: Brightness.dark, // dark icons for light bg
      statusBarBrightness: Brightness.light, // iOS: dark icons for light bg
    ),
  );
  runApp(const CercaniasScheduleApp());
}

class CercaniasScheduleApp extends StatelessWidget {
  const CercaniasScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CercaAlicante',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScheduleScreen(),
    );
  }
}
