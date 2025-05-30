class TrainSchedule {
  final String line;
  final String trainCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final bool accessible;

  const TrainSchedule({
    required this.line,
    required this.trainCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.accessible,
  });

  factory TrainSchedule.fromJson(Map<String, dynamic> json) {
    return TrainSchedule(
      line: json['linea'] ?? '',
      trainCode: json['cdgoTren'] ?? '',
      departureTime: json['horaSalida'] ?? '',
      arrivalTime: json['horaLlegada'] ?? '',
      duration: json['duracion'] ?? '',
      accessible: json['accesible'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line': line,
      'trainCode': trainCode,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'duration': duration,
      'accessible': accessible,
    };
  }
}
