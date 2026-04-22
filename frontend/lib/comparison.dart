import 'motorcycle.dart';

class Comparison {
  final Motorcycle bike1;
  final Motorcycle bike2;

  Comparison({
    required this.bike1,
    required this.bike2,
  });

  List<Map<String, String>> get comparisonRows => [
        {
          'label': 'Engine',
          'bike1': bike1.engine,
          'bike2': bike2.engine,
        },
        {
          'label': 'Horsepower',
          'bike1': bike1.power,
          'bike2': bike2.power,
        },
        {
          'label': 'Torque',
          'bike1': bike1.torque,
          'bike2': bike2.torque,
        },
        {
          'label': 'Weight',
          'bike1': bike1.weight,
          'bike2': bike2.weight,
        },
        {
          'label': 'Seat Height',
          'bike1': bike1.seatHeight,
          'bike2': bike2.seatHeight,
        },
        {
          'label': 'Transmission',
          'bike1': bike1.transmission,
          'bike2': bike2.transmission,
        },
      ];
}