class Budget {
  final int? id;
  final String categoryName;
  final double amount;
  final String monthYear; // e.g., "2024-10"

  Budget({
    this.id,
    required this.categoryName,
    required this.amount,
    required this.monthYear,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_name': categoryName,
      'amount': amount,
      'month_year': monthYear,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      categoryName: map['category_name'],
      amount: map['amount'],
      monthYear: map['month_year'],
    );
  }

  Budget copyWith({
    int? id,
    String? categoryName,
    double? amount,
    String? monthYear,
  }) {
    return Budget(
        id: id ?? this.id,
        categoryName: categoryName ?? this.categoryName,
        amount: amount ?? this.amount,
        monthYear: monthYear ?? this.monthYear);
  }
}
