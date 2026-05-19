class Product {
  const Product({
    this.barcode = '',
    this.name = '',
    this.brand = '',
    this.quantity = '',
    this.category = '',
    this.ingredientsText = '',
    this.allergensText = '',
    this.labels = '',
    this.servingSize = '',
    this.nutritionGrade = '',
    this.novaGroup,
    this.energyKcal100g,
    this.sugarG100g,
    this.saturatedFatG100g,
    this.saltG100g,
    this.sodiumMg100g,
    this.proteinG100g,
    this.fiberG100g,
  });

  final String barcode;
  final String name;
  final String brand;
  final String quantity;
  final String category;
  final String ingredientsText;
  final String allergensText;
  final String labels;
  final String servingSize;
  final String nutritionGrade;
  final double? novaGroup;
  final double? energyKcal100g;
  final double? sugarG100g;
  final double? saturatedFatG100g;
  final double? saltG100g;
  final double? sodiumMg100g;
  final double? proteinG100g;
  final double? fiberG100g;

  Product copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? quantity,
    String? category,
    String? ingredientsText,
    String? allergensText,
    String? labels,
    String? servingSize,
    String? nutritionGrade,
    double? novaGroup,
    double? energyKcal100g,
    double? sugarG100g,
    double? saturatedFatG100g,
    double? saltG100g,
    double? sodiumMg100g,
    double? proteinG100g,
    double? fiberG100g,
    bool clearEnergy = false,
    bool clearNovaGroup = false,
    bool clearSugar = false,
    bool clearSaturatedFat = false,
    bool clearSalt = false,
    bool clearSodium = false,
    bool clearProtein = false,
    bool clearFiber = false,
  }) {
    return Product(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      ingredientsText: ingredientsText ?? this.ingredientsText,
      allergensText: allergensText ?? this.allergensText,
      labels: labels ?? this.labels,
      servingSize: servingSize ?? this.servingSize,
      nutritionGrade: nutritionGrade ?? this.nutritionGrade,
      novaGroup: clearNovaGroup ? null : novaGroup ?? this.novaGroup,
      energyKcal100g: clearEnergy
          ? null
          : energyKcal100g ?? this.energyKcal100g,
      sugarG100g: clearSugar ? null : sugarG100g ?? this.sugarG100g,
      saturatedFatG100g: clearSaturatedFat
          ? null
          : saturatedFatG100g ?? this.saturatedFatG100g,
      saltG100g: clearSalt ? null : saltG100g ?? this.saltG100g,
      sodiumMg100g: clearSodium ? null : sodiumMg100g ?? this.sodiumMg100g,
      proteinG100g: clearProtein ? null : proteinG100g ?? this.proteinG100g,
      fiberG100g: clearFiber ? null : fiberG100g ?? this.fiberG100g,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'category': category,
      'ingredients_text': ingredientsText,
      'allergens_text': allergensText,
      'labels': labels,
      'serving_size': servingSize,
      'nutrition_grade': nutritionGrade,
      'nova_group': novaGroup,
      'energy_kcal_100g': energyKcal100g,
      'sugar_g_100g': sugarG100g,
      'saturated_fat_g_100g': saturatedFatG100g,
      'salt_g_100g': saltG100g,
      'sodium_mg_100g': sodiumMg100g,
      'protein_g_100g': proteinG100g,
      'fiber_g_100g': fiberG100g,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      ingredientsText: json['ingredients_text']?.toString() ?? '',
      allergensText: json['allergens_text']?.toString() ?? '',
      labels: json['labels']?.toString() ?? '',
      servingSize: json['serving_size']?.toString() ?? '',
      nutritionGrade: json['nutrition_grade']?.toString() ?? '',
      novaGroup: _number(json['nova_group']),
      energyKcal100g: _number(json['energy_kcal_100g']),
      sugarG100g: _number(json['sugar_g_100g']),
      saturatedFatG100g: _number(json['saturated_fat_g_100g']),
      saltG100g: _number(json['salt_g_100g']),
      sodiumMg100g: _number(json['sodium_mg_100g']),
      proteinG100g: _number(json['protein_g_100g']),
      fiberG100g: _number(json['fiber_g_100g']),
    );
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }
}
