// main.dart
//
// Main Flutter UI for RevFinder.
//
// Premium dark motorcycle search (#121212 surface, purple accents).
// Airbnb-style pinned search capsule; swipe-friendly selection cards.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'apiservice.dart';
import 'auth_page.dart';
import 'comparison.dart';
import 'comparison_modal.dart';
import 'motorcycle.dart';

const Color _kAppSurface = Color(0xFF121212);
const Color _kSearchPillFill = Color(0xFF1E1E1E);

/// Replace with your Supabase project URL (Dashboard → Settings → API).
const String kSupabaseUrl = 'https://tgkhaqhxyhkdlgmmfgey.supabase.co';

/// Replace with your Supabase anon public key (Dashboard → Settings → API).
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRna2hhcWh4eWhrZGxnbW1mZ2V5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxODc2MDAsImV4cCI6MjA5Mzc2MzYwMH0.BFdpEE9Ks9fwRxOsZVeSCjHUVGjvrVtEpL1lPUsEH28';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

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

      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Shows [SearchPage] when a Supabase session exists, otherwise [AuthPage].
/// Listens to auth changes so login/sign-out updates the root without manual routes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSub;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (!mounted) return;
        setState(() => _session = data.session);
      },
    );
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session != null) {
      return const SearchPage();
    }
    return const AuthPage();
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
  static const List<String> _suggestedComparisonLabels = [
    'Kawasaki Z400 vs Honda CB500F',
    'Yamaha MT-07 vs Suzuki SV650',
    'BMW R nineT vs Triumph Bonneville',
  ];
  bool _loadingSuggestedComparison = false;

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

  Future<Motorcycle?> _searchFirstMotorcycle(String query) async {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final response = await _apiService.fetchData(
      '/api/motorcycles/search?model=$encodedQuery',
    );
    if (response is! List || response.isEmpty) return null;

    for (final item in response) {
      if (item is Map) {
        return Motorcycle.fromJson(Map<String, dynamic>.from(item));
      }
    }

    return null;
  }

  Future<void> _selectSuggestedComparison(String label) async {
    final parts = label.split(' vs ');
    if (parts.length != 2 || _loadingSuggestedComparison) return;

    setState(() => _loadingSuggestedComparison = true);
    try {
      final first = await _searchFirstMotorcycle(parts[0]);
      final second = await _searchFirstMotorcycle(parts[1]);
      if (first == null || second == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load suggested comparison.')),
        );
        return;
      }

      final hydratedFirst = await _fetchHydratedMotorcycle(first);
      final hydratedSecond = await _fetchHydratedMotorcycle(second);
      if (!mounted) return;

      setState(() {
        selectedBikes
          ..clear()
          ..add(hydratedFirst)
          ..add(hydratedSecond);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suggested comparison failed.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingSuggestedComparison = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _kAppSurface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'RevFinder',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Find and compare motorcycles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStickySearchPill(colorScheme),
                      const SizedBox(height: 10),
                      _buildSuggestedComparisonChips(colorScheme),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Opacity(
                    opacity: selectedBikes.length >= 2 ? 1.0 : 0.4,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: selectedBikes.length >= 2
                          ? () {
                              final comparison = currentComparison;
                              if (comparison == null) return;
                              ComparisonModal.show(
                                context,
                                comparison: comparison,
                                apiService: _apiService,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.compare_arrows_rounded),
                      label: const Text(
                        'Compare motorcycles',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                    child: _buildComparisonSection(colorScheme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickySearchPill(ColorScheme colorScheme) {
    final accentPurple = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 10),
            blurRadius: 28,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SearchAnchor.bar(
          barHintText: 'Search make, model, or year',
          barLeading: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.search_rounded,
              size: 26,
              color: accentPurple.withValues(alpha: 0.9),
            ),
          ),
          barTrailing: [],
          barBackgroundColor: const WidgetStatePropertyAll(_kSearchPillFill),
          barOverlayColor: const WidgetStatePropertyAll(_kSearchPillFill),
          barElevation: WidgetStatePropertyAll(0),
          barTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.95),
              fontWeight: FontWeight.w400,
            ),
          ),
          barHintStyle: WidgetStatePropertyAll(
            TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          barPadding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 17,
            ),
          ),
          barShape: WidgetStatePropertyAll(
            const StadiumBorder(),
          ),
          suggestionsBuilder: (
            BuildContext context,
            SearchController controller,
          ) async {
            if (controller.text.isEmpty) {
              return const Iterable<Widget>.empty();
            }

            try {
              final encodedQuery = Uri.encodeQueryComponent(controller.text);

              final response = await _apiService.fetchData(
                '/api/motorcycles/search?model=$encodedQuery',
              );

              final List<dynamic> data = response as List<dynamic>;

              final motorcycles = data
                  .whereType<Map>()
                  .map(
                    (json) => Motorcycle.fromJson(
                      Map<String, dynamic>.from(json),
                    ),
                  )
                  .toList();

              if (motorcycles.isEmpty) {
                return const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No results found from API'),
                    ),
                  ),
                ];
              }

              return motorcycles.map((bike) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Text(
                      '${bike.make} ${bike.model}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(bike.year),
                    onTap: () async {
                      final hydratedBike = await _fetchHydratedMotorcycle(bike);

                      if (!mounted) return;

                      setState(() {
                        final alreadyExists = selectedBikes.any(
                          (b) =>
                              _normalizeForMatch(b.make) ==
                                  _normalizeForMatch(hydratedBike.make) &&
                              _normalizeForMatch(b.model) ==
                                  _normalizeForMatch(hydratedBike.model),
                        );

                        if (!alreadyExists && selectedBikes.length < 2) {
                          selectedBikes.add(hydratedBike);
                        }
                      });

                      controller.closeView('');
                    },
                  ),
                );
              });
            } catch (e) {
              debugPrint('SEARCH UI ERROR: $e');
              return [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ];
            }
          },
        ),
      ),
    );
  }

  Widget _buildSuggestedComparisonChips(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestedComparisonLabels.map((label) {
        return ActionChip(
          onPressed: _loadingSuggestedComparison
              ? null
              : () => _selectSuggestedComparison(label),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          backgroundColor: Colors.transparent,
          label: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparisonSection(ColorScheme colorScheme) {
    final muted = colorScheme.onSurfaceVariant.withValues(alpha: 0.75);

    if (selectedBikes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              size: 46,
              color: muted.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Search above to add motorcycles to your list.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: muted,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick two bikes to unlock full comparisons.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: muted.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: selectedBikes.map((bike) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: bike == selectedBikes.last ? 0 : 10,
              left: bike == selectedBikes.first ? 0 : 10,
            ),
            child: _SelectionCard(
              bike: bike,
              colorScheme: colorScheme,
              onRemove: () {
                setState(() => selectedBikes.remove(bike));
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.bike,
    required this.colorScheme,
    required this.onRemove,
  });

  final Motorcycle bike;
  final ColorScheme colorScheme;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cardBg = colorScheme.surfaceContainerHigh;
    final primary = colorScheme.primary;

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.make.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.05,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bike.model,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        bike.year,
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  splashRadius: 22,
                  icon: Icon(Icons.close_rounded, color: colorScheme.error),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CheckboxTheme(
                    data: CheckboxThemeData(
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return primary;
                        }
                        return Colors.transparent;
                      }),
                      side: BorderSide(width: 1.25, color: primary),
                      shape: const CircleBorder(),
                    ),
                    child: Checkbox(
                      value: true,
                      onChanged: (v) {
                        if (v == false) onRemove();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Compare',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}