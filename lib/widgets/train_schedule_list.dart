import 'package:flutter/material.dart';
import '../models/train_schedule.dart';
import '../localization.dart';

class TrainScheduleListItem extends StatelessWidget {
  final TrainSchedule train;
  final String lang;

  const TrainScheduleListItem({super.key, required this.train, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: const Icon(Icons.train),
      title: Text(
        '${t(lang, 'origin')}: ${train.departureTime}  →  ${t(lang, 'destination')}: ${train.arrivalTime}',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('${t(lang, 'duration')}: ${train.duration}', style: theme.textTheme.bodySmall),
          Text('${t(lang, 'train')}: ${train.trainCode}', style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: train.accessible ? const Icon(Icons.accessible, color: Colors.green) : null,
    );
  }
}
