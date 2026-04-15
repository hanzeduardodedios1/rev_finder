class Motorcycle {
  // REQUIRED identifiers
  final String make;
  final String model;
  final String year;

  // Display-ready specs
  final String engine;
  final String power;
  final String torque;
  final String weight;
  final String seatHeight;
  final String transmission;

  // Consructor
  Motorcycle({
    required this.make,
    required this.model,
    required this.year,
    required this.engine,
    required this.power,
    required this.torque,
    required this.weight,
    required this.seatHeight,
    required this.transmission,
  });

  // Mapping JSON to Motorcycle object variables
  factory Motorcycle.fromJson(Map<String, dynamic> json) {
    String? readString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null) {
          final asString = value.toString().trim();
          if (asString.isNotEmpty && asString.toLowerCase() != 'null') {
            return asString;
          }
        }
      }
      return null;
    }

    String readOrDefault(List<String> keys, String fallback) {
      return readString(keys) ?? fallback;
    }

    return Motorcycle(
      make: readOrDefault(['make'], 'Unknown Make'),
      model: readOrDefault(['model'], 'Unknown Model'),
      year: readOrDefault(['year'], 'Unknown Year'),

      // The API returns these keys in snake case
      engine: readOrDefault(['engine', 'displacement'], 'N/A'),
      power: readOrDefault(['power', 'horsepower', 'max_power'], 'N/A'),
      torque: readOrDefault(['torque', 'max_torque'], 'N/A'),
      weight: readOrDefault(['total_weight', 'dry_weight', 'weight'], 'N/A'),
      seatHeight: readOrDefault([
        'seat_height',
        'seatHeight',
        'seat height',
      ], 'N/A'),
      transmission: readOrDefault([
        'transmission',
        'gearbox',
        'TransmissionType',
      ], 'N/A'),
    );
  }
}
