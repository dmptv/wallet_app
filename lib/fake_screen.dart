import 'package:flutter/material.dart';

import 'features/transactions/transaction_screen.dart';

// widget that rebuild but keeps its state alive across rebuilds
class TreeDemoScreen extends StatefulWidget {
  const TreeDemoScreen({super.key});

  @override
  State<TreeDemoScreen> createState() => _TreeDemoScreenState();
}

// Here state that survives rebuilds is kept in the State object, not in the widget itself. This allows the state to persist even when the widget is rebuilt due to changes in its parent or other factors.
class _TreeDemoScreenState extends State<TreeDemoScreen> {

  bool swapped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tree Demo Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (!swapped) ...[
                    const CounterBox(key: ValueKey('a'), label: 'A'),
                    const CounterBox(key: ValueKey('b'), label: 'B'),
                  ] else ...[
                    const CounterBox(key: ValueKey('b'), label: 'B'),
                    const CounterBox(key: ValueKey('a'), label: 'A'),
                  ]
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // This button is just for display; it doesn't do anything
                setState(() {
                  swapped = !swapped;
                  // Trigger a rebuild of the TreeDemoScreen
                });
              },
              child: const Text('Swap Elements'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionScreen()),
                );
              },
              child: const Text('Open Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}

class CounterBox extends StatefulWidget { 
  final String label;

  const CounterBox({super.key, required this.label});
  
  @override
  State<CounterBox> createState() => _CounterBoxState();
}

class _CounterBoxState extends State<CounterBox> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    print('initState');
  } 

  @override
  Widget build(BuildContext context) {
    print('build, widget hash = ${identityHashCode(widget)}');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${widget.label}: $counter', style: const TextStyle(fontSize: 40)),
        ElevatedButton(
          onPressed: () {
            setState(() {
              counter++;
            });
          },
          child: const Text('Increment Counter'),
        ),
      ],
    );
  }
}