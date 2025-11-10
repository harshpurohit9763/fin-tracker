class Asset {
  final int? id;
  final String name;
  final double value;
  final double? yearlyAppreciation;
  final String? icon;

  Asset({
    this.id,
    required this.name,
    required this.value,
    this.yearlyAppreciation,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'yearly_appreciation': yearlyAppreciation,
      'icon': icon,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'],
      name: map['name'],
      value: map['value'],
      yearlyAppreciation: map['yearly_appreciation'],
      icon: map['icon'],
    );
  }

  Asset copyWith({
    int? id,
    String? name,
    double? value,
    double? yearlyAppreciation,
    String? icon,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      yearlyAppreciation: yearlyAppreciation ?? this.yearlyAppreciation,
      icon: icon ?? this.icon,
    );
  }
}
