class Emi {
  final int? id;
  final String loanName;
  final String? bankName;
  final double monthlyEmiAmount;
  final double? interestRate;
  final int totalTenureMonths;
  final int tenureRemainingMonths;
  final DateTime nextDueDate;

  Emi({
    this.id,
    required this.loanName,
    this.bankName,
    required this.monthlyEmiAmount,
    this.interestRate,
    required this.totalTenureMonths,
    required this.tenureRemainingMonths,
    required this.nextDueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_name': loanName,
      'bank_name': bankName,
      'monthly_emi_amount': monthlyEmiAmount,
      'interest_rate': interestRate,
      'total_tenure_months': totalTenureMonths,
      'tenure_remaining_months': tenureRemainingMonths,
      'next_due_date': nextDueDate.millisecondsSinceEpoch,
    };
  }

  factory Emi.fromMap(Map<String, dynamic> map) {
    return Emi(
      id: map['id'],
      loanName: map['loan_name'],
      bankName: map['bank_name'],
      monthlyEmiAmount: map['monthly_emi_amount'],
      interestRate: map['interest_rate'],
      totalTenureMonths: map['total_tenure_months'],
      tenureRemainingMonths: map['tenure_remaining_months'],
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(map['next_due_date']),
    );
  }

  Emi copyWith({
    int? id,
    String? loanName,
    String? bankName,
    double? monthlyEmiAmount,
    double? interestRate,
    int? totalTenureMonths,
    int? tenureRemainingMonths,
    DateTime? nextDueDate,
  }) {
    return Emi(
      id: id ?? this.id,
      loanName: loanName ?? this.loanName,
      bankName: bankName ?? this.bankName,
      monthlyEmiAmount: monthlyEmiAmount ?? this.monthlyEmiAmount,
      interestRate: interestRate ?? this.interestRate,
      totalTenureMonths: totalTenureMonths ?? this.totalTenureMonths,
      tenureRemainingMonths:
          tenureRemainingMonths ?? this.tenureRemainingMonths,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }
}
