import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';
import 'models/train_schedule.dart';
import 'settings_page.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String lang;
  String selectedOrigin = '60913';
  String selectedDestination = '60911';
  String defaultOrigin = '60913';
  String defaultDestination = '60911';
  String selectedDay = DateFormat('yyyy-MM-dd').format(DateTime.now());
  late Future<List<TrainSchedule>> futureSchedule;
  bool showPastTrains = false;
  late TextEditingController _originController;
  late TextEditingController _destinationController;

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

  static const Map<String, dynamic> stationIcons = {
    "60911": Icons.beach_access,
    "60913": Icons.school,
    "61200": Icons.location_city,
    "62103": Icons.park,
    "62102": Icons.nature,
    "62002": Icons.church,
    "62101": Icons.grass,
    "62100": Icons.landscape,
    "60914": Icons.account_balance,
    // Generic
    "07004": Icons.train,
    "07007": Icons.train,
    "06008": Icons.train,
    "06002": Icons.train,
    "06100": Icons.train,
    "62001": Icons.train,
    "62003": Icons.train,
    "62108": Icons.train,
    "07003": Icons.train,
    "06004": Icons.train,
    "06001": Icons.train,
    "06005": Icons.train,
    "06006": Icons.train,
    "61101": Icons.train,
    "06007": Icons.train,
    "07001": Icons.train,
    "62109": Icons.train,
    "62104": Icons.train,
    "06003": Icons.train,
  };

  static const Map<String, String> stationEmojis = {
    "60913": "🎓", // Sant Vicent Centre (university/hat)
    "60911": "🏖️", // Alacant Terminal (beach)
    "61200": "🌴", // Murcia del Carmen (palm tree)
    "62103": "🏞️", // Elx Parc (park)
    "62104": "✈️", // Torrellano (airport)
    "62001": "🌾", // Beniel
    "06006": "🏰", // Lorca-Sutullena
    "62002": "🎭", // Orihuela Miguel Hernández
    // Add more as desired, fallback handled below
  };

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: stations[selectedOrigin] ?? '');
    _destinationController = TextEditingController(text: stations[selectedDestination] ?? '');
    final systemLang = ui.window.locale.languageCode;
    lang = systemLang;
    selectedOrigin = defaultOrigin;
    selectedDestination = defaultDestination;
    futureSchedule = fetchSchedule();
    loadSettings();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('lang');
    final savedOrigin = prefs.getString('defaultOrigin');
    final savedDestination = prefs.getString('defaultDestination');
    setState(() {
      if (savedLang != null) lang = savedLang;
      if (savedOrigin != null && stations.containsKey(savedOrigin)) defaultOrigin = savedOrigin;
      if (savedDestination != null && stations.containsKey(savedDestination)) defaultDestination = savedDestination;
      selectedOrigin = defaultOrigin;
      selectedDestination = defaultDestination;
      futureSchedule = fetchSchedule();
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    await prefs.setString('defaultOrigin', defaultOrigin);
    await prefs.setString('defaultDestination', defaultDestination);
  }

  void openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          lang: lang,
          defaultOrigin: defaultOrigin,
          defaultDestination: defaultDestination,
        ),
      ),
    );
    await loadSettings();
  }

  Future<List<TrainSchedule>> fetchSchedule() async {
    DateTime date;
    try {
      date = DateFormat('yyyy-MM-dd').parse(selectedDay);
    } catch (_) {
      date = DateTime.now();
    }
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('https://horarios.renfe.com/cer/HorariosServlet');
    final body = jsonEncode({
      "nucleo": "41",
      "origen": selectedOrigin,
      "destino": selectedDestination,
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
      final List<TrainSchedule> allTrains = horarios.map((h) => TrainSchedule.fromJson(h)).toList();
      if (!showPastTrains) {
        final nowTime = DateFormat('HH:mm').format(DateTime.now());
        // Only show trains with departureTime >= nowTime
        return allTrains.where((t) {
          try {
            return t.departureTime.compareTo(nowTime) >= 0;
          } catch (_) {
            return true;
          }
        }).toList();
      } else {
        return allTrains;
      }
    } else {
      throw Exception('Failed to load schedule');
    }
  }

  Future<void> _pickStation({
    required bool isOrigin,
    required BuildContext context,
  }) async {
    final exclude = isOrigin ? selectedDestination : selectedOrigin;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = stations.entries
                .where((entry) =>
                    entry.key != exclude &&
                    (entry.value.toLowerCase().contains(query.toLowerCase()) ||
                        entry.key.contains(query)))
                .toList();
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: t(lang, 'searchStation'),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => setSheetState(() => query = value),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        return ListTile(
                          leading: Icon(stationIcons[entry.key] ?? Icons.train),
                          title: Text(entry.value),
                          onTap: () => Navigator.pop(context, entry.key),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
    if (selected != null) {
      setState(() {
        if (isOrigin) {
          selectedOrigin = selected;
        } else {
          selectedDestination = selected;
        }
        futureSchedule = fetchSchedule();
      });
    }
  }

  Widget buildScheduleCard(TrainSchedule train, ThemeData theme, String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Operator & Train Code
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFF6F8FC),
                child: Icon(Icons.train, color: Color(0xFF8D7CF6), size: 18),
                radius: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  train.line.isNotEmpty ? train.line : t(lang, 'train'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  train.trainCode,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8D7CF6), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Duration centered above dashed line
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D7CF6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      train.duration,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D7CF6), fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Middle Row: Stations, times, dashed route
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Departure
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    train.departureTime,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    t(lang, 'origin'),
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, 2),
                      painter: _DashedLinePainter(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Arrival
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    train.arrivalTime,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    t(lang, 'destination'),
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          if (train.accessible)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Chip(
                    label: Text(t(lang, 'accessible'), style: const TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.accessible, size: 14),
                    backgroundColor: Colors.green.shade50,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildScheduleSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 18, width: 120, color: Colors.grey[350], margin: const EdgeInsets.only(bottom: 10)),
          Row(
            children: [
              Container(height: 16, width: 48, color: Colors.grey[350]),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 8, color: Colors.grey[350])),
              const SizedBox(width: 8),
              Container(height: 16, width: 48, color: Colors.grey[350]),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 14, width: 80, color: Colors.grey[350]),
        ],
      ),
    );
  }

  Widget buildDatePicker(BuildContext context) {
    final today = DateTime.now();
    final selected = DateTime.parse(selectedDay);
    final theme = Theme.of(context);
    final accent = const Color(0xFF4EC7B3); // Use your accent color
    final List<DateTime> days = List.generate(7, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 64, // Smaller height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14), // Slightly reduced spacing
        itemBuilder: (context, i) {
          final d = days[i];
          final isSelected = d.year == selected.year && d.month == selected.month && d.day == selected.day;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDay = DateFormat('yyyy-MM-dd').format(d);
                futureSchedule = fetchSchedule();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48, // Smaller width
              height: 64, // Smaller height
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.white,
                borderRadius: BorderRadius.circular(16), // Slightly less rounded
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: accent.withOpacity(0.14),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isSelected ? accent : Colors.grey.shade200,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', lang).format(d),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13, // Smaller font
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17, // Smaller font
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F8FC), Color(0xFFE9F0FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row with Destination Station
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            stationEmojis[selectedDestination] ?? "🚆",
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            stations[selectedDestination] ?? '',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.share, color: Colors.black87),
                              onPressed: () {}, // TODO: Implement share
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.more_horiz, color: Colors.black87),
                              onPressed: openSettings,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Station pickers styled as pills with swap
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          // From
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final result = await showDialog<MapEntry<String, String>>(
                                  context: context,
                                  builder: (context) => _StationPickerDialog(
                                    stations: stations,
                                    selected: selectedOrigin,
                                    title: t(lang, 'from'),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    selectedOrigin = result.key;
                                    futureSchedule = fetchSchedule();
                                  });
                                }
                              },
                              child: Container(
                                height: 72,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3E7F1),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on, size: 18, color: Color(0xFF8D7CF6)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t(lang, 'from'), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                          const SizedBox(height: 1),
                                          Text(
                                            stations[selectedOrigin] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // To
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final result = await showDialog<MapEntry<String, String>>(
                                  context: context,
                                  builder: (context) => _StationPickerDialog(
                                    stations: stations,
                                    selected: selectedDestination,
                                    title: t(lang, 'to'),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    selectedDestination = result.key;
                                    futureSchedule = fetchSchedule();
                                  });
                                }
                              },
                              child: Container(
                                height: 72,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD3F4EF),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on, size: 18, color: Color(0xFF4EC7B3)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t(lang, 'to'), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                          const SizedBox(height: 1),
                                          Text(
                                            stations[selectedDestination] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Floating swap button
                      Positioned(
                        left: null,
                        right: null,
                        child: Material(
                          color: const Color(0xFF8D7CF6),
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              setState(() {
                                final temp = selectedOrigin;
                                selectedOrigin = selectedDestination;
                                selectedDestination = temp;
                                futureSchedule = fetchSchedule();
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.swap_horiz, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  buildDatePicker(context),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Switch(
                        value: showPastTrains,
                        onChanged: (value) {
                          setState(() {
                            showPastTrains = value;
                            futureSchedule = fetchSchedule();
                          });
                        },
                        activeColor: const Color(0xFF4EC7B3), // Accent color
                        inactiveTrackColor: Colors.grey.shade300,
                        inactiveThumbColor: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t(lang, 'showPast'),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: FutureBuilder<List<TrainSchedule>>(
                      future: futureSchedule,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ListView.builder(
                            itemCount: 3,
                            itemBuilder: (context, index) => buildScheduleSkeleton(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              t(lang, 'noResults'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              t(lang, 'noResults'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          );
                        } else {
                          final schedules = snapshot.data!;
                          return ListView.builder(
                            itemCount: schedules.length,
                            itemBuilder: (context, index) {
                              final train = schedules[index];
                              return buildScheduleCard(train, theme, lang);
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StationPickerDialog extends StatelessWidget {
  final Map<String, String> stations;
  final String selected;
  final String title;

  const _StationPickerDialog({
    required this.stations,
    required this.selected,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: stations.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              selected: entry.key == selected,
              onTap: () => Navigator.of(context).pop(entry),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB2B6C8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2), Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
