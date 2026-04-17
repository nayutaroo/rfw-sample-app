import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'pages/basic_demo_page.dart';
import 'pages/data_binding_page.dart';
import 'pages/live_editor_page.dart';

const _appTitle = 'RFW Sample';

void main() {
  runApp(const RfwSampleApp());
}

class RfwSampleApp extends StatelessWidget {
  const RfwSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  static const _pages = [
    BasicDemoPage(),
    DataBindingPage(),
    LiveEditorPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);

    return Scaffold(
      body: _pages[currentIndex.value],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.value,
        onDestinationSelected: (i) => currentIndex.value = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Basic',
          ),
          NavigationDestination(
            icon: Icon(Icons.data_object_outlined),
            selectedIcon: Icon(Icons.data_object),
            label: 'Data Binding',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Live Editor',
          ),
        ],
      ),
    );
  }
}
