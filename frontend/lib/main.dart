// main.dart
//
// Main Flutter UI for RevFinder.
//
// Updated behavior:
// - When a user selects a motorcycle, the card only shows the main specs.
// - The full expanded specs only appear when the user presses
//   the "Compare Motorcycles" button.
// - This keeps the first result view cleaner and makes the comparison dialog
//   the place for detailed analysis.
//
// Important fix:
// - The backend may return either a List of motorcycles OR a single JSON object.
// - The previous version only handled List responses.
// - This version handles both List and Map responses so parsed values and
//   backend-calculated scores can reach the frontend.

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 34, 8, 78),
        ),
      ),
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
  //
  // This version accepts both:
  // - Map<String, dynamic>
  // - generic Map values
  //
  // This prevents Flutter from skipping valid backend JSON objects.
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
  //
  // Important:
  // The backend may return either:
  // 1. A List of motorcycle JSON objects
  // 2. A single motorcycle JSON object as a Map
  //
  // The previous version only handled List responses.
  // If the backend returned a Map, Flutter ignored it and kept the original
  // search result, which caused parsed values and scores to stay null.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                const Text(
                  'RevFinder',
                  style: TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                  ),
                ),

                const SizedBox(height: 40),

                // Search bar that gets motorcycle suggestions from the backend.
                SearchAnchor.bar(
                  barHintText: 'Search make, model, or year ...',
                  barLeading: const Icon(Icons.search),
                  barBackgroundColor: const WidgetStatePropertyAll(
                    Colors.white,
                  ),
                  barElevation: const WidgetStatePropertyAll(2.0),
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
                            //
                            // The selected card will still only show main specs,
                            // but the comparison dialog can use the expanded specs.
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
    return AlertDialog(
      title: const Text('Motorcycle Comparison'),
      content: SizedBox(
        width: 850,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Spec',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${comparison.bike1.make} ${comparison.bike1.model}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${comparison.bike2.make} ${comparison.bike2.model}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Build every full comparison row from comparison.dart.
              //
              // This includes:
              // - Scores
              // - Main specs
              // - Expanded numeric specs
              // - Expanded build specs
              ...comparison.comparisonRows.map((row) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          row['label'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(row['bike1'] ?? 'N/A'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Text(row['bike2'] ?? 'N/A'),
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
    if (selectedBikes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('Search and select 2 motorcycles to compare.'),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
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
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const Divider(),

                    // Only the main specs show here.
                    //
                    // Do NOT place expanded specs here, because the user wants
                    // those to appear only inside the comparison dialog.
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
                      const Text(
                        'Press Compare Motorcycles to view full specs.',
                        style: TextStyle(
                          color: Colors.grey,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  // Builds one label/value row inside a motorcycle card.
  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
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