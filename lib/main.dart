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
  String _selectedDay = 'today'; // 'today' or 'tomorrow'
  late Future<List<TrainSchedule>> _futureSchedule;

  @override
  void initState() {
    super.initState();
    _futureSchedule = fetchSchedule();
  }

  // Update fetchSchedule to use selected origin and destination
  Future<List<TrainSchedule>> fetchSchedule() async {
    final now = DateTime.now();
    final date = _selectedDay == 'today' ? now : now.add(const Duration(days: 1));
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('https://horarios.renfe.com/cer/HorariosServlet');
    final body = jsonEncode({
      "nucleo": "41",
      "origen": _selectedOrigin,
      "destino": _selectedDestination,
      "fchaViaje": formattedDate,
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
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${stations[_selectedOrigin] ?? 'Origen'} → ${stations[_selectedDestination] ?? 'Destino'}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDEB71), Color(0xFFF8D800), Color(0xFFF1C40F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                    child: Column(
                      children: [
                        // Day selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Today'),
                              selected: _selectedDay == 'today',
                              onSelected: (selected) {
                                if (selected && _selectedDay != 'today') {
                                  setState(() {
                                    _selectedDay = 'today';
                                    _futureSchedule = fetchSchedule();
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Tomorrow'),
                              selected: _selectedDay == 'tomorrow',
                              onSelected: (selected) {
                                if (selected && _selectedDay != 'tomorrow') {
                                  setState(() {
                                    _selectedDay = 'tomorrow';
                                    _futureSchedule = fetchSchedule();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.train, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedOrigin,
                                decoration: const InputDecoration(labelText: 'Origen'),
                                borderRadius: BorderRadius.circular(12),
                                items: stations.entries
                                    .where((entry) => entry.key != _selectedDestination)
                                    .map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null && value != _selectedOrigin) {
                                    setState(() {
                                      _selectedOrigin = value;
                                      if (_selectedDestination == value) {
                                        _selectedDestination = stations.keys.firstWhere((k) => k != value);
                                      }
                                      _futureSchedule = fetchSchedule();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: 'Swap origin and destination',
                              child: FloatingActionButton(
                                heroTag: 'swap',
                                mini: true,
                                backgroundColor: Colors.redAccent,
                                onPressed: () {
                                  setState(() {
                                    final temp = _selectedOrigin;
                                    _selectedOrigin = _selectedDestination;
                                    _selectedDestination = temp;
                                    _futureSchedule = fetchSchedule();
                                  });
                                },
                                child: const Icon(Icons.swap_horiz, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.flag, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedDestination,
                                decoration: const InputDecoration(labelText: 'Destino'),
                                borderRadius: BorderRadius.circular(12),
                                items: stations.entries
                                    .where((entry) => entry.key != _selectedOrigin)
                                    .map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null && value != _selectedDestination) {
                                    setState(() {
                                      _selectedDestination = value;
                                      if (_selectedOrigin == value) {
                                        _selectedOrigin = stations.keys.firstWhere((k) => k != value);
                                      }
                                      _futureSchedule = fetchSchedule();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: trains.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = trains[i];
                        bool isPast = false;
                        if (_selectedDay == 'today') {
                          final now = DateTime.now();
                          final todayStr = DateFormat('yyyyMMdd').format(now);
                          final horaSalida = t.horaSalida;
                          // horaSalida is HH:mm, parse as today
                          final parts = horaSalida.split(':');
                          if (parts.length == 2) {
                            final h = int.tryParse(parts[0]) ?? 0;
                            final m = int.tryParse(parts[1]) ?? 0;
                            final depTime = DateTime(now.year, now.month, now.day, h, m);
                            if (depTime.isBefore(now)) {
                              isPast = true;
                            }
                          }
                        }
                        return Opacity(
                          opacity: isPast ? 0.4 : 1.0,
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            color: isPast ? Colors.grey[100] : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Text(
                                  t.linea,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Salida: ${t.horaSalida}  →  Llegada: ${t.horaLlegada}',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPast)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Past',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Duración: ${t.duracion}', style: theme.textTheme.bodySmall),
                                  Text('Tren: ${t.cdgoTren}', style: theme.textTheme.bodySmall),
                                ],
                              ),
                              trailing: t.accesible
                                  ? const Icon(Icons.accessible, color: Colors.green)
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
