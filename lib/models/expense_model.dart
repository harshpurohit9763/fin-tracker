class Expense {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final String monthYear; // "YYYY-MM"
  final String? description;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.monthYear,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'month_year': monthYear,
      'description': description,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      monthYear: map['month_year'],
      description: map['description'],
    );
  }

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    DateTime? date,
    String? monthYear,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      monthYear: monthYear ?? this.monthYear,
      description: description ?? this.description,
    );
  }
}
