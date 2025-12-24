import 'package:flutter/material.dart';
import 'package:ui_market_example/ui/generated/ui_routes.g.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Market Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Register generated routes
      routes: UIRoutes.routes,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Market Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Installed Packs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ..._buildPackList(context),
        ],
      ),
    );
  }

  List<Widget> _buildPackList(BuildContext context) {
    final packRoutes = UIRoutes.routesByPack;

    if (packRoutes.isEmpty) {
      return [
        const Center(
            child: Text('No packs installed. Run "ui_market add <pack>"')),
      ];
    }

    return packRoutes.entries.expand((entry) {
      final packName = entry.key;
      final routes = entry.value;

      return [
        Text(packName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...routes.map((route) => Card(
              child: ListTile(
                title: Text(route),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pushNamed(context, route);
                },
              ),
            )),
        const Divider(height: 32),
      ];
    }).toList();
  }
}
