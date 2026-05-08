// motorcycle.dart
//
// Frontend model for RevFinder.
//
// Updated behavior:
// - The backend parses raw API strings into clean JSON fields.
// - The frontend reads those clean fields and displays them.
// - No raw motorcycle API parsing should happen in Flutter.

class Motorcycle {
  final String make;
  final String model;
  final String year;

  final MotorcycleSpecs specs;

  Motorcycle({
    required this.make,
    required this.model,
    required this.year,
    required this.specs,
  });

  // Main display fields.
  String get engine => specs.engine;
  String get power => specs.power;
  String get torque => specs.torqueDisplay;
  String get weight => specs.weightDisplay;
  String get seatHeight => specs.seatHeightDisplay;
  String get transmission => specs.transmission;

  // Parsed / normalized fields from backend JSON.
  double? get engineCC => specs.engineCC;
  double? get horsepower => specs.horsepower;
  double? get torqueValue => specs.torque;
  double? get weightValue => specs.weight;
  double? get seatHeightValue => specs.seatHeight;
  double? get fuelCapacity => specs.fuelCapacityGallons;
  double? get mpg => specs.mpg;
  int? get cylinders => specs.cylinders;
  int? get gearbox => specs.gearbox;
  double? get topSpeed => specs.topSpeed;

  String? get engineType => specs.engineType;
  String? get coolingSystem => specs.coolingSystem;
  String? get clutchType => specs.clutchType;
  String? get frame => specs.frame;
  String? get frontBrakeType => specs.frontBrakeType;
  String? get rearBrakeType => specs.rearBrakeType;
  String? get frontSuspension => specs.frontSuspension;
  String? get rearSuspension => specs.rearSuspension;

  // Backend-calculated values.
  double? get powerScore => specs.powerScore;
  double? get comfortScore => specs.comfortScore;
  double? get suspensionScore => specs.suspensionScore;
  double? get powerToWeightRatio => specs.powerToWeightRatio;
  double? get maxRange => specs.maxRange;
  bool? get isBeginnerBike => specs.isBeginnerBike;

  factory Motorcycle.fromJson(Map json) {
    return Motorcycle(
      make: MotorcycleSpecs.readOrDefault(json, ['make'], 'Unknown Make'),
      model: MotorcycleSpecs.readOrDefault(json, ['model'], 'Unknown Model'),
      year: MotorcycleSpecs.readOrDefault(json, ['year'], 'Unknown Year'),
      specs: MotorcycleSpecs.fromJson(json),
    );
  }

  /// Full spec map for API payloads (comparison summary, etc.).
  Map<String, dynamic> toComparisonPayload() {
    final s = specs;
    return {
      'make': make,
      'model': model,
      'year': year,
      'engine_display': s.engine,
      'power_display': s.power,
      'torque_display': s.torqueDisplay,
      'weight_display': s.weightDisplay,
      'seat_height_display': s.seatHeightDisplay,
      'transmission_display': s.transmission,
      'parsed_engine_cc': s.engineCC,
      'parsed_horsepower': s.horsepower,
      'parsed_torque_lb_ft': s.torque,
      'parsed_weight_lb': s.weight,
      'parsed_seat_height_in': s.seatHeight,
      'parsed_fuel_capacity_gal': s.fuelCapacityGallons,
      'parsed_mpg': s.mpg,
      'cylinders': s.cylinders,
      'gearbox': s.gearbox,
      'top_speed_mph': s.topSpeed,
      'engine_type': s.engineType,
      'cooling_system': s.coolingSystem,
      'clutch_type': s.clutchType,
      'frame': s.frame,
      'front_brake_type': s.frontBrakeType,
      'rear_brake_type': s.rearBrakeType,
      'front_suspension': s.frontSuspension,
      'rear_suspension': s.rearSuspension,
      'power_score': s.powerScore,
      'comfort_score': s.comfortScore,
      'suspension_score': s.suspensionScore,
      'power_to_weight_ratio': s.powerToWeightRatio,
      'max_range': s.maxRange,
      'is_beginner_bike': s.isBeginnerBike,
    };
  }
}

class MotorcycleSpecs {
  // Main display-ready fields.
  final String engine;
  final String power;
  final String torqueDisplay;
  final String weightDisplay;
  final String seatHeightDisplay;
  final String transmission;

  // Parsed / normalized numeric fields.
  final double? engineCC;
  final double? horsepower;
  final double? torque;
  final double? weight;
  final double? seatHeight;
  final double? fuelCapacityGallons;
  final double? mpg;
  final int? cylinders;
  final int? gearbox;
  final double? topSpeed;

  // Text specs.
  final String? engineType;
  final String? coolingSystem;
  final String? clutchType;
  final String? frame;
  final String? frontBrakeType;
  final String? rearBrakeType;
  final String? frontSuspension;
  final String? rearSuspension;

  // Backend-calculated fields.
  final double? powerScore;
  final double? comfortScore;
  final double? suspensionScore;
  final double? powerToWeightRatio;
  final double? maxRange;
  final bool? isBeginnerBike;

  MotorcycleSpecs({
    required this.engine,
    required this.power,
    required this.torqueDisplay,
    required this.weightDisplay,
    required this.seatHeightDisplay,
    required this.transmission,
    required this.engineCC,
    required this.horsepower,
    required this.torque,
    required this.weight,
    required this.seatHeight,
    required this.fuelCapacityGallons,
    required this.mpg,
    required this.cylinders,
    required this.gearbox,
    required this.topSpeed,
    required this.engineType,
    required this.coolingSystem,
    required this.clutchType,
    required this.frame,
    required this.frontBrakeType,
    required this.rearBrakeType,
    required this.frontSuspension,
    required this.rearSuspension,
    required this.powerScore,
    required this.comfortScore,
    required this.suspensionScore,
    required this.powerToWeightRatio,
    required this.maxRange,
    required this.isBeginnerBike,
  });

  factory MotorcycleSpecs.fromJson(Map json) {
    return MotorcycleSpecs(
      // ------------------------------------------------------------
      // Main display strings.
      //
      // These prefer backend display fields first.
      // If the backend does not send them yet, fallback to raw API keys.
      // ------------------------------------------------------------
      engine: readOrDefault(
        json,
        ['engine_display', 'engine', 'engine_type', 'displacement'],
        'N/A',
      ),
      power: readOrDefault(
        json,
        ['power_display', 'power', 'horsepower', 'max_power', 'hp'],
        'N/A',
      ),
      torqueDisplay: readOrDefault(
        json,
        ['torque_display', 'raw_torque', 'torque', 'max_torque'],
        'N/A',
      ),
      weightDisplay: readOrDefault(
        json,
        [
          'weight_display',
          'raw_total_weight',
          'total_weight',
          'dry_weight',
          'wet_weight',
          'weight',
        ],
        'N/A',
      ),
      seatHeightDisplay: readOrDefault(
        json,
        [
          'seat_height_display',
          'raw_seat_height',
          'seat_height',
          'seatHeight',
          'seat height',
        ],
        'N/A',
      ),
      transmission: readOrDefault(
        json,
        ['transmission_display', 'transmission', 'gearbox', 'TransmissionType'],
        'N/A',
      ),

      // ------------------------------------------------------------
      // Parsed numeric values from backend JSON.
      //
      // The backend is responsible for parsing raw API strings.
      // Flutter only reads the clean parsed fields.
      // ------------------------------------------------------------
      engineCC: readDouble(json, ['parsed_engine_cc', 'engine_cc']),
      horsepower: readDouble(json, ['parsed_horsepower', 'horsepower']),
      torque: readDouble(json, ['parsed_torque_lb_ft', 'torque']),
      weight: readDouble(json, ['parsed_weight_lb', 'weight']),
      seatHeight: readDouble(json, ['parsed_seat_height_in', 'seat_height']),
      fuelCapacityGallons: readDouble(
        json,
        ['parsed_fuel_capacity_gal', 'fuel_capacity_gallons', 'fuel_capacity'],
      ),
      mpg: readDouble(json, ['parsed_mpg', 'mpg']),
      cylinders: readInt(json, ['cylinders']),
      gearbox: readInt(json, ['gearbox']),
      topSpeed: readDouble(json, ['top_speed_mph', 'top_speed', 'topSpeed']),


      // ------------------------------------------------------------
      // Text fields from backend parsed JSON.
      // ------------------------------------------------------------
      engineType: readString(json, ['engine_type', 'engineType', 'engine']),
      coolingSystem: readString(
        json,
        ['cooling_system', 'coolingSystem', 'cooling'],
      ),
      clutchType: readString(json, ['clutch_type', 'clutchType', 'clutch']),
      frame: readString(json, ['frame']),
      frontBrakeType: readString(
        json,
        ['front_brake_type', 'frontBrakeType', 'front_brakes'],
      ),
      rearBrakeType: readString(
        json,
        ['rear_brake_type', 'rearBrakeType', 'rear_brakes'],
      ),
      frontSuspension: readString(
        json,
        ['front_suspension', 'frontSuspension'],
      ),
      rearSuspension: readString(
        json,
        ['rear_suspension', 'rearSuspension'],
      ),

      // ------------------------------------------------------------
      // Backend-calculated fields.
      // ------------------------------------------------------------
      powerScore: readDouble(json, ['power_score', 'powerScore']),
      comfortScore: readDouble(json, ['comfort_score', 'comfortScore']),
      suspensionScore: readDouble(json, ['suspension_score', 'suspensionScore']),
      powerToWeightRatio: readDouble(
        json,
        ['power_to_weight_ratio', 'powerToWeightRatio'],
      ),
      maxRange: readDouble(json, ['max_range', 'maxRange']),
      isBeginnerBike: readBool(json, ['is_beginner_bike', 'isBeginnerBike']),
    );
  }

  // ------------------------------------------------------------
  // Display helpers
  // ------------------------------------------------------------

  static String formatScore(double? value) {
    if (value == null) return '';

    return value.toStringAsFixed(2);
  }

  static String formatDouble(double? value, String unit) {
    if (value == null) return '';

    final formatted = value.toStringAsFixed(2);

    if (unit.trim().isEmpty) {
      return formatted;
    }

    return '$formatted $unit';
  }

  static String formatInt(int? value, String unit) {
    if (value == null) return '';

    if (unit.trim().isEmpty) {
      return value.toString();
    }

    return '$value $unit';
  }

  static String formatBool(bool? value) {
    if (value == null) return '';

    return value ? 'Yes' : 'No';
  }

  static String formatText(String? value) {
    if (value == null || value.trim().isEmpty) return '';

    return value;
  }

  // ------------------------------------------------------------
  // Basic readers
  // ------------------------------------------------------------

  static String? readString(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value != null) {
        final asString = value.toString().trim();

        if (asString.isNotEmpty &&
            asString.toLowerCase() != 'null' &&
            asString.toLowerCase() != 'none' &&
            asString.toLowerCase() != 'n/a') {
          return asString;
        }
      }
    }

    return null;
  }

  static String readOrDefault(
    Map json,
    List<String> keys,
    String fallback,
  ) {
    return readString(json, keys) ?? fallback;
  }

  static double? readDouble(Map json, List<String> keys) {
    final rawValue = readString(json, keys);

    if (rawValue == null) return null;

    return _firstNumber(rawValue);
  }

  static int? readInt(Map json, List<String> keys) {
    final rawValue = readString(json, keys);

    if (rawValue == null) return null;

    final match = RegExp(r'\d+').firstMatch(rawValue);

    if (match == null) return null;

    return int.tryParse(match.group(0)!);
  }

  static bool? readBool(Map json, List<String> keys) {
    final rawValue = readString(json, keys);

    if (rawValue == null) return null;

    final normalized = rawValue.toLowerCase();

    if (normalized == 'true') return true;
    if (normalized == 'false') return false;

    return null;
  }

  // ------------------------------------------------------------
  // Numeric parsing helper for clean backend values
  // ------------------------------------------------------------

  static double? _firstNumber(String value) {
    final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(value);

    if (match == null) return null;

    return double.tryParse(match.group(0)!);
  }
}