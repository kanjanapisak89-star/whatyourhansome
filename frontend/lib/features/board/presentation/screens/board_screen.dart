import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Board'),
      ),
      body: const Center(
        child: Text('Board Screen - Submit Questions'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Question submission form - coming soon
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
