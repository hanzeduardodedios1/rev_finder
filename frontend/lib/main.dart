// main.dart
//
// Main Flutter UI for RevFinder.
//
// Updated behavior:
// - Website now uses dark mode.
// - Search bar, cards, dialog, and text colors adapt to the dark theme.
// - When a user selects a motorcycle, the card only shows the main specs.
// - The full expanded specs only appear when the user presses
//   the "Compare Motorcycles" button.
// - The comparison dialog shows green styling for better numeric values
//   and red styling for worse numeric values.
// - For inverse rows like weight and seat height, lower values show
//   as green negative differences.

import 'package:flutter/material.dart';

import 'apiservice.dart';
import 'comparison.dart';
import 'motorcycle.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Builds the root Flutter app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RevFinder',

      // Light theme is still defined in case you want to switch later.
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 34, 8, 78),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
      ),

      // Dark theme used by the app.
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 120, 82, 255),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 120, 82, 255),
            foregroundColor: Colors.white,
          ),
        ),
      ),

      // Forces dark mode.
      //
      // Change this to ThemeMode.system if you want the app to follow
      // the user's device/browser theme setting.
      themeMode: ThemeMode.dark,

      home: const SearchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Stores the motorcycles selected for comparison.
  //
  // The comparison feature only allows two motorcycles at a time.
  final List<Motorcycle> selectedBikes = [];

  // Handles backend API calls.
  final ApiService _apiService = ApiService();

  // Creates a Comparison object only when two bikes are selected.
  Comparison? get currentComparison {
    if (selectedBikes.length == 2) {
      return Comparison(
        bike1: selectedBikes[0],
        bike2: selectedBikes[1],
      );
    }

    return null;
  }

  // Normalizes text so make/model matching is not broken by case or spacing.
  String _normalizeForMatch(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Picks the best matching full-spec result from the specs endpoint.
  Motorcycle _pickBestSpecMatch(
    List<dynamic> specsData,
    Motorcycle selectedSuggestion,
  ) {
    final normalizedTargetModel = _normalizeForMatch(selectedSuggestion.model);
    final normalizedTargetMake = _normalizeForMatch(selectedSuggestion.make);

    // Try exact make + model match first.
    for (final item in specsData) {
      if (item is! Map) continue;

      final candidate = Motorcycle.fromJson(
        Map<String, dynamic>.from(item),
      );

      final candidateModel = _normalizeForMatch(candidate.model);
      final candidateMake = _normalizeForMatch(candidate.make);

      if (candidateMake == normalizedTargetMake &&
          candidateModel == normalizedTargetModel) {
        return candidate;
      }
    }

    // If exact model text does not match because of formatting differences,
    // use the first full-spec result returned by the backend.
    for (final item in specsData) {
      if (item is Map) {
        return Motorcycle.fromJson(
          Map<String, dynamic>.from(item),
        );
      }
    }

    // If the backend gave no usable full-spec result, keep the original result.
    return selectedSuggestion;
  }

  // Fetches the full specs for a selected motorcycle.
  Future<Motorcycle> _fetchHydratedMotorcycle(
    Motorcycle selectedSuggestion,
  ) async {
    final encodedMake = Uri.encodeQueryComponent(selectedSuggestion.make);
    final encodedModel = Uri.encodeQueryComponent(
      selectedSuggestion.model.trim(),
    );

    final endpoint =
        '/api/motorcycles/specs?make=$encodedMake&model=$encodedModel';

    final response = await _apiService.fetchData(endpoint);

    // Case 1: Backend returns a list of motorcycle records.
    if (response is List && response.isNotEmpty) {
      return _pickBestSpecMatch(response, selectedSuggestion);
    }

    // Case 2: Backend returns one motorcycle record as Map<String, dynamic>.
    if (response is Map<String, dynamic>) {
      return Motorcycle.fromJson(response);
    }

    // Case 3: Backend returns one motorcycle record as a generic Map.
    if (response is Map) {
      return Motorcycle.fromJson(
        Map<String, dynamic>.from(response),
      );
    }

    // If the backend gave no usable full-spec result, keep the original result.
    return selectedSuggestion;
  }

  // Builds one value inside the comparison dialog.
  //
  // Numeric comparison rows show:
  // - green styling if this motorcycle has the better value
  // - red styling if this motorcycle has the worse value
  // - gray Equal label if both values are equal
  //
  // For normal rows, higher is better:
  //   better value = green up arrow with +difference
  //
  // For inverse rows like weight and seat height, lower is better:
  //   better value = green down arrow with -difference
  Widget _buildComparisonValue({
    required String value,
    required ComparisonResult result,
    required String differenceText,
    required bool lowerIsBetter,
  }) {
    if (result == ComparisonResult.none) {
      return Text(value);
    }

    if (result == ComparisonResult.equal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value),
          const SizedBox(height: 2),
          const Text(
            'Equal',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // In comparison.dart, ComparisonResult.higher means this row's value
    // should be treated as the better value. For inverse rows, that better
    // value is actually the lower numeric value.
    final isBetter = result == ComparisonResult.higher;

    final color = isBetter ? Colors.greenAccent : Colors.redAccent;

    final icon = lowerIsBetter
        ? (isBetter ? Icons.arrow_downward : Icons.arrow_upward)
        : (isBetter ? Icons.arrow_upward : Icons.arrow_downward);

    final prefix = lowerIsBetter
        ? (isBetter ? '-' : '+')
        : (isBetter ? '+' : '-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$prefix$differenceText',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                Text(
                  'RevFinder',
                  style: TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 40),

                // Search bar that gets motorcycle suggestions from the backend.
                SearchAnchor.bar(
                  barHintText: 'Search make, model, or year ...',
                  barLeading: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  barBackgroundColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest,
                  ),
                  barOverlayColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest,
                  ),
                  barElevation: const WidgetStatePropertyAll(2.0),
                  barTextStyle: WidgetStatePropertyAll(
                    TextStyle(color: colorScheme.onSurface),
                  ),
                  barHintStyle: WidgetStatePropertyAll(
                    TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  barPadding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  barShape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                  ),
                  suggestionsBuilder: (
                    BuildContext context,
                    SearchController controller,
                  ) async {
                    // Empty search case.
                    if (controller.text.isEmpty) {
                      return const Iterable<Widget>.empty();
                    }

                    try {
                      // Encode spaces so searches like "Ninja 400" do not break.
                      final encodedQuery = Uri.encodeQueryComponent(
                        controller.text,
                      );

                      final response = await _apiService.fetchData(
                        '/api/motorcycles/search?model=$encodedQuery',
                      );

                      // Convert JSON response into Motorcycle objects.
                      final List<dynamic> data = response as List<dynamic>;

                      final motorcycles = data
                          .whereType<Map>()
                          .map(
                            (json) => Motorcycle.fromJson(
                              Map<String, dynamic>.from(json),
                            ),
                          )
                          .toList();

                      return motorcycles.map((bike) {
                        return ListTile(
                          title: Text('${bike.make} ${bike.model}'),
                          subtitle: Text(bike.year),
                          onTap: () async {
                            // Fetch detailed specs after user selects a bike.
                            final hydratedBike =
                                await _fetchHydratedMotorcycle(bike);

                            if (!mounted) return;

                            setState(() {
                              final alreadyExists = selectedBikes.any(
                                (b) =>
                                    _normalizeForMatch(b.make) ==
                                        _normalizeForMatch(hydratedBike.make) &&
                                    _normalizeForMatch(b.model) ==
                                        _normalizeForMatch(hydratedBike.model),
                              );

                              // Add the selected bike if it is not already selected.
                              if (!alreadyExists && selectedBikes.length < 2) {
                                selectedBikes.add(hydratedBike);
                              }
                            });

                            // Close search bar after selection.
                            controller.closeView('');
                          },
                        );
                      });
                    } catch (e) {
                      return [
                        ListTile(
                          title: Text('Error fetching bikes: $e'),
                        ),
                      ];
                    }
                  },
                ),

                if (selectedBikes.length == 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final comparison = currentComparison;

                        if (comparison == null) return;

                        showDialog(
                          context: context,
                          builder: (_) => _buildComparisonDialog(comparison),
                        );
                      },
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Compare Motorcycles'),
                    ),
                  ),

                const SizedBox(height: 40),

                // Shows only the main selected motorcycle cards.
                _buildComparisonSection(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds the pop-up comparison dialog.
  //
  // This is where the full expanded specs appear.
  Widget _buildComparisonDialog(Comparison comparison) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      title: Text(
        'Motorcycle Comparison',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      content: SizedBox(
        width: 850,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Spec',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${comparison.bike1.make} ${comparison.bike1.model}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${comparison.bike2.make} ${comparison.bike2.model}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Build every full comparison row from comparison.dart.
              //
              // Numeric rows show green/red arrows and the difference amount.
              // Text rows show normally.
              ...comparison.comparisonRows.map((row) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          row.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildComparisonValue(
                          value: row.bike1,
                          result: row.bike1Result,
                          differenceText: row.differenceText,
                          lowerIsBetter: row.lowerIsBetter,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildComparisonValue(
                          value: row.bike2,
                          result: row.bike2Result,
                          differenceText: row.differenceText,
                          lowerIsBetter: row.lowerIsBetter,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  // Builds the main selected motorcycle card section.
  //
  // Important:
  // This section intentionally displays ONLY the main specs.
  // The detailed/expanded specs are hidden until the user presses
  // the "Compare Motorcycles" button.
  Widget _buildComparisonSection() {
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedBikes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'Search and select 2 motorcycles to compare.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,

        // Convert each selected bike into a visual card.
        children: selectedBikes.map((bike) {
          return Expanded(
            child: Card(
              elevation: 4,
              color: colorScheme.surfaceContainerHigh,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header with motorcycle name and remove button.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${bike.make} ${bike.model}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedBikes.remove(bike);
                            });
                          },
                        ),
                      ],
                    ),

                    Text(
                      bike.year,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),

                    const Divider(),

                    // Only the main specs show here.
                    _buildSectionTitle('Main Specs'),
                    _buildSpecRow('Engine', bike.engine),
                    _buildSpecRow('Horsepower', bike.power),
                    _buildSpecRow('Torque', bike.torque),
                    _buildSpecRow('Weight', bike.weight),
                    _buildSpecRow('Seat Height', bike.seatHeight),
                    _buildSpecRow('Transmission', bike.transmission),

                    const SizedBox(height: 12),

                    // Small hint so the user knows where the detailed specs are.
                    if (selectedBikes.length == 2)
                      Text(
                        'Press Compare Motorcycles to view full specs.',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Small title used to separate sections inside each comparison card.
  Widget _buildSectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  // Builds one label/value row inside a motorcycle card.
  Widget _buildSpecRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}