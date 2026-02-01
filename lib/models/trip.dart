class Trip {
  final int? id;
  final String title;
  final String destination;
  final String startDate;
  final String endDate;
  final String currency;
  final double budget;

  Trip({
    this.id, required this.title, required this.destination,
    required this.startDate, required this.endDate,
    required this.currency, required this.budget,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'title': title, 'destination': destination,
      'startDate': startDate, 'endDate': endDate,
      'currency': currency, 'budget': budget,
    };
  }
}