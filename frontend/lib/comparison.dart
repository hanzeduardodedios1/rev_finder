// comparison.dart
//
// Builds comparison rows for the comparison dialog.
//
// Updated:
// - Numeric rows can now show which motorcycle has the better value.
// - Most numeric rows treat higher values as better.
// - Parsed Weight and Parsed Seat Height treat lower values as better.
// - Better value gets the green styling from main.dart.
// - Worse value gets the red styling from main.dart.
// - For inverse rows, the better/lower value will show as a green negative difference.
// - Non-numeric/text rows are displayed normally.

import 'motorcycle.dart';

enum ComparisonResult {
  higher,
  lower,
  equal,
  none,
}

class ComparisonRow {
  final String label;
  final String bike1;
  final String bike2;
  final String unit;

  // If true, lower numeric values are treated as better.
  //
  // Example:
  // - horsepower: lowerIsBetter = false
  // - weight: lowerIsBetter = true
  // - seat height: lowerIsBetter = true
  final bool lowerIsBetter;

  final double? bike1NumericValue;
  final double? bike2NumericValue;

  ComparisonRow({
    required this.label,
    required this.bike1,
    required this.bike2,
    this.unit = '',
    this.lowerIsBetter = false,
    this.bike1NumericValue,
    this.bike2NumericValue,
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

    // For rows like weight and seat height, lower is better.
    if (lowerIsBetter) {
      if (bike1NumericValue! < bike2NumericValue!) {
        return ComparisonResult.higher;
      }

      return ComparisonResult.lower;
    }

    // Default behavior: greater value is better.
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

    // For rows like weight and seat height, lower is better.
    if (lowerIsBetter) {
      if (bike2NumericValue! < bike1NumericValue!) {
        return ComparisonResult.higher;
      }

      return ComparisonResult.lower;
    }

    // Default behavior: greater value is better.
    if (bike2NumericValue! > bike1NumericValue!) {
      return ComparisonResult.higher;
    }

    return ComparisonResult.lower;
  }

  // This is now a getter, so main.dart can use:
  // differenceText: row.differenceText
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

  ComparisonRow _numericRow({
    required String label,
    required double? bike1Value,
    required double? bike2Value,
    required String unit,
    bool lowerIsBetter = false,
  }) {
    return ComparisonRow(
      label: label,
      bike1: MotorcycleSpecs.formatDouble(bike1Value, unit),
      bike2: MotorcycleSpecs.formatDouble(bike2Value, unit),
      unit: unit,
      lowerIsBetter: lowerIsBetter,
      bike1NumericValue: bike1Value,
      bike2NumericValue: bike2Value,
    );
  }

  ComparisonRow _scoreRow({
    required String label,
    required double? bike1Value,
    required double? bike2Value,
  }) {
    return ComparisonRow(
      label: label,
      bike1: MotorcycleSpecs.formatScore(bike1Value),
      bike2: MotorcycleSpecs.formatScore(bike2Value),
      bike1NumericValue: bike1Value,
      bike2NumericValue: bike2Value,
    );
  }

  ComparisonRow _intRow({
    required String label,
    required int? bike1Value,
    required int? bike2Value,
    required String unit,
    bool lowerIsBetter = false,
  }) {
    return ComparisonRow(
      label: label,
      bike1: MotorcycleSpecs.formatInt(bike1Value, unit),
      bike2: MotorcycleSpecs.formatInt(bike2Value, unit),
      unit: unit,
      lowerIsBetter: lowerIsBetter,
      bike1NumericValue: bike1Value?.toDouble(),
      bike2NumericValue: bike2Value?.toDouble(),
    );
  }

  ComparisonRow _textRow({
    required String label,
    required String bike1Value,
    required String bike2Value,
  }) {
    return ComparisonRow(
      label: label,
      bike1: bike1Value,
      bike2: bike2Value,
    );
  }

  ComparisonRow _nullableTextRow({
    required String label,
    required String? bike1Value,
    required String? bike2Value,
  }) {
    return ComparisonRow(
      label: label,
      bike1: MotorcycleSpecs.formatText(bike1Value),
      bike2: MotorcycleSpecs.formatText(bike2Value),
    );
  }

  List<ComparisonRow> get comparisonRows => [
        _scoreRow(
          label: 'Power Score',
          bike1Value: bike1.powerScore,
          bike2Value: bike2.powerScore,
        ),
        _scoreRow(
          label: 'Comfort Score',
          bike1Value: bike1.comfortScore,
          bike2Value: bike2.comfortScore,
        ),
        _scoreRow(
          label: 'Suspension Score',
          bike1Value: bike1.suspensionScore,
          bike2Value: bike2.suspensionScore,
        ),
        _scoreRow(
          label: 'Power-to-Weight Ratio',
          bike1Value: bike1.powerToWeightRatio,
          bike2Value: bike2.powerToWeightRatio,
        ),
        _numericRow(
          label: 'Estimated Max Range',
          bike1Value: bike1.maxRange,
          bike2Value: bike2.maxRange,
          unit: 'mi',
        ),

        _textRow(
          label: 'Beginner Bike',
          bike1Value: MotorcycleSpecs.formatBool(bike1.isBeginnerBike),
          bike2Value: MotorcycleSpecs.formatBool(bike2.isBeginnerBike),
        ),

        _textRow(
          label: 'Engine',
          bike1Value: bike1.engine,
          bike2Value: bike2.engine,
        ),
        _textRow(
          label: 'Horsepower',
          bike1Value: bike1.power,
          bike2Value: bike2.power,
        ),
        _textRow(
          label: 'Torque',
          bike1Value: bike1.torque,
          bike2Value: bike2.torque,
        ),
        _textRow(
          label: 'Weight',
          bike1Value: bike1.weight,
          bike2Value: bike2.weight,
        ),
        _textRow(
          label: 'Seat Height',
          bike1Value: bike1.seatHeight,
          bike2Value: bike2.seatHeight,
        ),
        _textRow(
          label: 'Transmission',
          bike1Value: bike1.transmission,
          bike2Value: bike2.transmission,
        ),

        _numericRow(
          label: 'Engine CC',
          bike1Value: bike1.engineCC,
          bike2Value: bike2.engineCC,
          unit: 'cc',
        ),
        _numericRow(
          label: 'Parsed Horsepower',
          bike1Value: bike1.horsepower,
          bike2Value: bike2.horsepower,
          unit: 'hp',
        ),
        _numericRow(
          label: 'Parsed Torque',
          bike1Value: bike1.torqueValue,
          bike2Value: bike2.torqueValue,
          unit: 'lb-ft',
        ),
        _numericRow(
          label: 'Parsed Weight',
          bike1Value: bike1.weightValue,
          bike2Value: bike2.weightValue,
          unit: 'lb',
          lowerIsBetter: true,
        ),
        _numericRow(
          label: 'Parsed Seat Height',
          bike1Value: bike1.seatHeightValue,
          bike2Value: bike2.seatHeightValue,
          unit: 'in',
          lowerIsBetter: true,
        ),
        _numericRow(
          label: 'Fuel Capacity',
          bike1Value: bike1.fuelCapacity,
          bike2Value: bike2.fuelCapacity,
          unit: 'gal',
        ),
        _numericRow(
          label: 'MPG',
          bike1Value: bike1.mpg,
          bike2Value: bike2.mpg,
          unit: 'mpg',
        ),
        _intRow(
          label: 'Cylinders',
          bike1Value: bike1.cylinders,
          bike2Value: bike2.cylinders,
          unit: '',
        ),
        _intRow(
          label: 'Gearbox',
          bike1Value: bike1.gearbox,
          bike2Value: bike2.gearbox,
          unit: 'speed',
        ),
        _numericRow(
          label: 'Top Speed',
          bike1Value: bike1.topSpeed,
          bike2Value: bike2.topSpeed,
          unit: 'mph',
        ),

        _nullableTextRow(
          label: 'Engine Type',
          bike1Value: bike1.engineType,
          bike2Value: bike2.engineType,
        ),
        _nullableTextRow(
          label: 'Cooling System',
          bike1Value: bike1.coolingSystem,
          bike2Value: bike2.coolingSystem,
        ),
        _nullableTextRow(
          label: 'Clutch Type',
          bike1Value: bike1.clutchType,
          bike2Value: bike2.clutchType,
        ),
        _nullableTextRow(
          label: 'Frame',
          bike1Value: bike1.frame,
          bike2Value: bike2.frame,
        ),
        _nullableTextRow(
          label: 'Front Brake Type',
          bike1Value: bike1.frontBrakeType,
          bike2Value: bike2.frontBrakeType,
        ),
        _nullableTextRow(
          label: 'Rear Brake Type',
          bike1Value: bike1.rearBrakeType,
          bike2Value: bike2.rearBrakeType,
        ),
        _nullableTextRow(
          label: 'Front Suspension',
          bike1Value: bike1.frontSuspension,
          bike2Value: bike2.frontSuspension,
        ),
        _nullableTextRow(
          label: 'Rear Suspension',
          bike1Value: bike1.rearSuspension,
          bike2Value: bike2.rearSuspension,
        ),
      ];
}