import 'package:flutter/material.dart';

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
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
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


// --------------------- SEARCH BAR & TITLE ---------------------
class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                barBackgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
                barElevation: const WidgetStatePropertyAll<double>(2.0),
                barPadding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 16.0)
                ),
                barShape: WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
                ),
                suggestionsBuilder: (BuildContext context, SearchController controller) {
                  
                  // Suggestion inputs handled by filtering/querying logic from backend
                  return const Iterable<Widget>.empty();
                },
              )
            ],
          ),
        ),
        
      )
    );
  }
}

