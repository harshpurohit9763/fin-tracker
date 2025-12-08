class Emi {
  final int? id;
  final String loanName;
  final String? bankName;
  final double monthlyEmiAmount;
  final double? interestRate;
  final int totalTenureMonths;
  final int tenureRemainingMonths;
  final DateTime startDate;
  final DateTime nextDueDate;
  final bool isCompoundInterest;

  Emi({
    this.id,
    required this.loanName,
    this.bankName,
    required this.monthlyEmiAmount,
    this.interestRate,
    required this.totalTenureMonths,
    required this.tenureRemainingMonths,
    required this.startDate,
    required this.nextDueDate,
    this.isCompoundInterest = false,
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
      'start_date': startDate.millisecondsSinceEpoch,
      'next_due_date': nextDueDate.millisecondsSinceEpoch,
      'is_compound_interest': isCompoundInterest ? 1 : 0,
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
      startDate: DateTime.fromMillisecondsSinceEpoch(
          map['start_date'] ?? map['next_due_date']),
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(map['next_due_date']),
      isCompoundInterest:
          map['is_compound_interest'] == 1, // Convert from int to bool
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
    DateTime? startDate,
    DateTime? nextDueDate,
    bool? isCompoundInterest,
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
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isCompoundInterest: isCompoundInterest ?? this.isCompoundInterest,
    );
  }
}
