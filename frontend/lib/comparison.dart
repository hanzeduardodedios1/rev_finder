// comparison.dart
//
// Builds comparison rows for the comparison dialog.
//
// This file displays all values currently exposed through motorcycle.dart.
// It does not calculate power score or comfort score.
// The backend calculates normalized values and scores, then Flutter displays them.

import 'motorcycle.dart';

class Comparison {
  final Motorcycle bike1;
  final Motorcycle bike2;

  Comparison({
    required this.bike1,
    required this.bike2,
  });

  List<Map<String, String>> get comparisonRows => [
        // ------------------------------------------------------------
        // Backend-calculated score rows
        // ------------------------------------------------------------
        {
          'label': 'Power Score',
          'bike1': MotorcycleSpecs.formatScore(bike1.powerScore),
          'bike2': MotorcycleSpecs.formatScore(bike2.powerScore),
        },
        {
          'label': 'Comfort Score',
          'bike1': MotorcycleSpecs.formatScore(bike1.comfortScore),
          'bike2': MotorcycleSpecs.formatScore(bike2.comfortScore),
        },
        {
          'label': 'Suspension Score',
          'bike1': MotorcycleSpecs.formatScore(bike1.suspensionScore),
          'bike2': MotorcycleSpecs.formatScore(bike2.suspensionScore),
        },
        {
          'label': 'Power-to-Weight Ratio',
          'bike1': MotorcycleSpecs.formatScore(bike1.powerToWeightRatio),
          'bike2': MotorcycleSpecs.formatScore(bike2.powerToWeightRatio),
        },
        {
          'label': 'Estimated Max Range',
          'bike1': MotorcycleSpecs.formatDouble(bike1.maxRange, 'mi'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.maxRange, 'mi'),
        },
        {
          'label': 'Beginner Bike',
          'bike1': MotorcycleSpecs.formatBool(bike1.isBeginnerBike),
          'bike2': MotorcycleSpecs.formatBool(bike2.isBeginnerBike),
        },

        // ------------------------------------------------------------
        // Main display specs
        // These are the human-readable fields shown on the main cards.
        // ------------------------------------------------------------
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

        // ------------------------------------------------------------
        // Backend-normalized numeric specs
        // These are parsed/cleaned values returned by the backend.
        // Useful for checking if parsing is working correctly.
        // ------------------------------------------------------------
        {
          'label': 'Engine CC',
          'bike1': MotorcycleSpecs.formatDouble(bike1.engineCC, 'cc'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.engineCC, 'cc'),
        },
        {
          'label': 'Parsed Horsepower',
          'bike1': MotorcycleSpecs.formatDouble(bike1.horsepower, 'hp'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.horsepower, 'hp'),
        },
        {
          'label': 'Parsed Torque',
          'bike1': MotorcycleSpecs.formatDouble(bike1.torqueValue, 'lb-ft'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.torqueValue, 'lb-ft'),
        },
        {
          'label': 'Parsed Weight',
          'bike1': MotorcycleSpecs.formatDouble(bike1.weightValue, 'lb'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.weightValue, 'lb'),
        },
        {
          'label': 'Parsed Seat Height',
          'bike1': MotorcycleSpecs.formatDouble(bike1.seatHeightValue, 'in'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.seatHeightValue, 'in'),
        },
        {
          'label': 'Fuel Capacity',
          'bike1': MotorcycleSpecs.formatDouble(bike1.fuelCapacity, 'gal'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.fuelCapacity, 'gal'),
        },
        {
          'label': 'MPG',
          'bike1': MotorcycleSpecs.formatDouble(bike1.mpg, 'mpg'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.mpg, 'mpg'),
        },
        {
          'label': 'Cylinders',
          'bike1': MotorcycleSpecs.formatInt(bike1.cylinders, ''),
          'bike2': MotorcycleSpecs.formatInt(bike2.cylinders, ''),
        },
        {
          'label': 'Gearbox',
          'bike1': MotorcycleSpecs.formatInt(bike1.gearbox, 'speed'),
          'bike2': MotorcycleSpecs.formatInt(bike2.gearbox, 'speed'),
        },
        {
          'label': 'Top Speed',
          'bike1': MotorcycleSpecs.formatDouble(bike1.topSpeed, 'mph'),
          'bike2': MotorcycleSpecs.formatDouble(bike2.topSpeed, 'mph'),
        },

        // ------------------------------------------------------------
        // Backend-normalized text specs
        // ------------------------------------------------------------
        {
          'label': 'Engine Type',
          'bike1': MotorcycleSpecs.formatText(bike1.engineType),
          'bike2': MotorcycleSpecs.formatText(bike2.engineType),
        },
        {
          'label': 'Cooling System',
          'bike1': MotorcycleSpecs.formatText(bike1.coolingSystem),
          'bike2': MotorcycleSpecs.formatText(bike2.coolingSystem),
        },
        {
          'label': 'Clutch Type',
          'bike1': MotorcycleSpecs.formatText(bike1.clutchType),
          'bike2': MotorcycleSpecs.formatText(bike2.clutchType),
        },
        {
          'label': 'Frame',
          'bike1': MotorcycleSpecs.formatText(bike1.frame),
          'bike2': MotorcycleSpecs.formatText(bike2.frame),
        },
        {
          'label': 'Front Brake Type',
          'bike1': MotorcycleSpecs.formatText(bike1.frontBrakeType),
          'bike2': MotorcycleSpecs.formatText(bike2.frontBrakeType),
        },
        {
          'label': 'Rear Brake Type',
          'bike1': MotorcycleSpecs.formatText(bike1.rearBrakeType),
          'bike2': MotorcycleSpecs.formatText(bike2.rearBrakeType),
        },
        {
          'label': 'Front Suspension',
          'bike1': MotorcycleSpecs.formatText(bike1.frontSuspension),
          'bike2': MotorcycleSpecs.formatText(bike2.frontSuspension),
        },
        {
          'label': 'Rear Suspension',
          'bike1': MotorcycleSpecs.formatText(bike1.rearSuspension),
          'bike2': MotorcycleSpecs.formatText(bike2.rearSuspension),
        },
      ];
}