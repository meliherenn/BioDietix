import '../../../models/product.dart';
import '../../../models/product_evaluation.dart';

class ProductCheck {
  const ProductCheck({
    required this.id,
    required this.productName,
    required this.brand,
    required this.barcode,
    required this.decision,
    required this.dataQualityLevel,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String productName;
  final String brand;
  final String barcode;
  final String decision;
  final String dataQualityLevel;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductCheck copyWith({
    String? id,
    String? productName,
    String? brand,
    String? barcode,
    String? decision,
    String? dataQualityLevel,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCheck(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      decision: decision ?? this.decision,
      dataQualityLevel: dataQualityLevel ?? this.dataQualityLevel,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'brand': brand,
      'barcode': barcode,
      'decision': decision,
      'dataQualityLevel': dataQualityLevel,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductCheck.fromJson(Map<String, dynamic> json) {
    return ProductCheck(
      id: json['id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      decision: json['decision']?.toString() ?? 'recommended',
      dataQualityLevel: json['dataQualityLevel']?.toString() ?? 'medium',
      note: json['note']?.toString() ?? '',
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  factory ProductCheck.fromEvaluation({
    required String id,
    required Product product,
    required ProductEvaluation evaluation,
    required DateTime now,
  }) {
    final productName = product.name.trim().isEmpty
        ? product.barcode.trim()
        : product.name.trim();
    return ProductCheck(
      id: id,
      productName: productName,
      brand: product.brand.trim(),
      barcode: product.barcode.trim(),
      decision: evaluation.decision,
      dataQualityLevel: evaluation.dataQualityLevel,
      note: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
