class ProductOptionModel {
  final String name;
  final List<String> values;

  const ProductOptionModel({required this.name, required this.values});

  Map<String, dynamic> toMap() {
    return {'name': name, 'values': values};
  }

  factory ProductOptionModel.fromMap(Map<String, dynamic> map) {
    final rawValues = map['values'];
    return ProductOptionModel(
      name: map['name']?.toString() ?? '',
      values: rawValues is Iterable
          ? rawValues
                .where((value) => value != null)
                .map((value) => value.toString())
                .toList()
          : const [],
    );
  }

  factory ProductOptionModel.formMap(Map<String, dynamic> map) {
    return ProductOptionModel.fromMap(map);
  }
}
