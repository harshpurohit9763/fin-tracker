class Badge {
  final int? id;
  final String goalName;
  final String goalIcon;
  final double targetAmount;
  final DateTime completionDate;

  Badge({
    this.id,
    required this.goalName,
    required this.goalIcon,
    required this.targetAmount,
    required this.completionDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_name': goalName,
      'goal_icon': goalIcon,
      'target_amount': targetAmount,
      'completion_date': completionDate.millisecondsSinceEpoch,
    };
  }

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'],
      goalName: map['goal_name'],
      goalIcon: map['goal_icon'],
      targetAmount: map['target_amount'],
      completionDate:
          DateTime.fromMillisecondsSinceEpoch(map['completion_date']),
    );
  }
}
