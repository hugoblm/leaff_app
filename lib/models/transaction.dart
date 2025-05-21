class Transaction {
  final String label;
  final double amount;
  final String date;
  final int score;
  final String details;
  final String recommendation;

  Transaction({
    required this.label,
    required this.amount,
    required this.date,
    required this.score,
    required this.details,
    required this.recommendation,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      score: json['score'] as int,
      details: json['details'] as String,
      recommendation: json['recommendation'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'date': date,
        'score': score,
        'details': details,
        'recommendation': recommendation,
      };
} 