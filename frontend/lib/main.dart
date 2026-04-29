import 'package:flutter/material.dart';
import 'motorcycle.dart';
import 'apiservice.dart';
import 'comparison.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RevFinder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 34, 8, 78)),
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
  // Handle memory for comparison (store a motorcycle object here)
  List<Motorcycle> selectedBikes = [];
  final ApiService _apiService = ApiService();

  Comparison? get currentComparison {
    if (selectedBikes.length == 2) {
      return Comparison(
        bike1: selectedBikes[0],
        bike2: selectedBikes[1],
      );
    }
    return null;
  }

  String _normalizeForMatch(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Motorcycle _pickBestSpecMatch(
    List<dynamic> specsData,
    Motorcycle selectedSuggestion,
  ) {
    final normalizedTargetModel = _normalizeForMatch(selectedSuggestion.model);
    final normalizedTargetMake = _normalizeForMatch(selectedSuggestion.make);

    for (final item in specsData) {
      if (item is! Map<String, dynamic>) continue;
      final candidate = Motorcycle.fromJson(item);
      final candidateModel = _normalizeForMatch(candidate.model);
      final candidateMake = _normalizeForMatch(candidate.make);
      if (candidateMake == normalizedTargetMake &&
          candidateModel == normalizedTargetModel) {
        return candidate;
      }
    }

    // If exact model text does not match due to formatting differences,
    // use the first result for the selected make/model request.
    for (final item in specsData) {
      if (item is Map<String, dynamic>) {
        return Motorcycle.fromJson(item);
      }
    }

    return selectedSuggestion;
  }

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

    if (response is List<dynamic> && response.isNotEmpty) {
      return _pickBestSpecMatch(response, selectedSuggestion);
    }

    // Keep suggestion result if specs endpoint has no matching records.
    return selectedSuggestion;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ), // Widened for 3 cards
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
                SearchAnchor.bar(
                  barHintText: 'Search make, model, or year ...',
                  barLeading: const Icon(Icons.search),
                  barBackgroundColor: const WidgetStatePropertyAll<Color>(
                    Colors.white,
                  ),
                  barElevation: const WidgetStatePropertyAll<double>(2.0),
                  barPadding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  barShape: WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                  ),
                  suggestionsBuilder:
                      (
                        BuildContext context,
                        SearchController controller,
                      ) async {
                        // Empty search case
                        if (controller.text.isEmpty) {
                          return const Iterable<Widget>.empty();
                        }

                        // Call API service to fetch motorcycles based on the search query
                        try {
                          // Safely encode spaces so "Ninja 400" doesn't break the URL
                          final encodedQuery = Uri.encodeQueryComponent(
                            controller.text,
                          );
                          final response = await _apiService.fetchData(
                            '/api/motorcycles/search?model=$encodedQuery',
                          );

                          // Convert JSON into a list of Motorcycle objects
                          final List<dynamic> data = response as List<dynamic>;
                          final motorcycles = data
                              .map((json) => Motorcycle.fromJson(json))
                              .toList();

                          // Create ListTile for each found Motorcycle
                          return motorcycles.map((bike) {
                            return ListTile(
                              title: Text('${bike.make} ${bike.model}'),
                              subtitle: Text(bike.year),
                              onTap: () async {
                                final hydratedBike =
                                    await _fetchHydratedMotorcycle(bike);
                                if (!mounted) return;

                                setState(() {
                                  // Duplicate checking
                                  bool alreadyExists = selectedBikes.any(
                                    (b) =>
                                        _normalizeForMatch(b.make) ==
                                            _normalizeForMatch(
                                              hydratedBike.make,
                                            ) &&
                                        _normalizeForMatch(b.model) ==
                                            _normalizeForMatch(
                                              hydratedBike.model,
                                            ),
                                  );

                                  // Add if new and less than 2 bikes selected
                                  if (!alreadyExists &&
                                      selectedBikes.length < 2) {
                                    selectedBikes.add(hydratedBike);
                                  }
                                });

                                // Close search bar after selection
                                controller.closeView('');
                              },
                            );
                          });
                        } catch (e) {
                          return [
                            ListTile(title: Text('Error fetching bikes: $e')),
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
                // COMPARISON UI
                _buildComparisonSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonDialog(Comparison comparison) {
    return AlertDialog(
      title: const Text('Motorcycle Comparison'),
      content: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${comparison.bike1.make} ${comparison.bike1.model}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${comparison.bike2.make} ${comparison.bike2.model}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...comparison.comparisonRows.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row['label']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(flex: 3, child: Text(row['bike1']!)),
                    Expanded(flex: 3, child: Text(row['bike2']!)),
                  ],
                ),
              );
            }),
          ],
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

  // COMPARISON
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
        // Map our selected bikes into visual Cards
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
                    // Header with close button
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
                            // Remove bike from comparison
                            setState(() {
                              selectedBikes.remove(bike);
                            });
                          },
                        ),
                      ],
                    ),
                    Text(bike.year, style: const TextStyle(color: Colors.grey)),
                    const Divider(),

                    // Specs
                    _buildSpecRow('Engine', bike.engine),
                    _buildSpecRow('Horsepower', bike.power),
                    _buildSpecRow('Weight', bike.weight),
                    _buildSpecRow('Seat Height', bike.seatHeight),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
