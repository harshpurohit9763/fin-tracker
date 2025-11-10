class Subscription {
  final int? id;
  final String name;
  final double amount;
  final DateTime nextDueDate;
  final String? icon;

  Subscription({
    this.id,
    required this.name,
    required this.amount,
    required this.nextDueDate,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'next_due_date': nextDueDate.millisecondsSinceEpoch,
      'icon': icon,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(map['next_due_date']),
      icon: map['icon'],
    );
  }

  Subscription copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? nextDueDate,
    String? icon,
  }) {
    return Subscription(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        icon: icon ?? this.icon);
  }
}
