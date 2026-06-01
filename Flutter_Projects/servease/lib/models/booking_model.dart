class BookingModel {
  final String userId;
  final String providerId;
  final String service;
  final String date;
  final String time;
  final String status;

  BookingModel({
    required this.userId,
    required this.providerId,
    required this.service,
    required this.date,
    required this.time,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'providerId': providerId,
      'service': service,
      'date': date,
      'time': time,
      'status': status,
      'createdAt': DateTime.now(),
    };
  }
}
