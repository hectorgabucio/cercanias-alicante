import 'package:flutter/material.dart';
import 'models/train_schedule.dart';
import 'settings_page.dart';
import 'localization.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String lang;
  late String selectedOrigin;
  late String selectedDestination;
  late String defaultOrigin;
  late String defaultDestination;
  String selectedDay = 'today';
  late Future<List<TrainSchedule>> futureSchedule;
  bool showPastTrains = false;

  static const List<Map<String, String>> stations = [
    {'code': '60913', 'label': 'Sant Vicent Centre'},
    {'code': '60911', 'label': 'Alacant Terminal'},
    // Add more stations as needed
  ];

  @override
  void initState() {
    super.initState();
    lang = 'es'; // TODO: Detect system language
    selectedOrigin = '60913';
    selectedDestination = '60911';
    defaultOrigin = '60913';
    defaultDestination = '60911';
    futureSchedule = Future.value([]); // Initialize with an empty future
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScheduleAppBar(),
      drawer: ScheduleDrawer(
        lang: lang,
        defaultOrigin: defaultOrigin,
        defaultDestination: defaultDestination,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t(lang, 'origin'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedOrigin,
              items: stations
                  .map((station) => DropdownMenuItem(
                        value: station['code'],
                        child: Text(station['label']!),
                      ))
                  .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedOrigin = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(t(lang, 'destination'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedDestination,
              items: stations
                  .map((station) => DropdownMenuItem(
                        value: station['code'],
                        child: Text(station['label']!),
                      ))
                  .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedDestination = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    futureSchedule = fetchSchedule();
                  });
                },
                child: Text(t(lang, 'search')),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<TrainSchedule>>(
                future: futureSchedule,
                builder: (BuildContext context, AsyncSnapshot<List<TrainSchedule>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No results found.'));
                  } else {
                    final List<TrainSchedule> schedules = snapshot.data!;
                    return ListView.separated(
                      itemCount: schedules.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final TrainSchedule schedule = schedules[index];
                        return ListTile(
                          leading: const Icon(Icons.train),
                          title: Text('Train: ${schedule.trainCode}'),
                          subtitle: Text('Departure: ${schedule.departureTime} - Arrival: ${schedule.arrivalTime}'),
                          trailing: Text(schedule.duration),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<TrainSchedule>> fetchSchedule() async {
    // TODO: Implement fetching logic
    return [];
  }
}

class ScheduleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScheduleAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      titleSpacing: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Open navigation menu',
        ),
      ),
      title: Text(
        t('es', 'appTitle'),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
      actions: const [],
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }
}

class ScheduleDrawer extends StatelessWidget {
  final String lang;
  final String defaultOrigin;
  final String defaultDestination;

  const ScheduleDrawer({
    super.key,
    required this.lang,
    required this.defaultOrigin,
    required this.defaultDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF5B86E5),
            ),
            child: Center(
              child: Text(
                t(lang, 'settings'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(t(lang, 'settings')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    lang: lang,
                    defaultOrigin: defaultOrigin,
                    defaultDestination: defaultDestination,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
