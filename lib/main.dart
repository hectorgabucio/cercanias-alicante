import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const CercaniasScheduleApp());
}

class CercaniasScheduleApp extends StatelessWidget {
  const CercaniasScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cercanías Schedule',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const ScheduleScreen(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Add station codes and names
  static const Map<String, String> stations = {
    "07004": "Aguilas",
    "07007": "Aguilas el Labradorcico",
    "60911": "Alacant Terminal",
    "06008": "Alcantarilla-Los Romanos",
    "06002": "Alhama de Murcia",
    "06100": "Almendricos",
    "62001": "Beniel",
    "62003": "Callosa de Segura",
    "62101": "Crevillent",
    "62108": "Elche-Mercancias",
    "62102": "Elx Carrùs",
    "62103": "Elx Parc",
    "07003": "Jaravia",
    "06004": "La Hoya",
    "06001": "Librilla",
    "06005": "Lorca San Diego",
    "06006": "Lorca-Sutullena",
    "61200": "Murcia del Carmen",
    "61101": "Murcia Mercancias",
    "62002": "Orihuela Miguel Hernández",
    "06007": "Puerto Lumbreras",
    "07001": "Pulpi",
    "62100": "San Isidro-Albatera-Catral",
    "62109": "Sant Gabriel",
    "60913": "Sant Vicent Centre",
    "62104": "Torrellano",
    "06003": "Totana",
    "60914": "Universidad de Alicante",
  };

  // Add state for selected origin and destination
  String _selectedOrigin = '60913'; // Default: Sant Vicent Centre
  String _selectedDestination = '60911'; // Default: Alacant Terminal
  late Future<List<TrainSchedule>> _futureSchedule;

  @override
  void initState() {
    super.initState();
    _futureSchedule = fetchSchedule();
  }

  // Update fetchSchedule to use selected origin and destination
  Future<List<TrainSchedule>> fetchSchedule() async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    final url = Uri.parse('https://horarios.renfe.com/cer/HorariosServlet');
    final body = jsonEncode({
      "nucleo": "41",
      "origen": _selectedOrigin,
      "destino": _selectedDestination,
      "fchaViaje": today,
      "validaReglaNegocio": true,
      "tiempoReal": false,
      "servicioHorarios": "VTI",
      "horaViajeOrigen": "00",
      "horaViajeLlegada": "26",
      "accesibilidadTrenes": false
    });
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> horarios = data['horario'] ?? [];
      return horarios.map((h) => TrainSchedule.fromJson(h)).toList();
    } else {
      throw Exception('Failed to load schedule');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${stations[_selectedOrigin] ?? 'Origen'} → ${stations[_selectedDestination] ?? 'Destino'}',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedOrigin,
                  decoration: const InputDecoration(labelText: 'Origen'),
                  items: stations.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedOrigin) {
                      setState(() {
                        _selectedOrigin = value;
                        _futureSchedule = fetchSchedule();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedDestination,
                  decoration: const InputDecoration(labelText: 'Destino'),
                  items: stations.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedDestination) {
                      setState(() {
                        _selectedDestination = value;
                        _futureSchedule = fetchSchedule();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TrainSchedule>>(
              future: _futureSchedule,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No trains found for today.'));
                }
                final trains = snapshot.data!;
                return ListView.separated(
                  itemCount: trains.length,
                  separatorBuilder: (context, i) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = trains[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(t.linea)),
                      title: Text('Salida: ${t.horaSalida}  →  Llegada: ${t.horaLlegada}'),
                      subtitle: Text('Duración: ${t.duracion}  |  Tren: ${t.cdgoTren}'),
                      trailing: t.accesible ? const Icon(Icons.accessible, color: Colors.green) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TrainSchedule {
  final String linea;
  final String cdgoTren;
  final String horaSalida;
  final String horaLlegada;
  final String duracion;
  final bool accesible;

  TrainSchedule({
    required this.linea,
    required this.cdgoTren,
    required this.horaSalida,
    required this.horaLlegada,
    required this.duracion,
    required this.accesible,
  });

  factory TrainSchedule.fromJson(Map<String, dynamic> json) {
    return TrainSchedule(
      linea: json['linea'] ?? '',
      cdgoTren: json['cdgoTren'] ?? '',
      horaSalida: json['horaSalida'] ?? '',
      horaLlegada: json['horaLlegada'] ?? '',
      duracion: json['duracion'] ?? '',
      accesible: json['accesible'] ?? false,
    );
  }
}
