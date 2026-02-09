class Trip {
  final dynamic id;
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
      'title': title,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'currency': currency,
      'budget': budget,
    };
  }
}