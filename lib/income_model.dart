class Income {
  final int? id;
  final double amount;
  final String description;
  final String source; // Added source field
  final DateTime date;
  final String monthYear; // "YYYY-MM"
  final bool isMonthly; // New field for monthly income

  Income({
    this.id,
    required this.amount,
    required this.description,
    required this.source, // Added source to constructor
    required this.date,
    required this.monthYear,
    this.isMonthly = false, // Default to one-time income
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'source': source, // Added source to toMap
      'date': date.millisecondsSinceEpoch,
      'month_year': monthYear,
      'is_monthly': isMonthly ? 1 : 0, // SQLite stores booleans as integers
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      amount: map['amount'],
      description: map['description'],
      source: map['source'], // Added source to fromMap
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      monthYear: map['month_year'],
      isMonthly: map['is_monthly'] == 1,
    );
  }

  Income copyWith({
    int? id,
    double? amount,
    String? description,
    String? source, // Added source to copyWith
    DateTime? date,
    String? monthYear,
    bool? isMonthly,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      source: source ?? this.source, // Added source to copyWith
      date: date ?? this.date,
      monthYear: monthYear ?? this.monthYear,
      isMonthly: isMonthly ?? this.isMonthly,
    );
  }
}
