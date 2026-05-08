// comparison.dart
//
// Builds comparison rows for the comparison dialog.
// Rows are grouped into labeled sections; missing fields use empty strings
// and render as “Data Unavailable” in the modal.

import 'motorcycle.dart';

enum ComparisonResult {
  higher,
  lower,
  equal,
  none,
}

/// Non-null if this row should appear in the comparison modal.
bool isMissingModalDisplay(String? value) {
  if (value == null) return true;
  final t = value.trim();
  if (t.isEmpty) return true;
  final lower = t.toLowerCase();
  if (lower == 'null') return true;
  if (lower == 'n/a') return true;
  return false;
}

class ComparisonSection {
  final String title;
  final List<ComparisonRow> rows;

  const ComparisonSection({
    required this.title,
    required this.rows,
  });
}

class ComparisonRow {
  final String label;
  final String bike1;
  final String bike2;
  final String unit;

  /// If true, lower numeric values are treated as better.
  final bool lowerIsBetter;

  /// Snake_case metric id for modal delta coloring (neutral / inverse presets).
  final String? specKey;

  final double? bike1NumericValue;
  final double? bike2NumericValue;

  /// When true, spec table cells align values to the trailing edge for scan-friendly numerics.
  final bool rightAlignValues;

  ComparisonRow({
    required this.label,
    required this.bike1,
    required this.bike2,
    this.unit = '',
    this.lowerIsBetter = false,
    this.specKey,
    this.bike1NumericValue,
    this.bike2NumericValue,
    this.rightAlignValues = false,
  });

  bool get isNumericComparison {
    return bike1NumericValue != null && bike2NumericValue != null;
  }

  double? get difference {
    if (!isNumericComparison) return null;

    return (bike1NumericValue! - bike2NumericValue!).abs();
  }

  ComparisonResult get bike1Result {
    if (!isNumericComparison) return ComparisonResult.none;

    if (bike1NumericValue! == bike2NumericValue!) {
      return ComparisonResult.equal;
    }

    if (lowerIsBetter) {
      if (bike1NumericValue! < bike2NumericValue!) {
        return ComparisonResult.higher;
      }

      return ComparisonResult.lower;
    }

    if (bike1NumericValue! > bike2NumericValue!) {
      return ComparisonResult.higher;
    }

    return ComparisonResult.lower;
  }

  ComparisonResult get bike2Result {
    if (!isNumericComparison) return ComparisonResult.none;

    if (bike2NumericValue! == bike1NumericValue!) {
      return ComparisonResult.equal;
    }

    if (lowerIsBetter) {
      if (bike2NumericValue! < bike1NumericValue!) {
        return ComparisonResult.higher;
      }

      return ComparisonResult.lower;
    }

    if (bike2NumericValue! > bike1NumericValue!) {
      return ComparisonResult.higher;
    }

    return ComparisonResult.lower;
  }

  String get differenceText {
    final diff = difference;

    if (diff == null) return '';

    if (diff == 0) return 'Equal';

    if (unit.trim().isEmpty) {
      return diff.toStringAsFixed(2);
    }

    return '${diff.toStringAsFixed(2)} $unit';
  }
}

class Comparison {
  final Motorcycle bike1;
  final Motorcycle bike2;

  Comparison({
    required this.bike1,
    required this.bike2,
  });

  /// Formats a numeric cell; empty string means “unavailable” in the modal.
  String _formatNumericCell(double? value, String unit) {
    if (value == null) return '';
    return MotorcycleSpecs.formatDouble(value, unit);
  }

  ComparisonRow _numericRow({
    required String label,
    required double? bike1Value,
    required double? bike2Value,
    required String unit,
    bool lowerIsBetter = false,
    String? specKey,
  }) {
    return ComparisonRow(
      label: label,
      bike1: _formatNumericCell(bike1Value, unit),
      bike2: _formatNumericCell(bike2Value, unit),
      unit: unit,
      lowerIsBetter: lowerIsBetter,
      specKey: specKey,
      bike1NumericValue: bike1Value,
      bike2NumericValue: bike2Value,
      rightAlignValues: true,
    );
  }

  ComparisonRow _scoreRow({
    required String label,
    required double? bike1Value,
    required double? bike2Value,
  }) {
    return ComparisonRow(
      label: label,
      bike1: bike1Value != null ? MotorcycleSpecs.formatScore(bike1Value) : '',
      bike2: bike2Value != null ? MotorcycleSpecs.formatScore(bike2Value) : '',
      bike1NumericValue: bike1Value,
      bike2NumericValue: bike2Value,
      rightAlignValues: true,
    );
  }

  String _textCell(String? value) {
    if (isMissingModalDisplay(value)) return '';
    return value!.trim();
  }

  ComparisonRow _partialNumericRow({
    required String label,
    required double? bike1Value,
    required double? bike2Value,
    required String unit,
    bool lowerIsBetter = false,
    String? specKey,
  }) {
    return _numericRow(
      label: label,
      bike1Value: bike1Value,
      bike2Value: bike2Value,
      unit: unit,
      lowerIsBetter: lowerIsBetter,
      specKey: specKey,
    );
  }

  ComparisonRow _partialTextRow({
    required String label,
    required String? bike1Value,
    required String? bike2Value,
  }) {
    return ComparisonRow(
      label: label,
      bike1: _textCell(bike1Value),
      bike2: _textCell(bike2Value),
    );
  }

  ComparisonRow _horsepowerRow() {
    final n1 = bike1.horsepower;
    final n2 = bike2.horsepower;
    if (n1 != null && n2 != null) {
      return _numericRow(
        label: 'Horsepower',
        bike1Value: n1,
        bike2Value: n2,
        unit: 'hp',
      );
    }
    return _partialTextRow(
      label: 'Horsepower',
      bike1Value: bike1.power,
      bike2Value: bike2.power,
    );
  }

  ComparisonRow _torqueRow() {
    final n1 = bike1.torqueValue;
    final n2 = bike2.torqueValue;
    if (n1 != null && n2 != null) {
      return _numericRow(
        label: 'Torque',
        bike1Value: n1,
        bike2Value: n2,
        unit: 'lb-ft',
      );
    }
    return _partialTextRow(
      label: 'Torque',
      bike1Value: bike1.torque,
      bike2Value: bike2.torque,
    );
  }

  ComparisonRow _displacementRow() {
    return _partialNumericRow(
      label: 'Displacement',
      bike1Value: bike1.engineCC,
      bike2Value: bike2.engineCC,
      unit: 'cc',
      specKey: 'displacement',
    );
  }

  ComparisonRow _powerToWeightRow() {
    return _partialNumericRow(
      label: 'Power-to-Weight Ratio',
      bike1Value: bike1.powerToWeightRatio,
      bike2Value: bike2.powerToWeightRatio,
      unit: '',
    );
  }

  ComparisonRow _beginnerRow() {
    final b1 = bike1.isBeginnerBike;
    final b2 = bike2.isBeginnerBike;
    return ComparisonRow(
      label: 'Beginner Bike',
      bike1: b1 == null ? '' : (b1 ? 'Yes' : 'No'),
      bike2: b2 == null ? '' : (b2 ? 'Yes' : 'No'),
    );
  }

  ComparisonRow _seatHeightRow() {
    final n1 = bike1.seatHeightValue;
    final n2 = bike2.seatHeightValue;
    if (n1 != null && n2 != null) {
      return _numericRow(
        label: 'Seat Height',
        bike1Value: n1,
        bike2Value: n2,
        unit: 'in',
        lowerIsBetter: true,
      );
    }
    return _partialTextRow(
      label: 'Seat Height',
      bike1Value: bike1.seatHeight,
      bike2Value: bike2.seatHeight,
    );
  }

  ComparisonRow _weightRow() {
    final n1 = bike1.weightValue;
    final n2 = bike2.weightValue;
    if (n1 != null && n2 != null) {
      return _numericRow(
        label: 'Weight',
        bike1Value: n1,
        bike2Value: n2,
        unit: 'lb',
        lowerIsBetter: true,
        specKey: 'weight',
      );
    }
    return _partialTextRow(
      label: 'Weight',
      bike1Value: bike1.weight,
      bike2Value: bike2.weight,
    );
  }

  ComparisonRow _engineRow() {
    return _partialTextRow(
      label: 'Engine',
      bike1Value: bike1.engine,
      bike2Value: bike2.engine,
    );
  }

  ComparisonRow _transmissionRow() {
    return _partialTextRow(
      label: 'Transmission',
      bike1Value: bike1.transmission,
      bike2Value: bike2.transmission,
    );
  }

  ComparisonRow _suspensionScoreRow() {
    return _partialNumericRow(
      label: 'Suspension Score',
      bike1Value: bike1.suspensionScore,
      bike2Value: bike2.suspensionScore,
      unit: '',
    );
  }

  ComparisonRow _maxRangeRow() {
    return _partialNumericRow(
      label: 'Estimated Max Range',
      bike1Value: bike1.maxRange,
      bike2Value: bike2.maxRange,
      unit: 'mi',
    );
  }

  /// Metadata rows for score-card deltas (not shown as table rows).
  ComparisonRow get powerScoreComparisonMeta => _scoreRow(
        label: 'Power Score',
        bike1Value: bike1.powerScore,
        bike2Value: bike2.powerScore,
      );

  ComparisonRow get comfortScoreComparisonMeta => _scoreRow(
        label: 'Comfort Score',
        bike1Value: bike1.comfortScore,
        bike2Value: bike2.comfortScore,
      );

  List<ComparisonSection> get comparisonSections {
    final performance = ComparisonSection(
      title: 'PERFORMANCE',
      rows: [
        _horsepowerRow(),
        _torqueRow(),
        _displacementRow(),
        _powerToWeightRow(),
      ],
    );

    final ergonomics = ComparisonSection(
      title: 'ERGONOMICS & COMFORT',
      rows: [
        _beginnerRow(),
        _seatHeightRow(),
        _weightRow(),
      ],
    );

    final drivetrain = ComparisonSection(
      title: 'DRIVETRAIN',
      rows: [
        _engineRow(),
        _transmissionRow(),
        _suspensionScoreRow(),
        _maxRangeRow(),
      ],
    );

    return [
      performance,
      ergonomics,
      drivetrain,
    ];
  }
}
