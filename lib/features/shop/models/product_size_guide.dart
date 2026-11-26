class ProductSizeMeasurement {
  const ProductSizeMeasurement({required this.size, required this.footLengthCm});
  final String size;
  final double footLengthCm;

  Map<String, dynamic> toJson() => {'Size': size, 'FootLengthCm': footLengthCm};

  factory ProductSizeMeasurement.fromJson(Map<String, dynamic> data) => ProductSizeMeasurement(
    size: (data['Size'] ?? '').toString(),
    footLengthCm: (data['FootLengthCm'] as num).toDouble(),
  );
}

class ProductSizeGuide {
  const ProductSizeGuide({required this.rows, this.fitNote = '', this.source = '', this.isReference = false});
  final List<ProductSizeMeasurement> rows;
  final String fitNote;
  final String source;
  final bool isReference;

  static const reference = ProductSizeGuide(isReference: true, rows: [
    ProductSizeMeasurement(size: '36', footLengthCm: 23),
    ProductSizeMeasurement(size: '37', footLengthCm: 23.5),
    ProductSizeMeasurement(size: '38', footLengthCm: 24),
    ProductSizeMeasurement(size: '39', footLengthCm: 24.5),
    ProductSizeMeasurement(size: '40', footLengthCm: 25),
    ProductSizeMeasurement(size: '41', footLengthCm: 25.5),
    ProductSizeMeasurement(size: '42', footLengthCm: 26),
    ProductSizeMeasurement(size: '43', footLengthCm: 26.5),
    ProductSizeMeasurement(size: '44', footLengthCm: 27),
    ProductSizeMeasurement(size: '45', footLengthCm: 27.5),
    ProductSizeMeasurement(size: '46', footLengthCm: 28),
  ]);

  Map<String, dynamic> toJson() => {
    'Rows': rows.map((row) => row.toJson()).toList(), 'FitNote': fitNote, 'Source': source,
    'IsReference': isReference,
  };

  factory ProductSizeGuide.fromJson(Map<String, dynamic> data) => ProductSizeGuide(
    rows: (data['Rows'] as List? ?? []).whereType<Map>().where((row) =>
      (row['Size'] ?? '').toString().trim().isNotEmpty &&
      row['FootLengthCm'] is num && (row['FootLengthCm'] as num) > 0).map((row) =>
      ProductSizeMeasurement.fromJson(Map<String, dynamic>.from(row))).toList(),
    fitNote: (data['FitNote'] ?? '').toString(), source: (data['Source'] ?? '').toString(),
    isReference: data['IsReference'] == true,
  );
}
