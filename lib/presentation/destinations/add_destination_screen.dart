import 'package:flutter/material.dart';

/// Add/Edit destination screen - TO BE IMPLEMENTED
class AddDestinationScreen extends StatelessWidget {
  final String? destinationId;

  const AddDestinationScreen({
    super.key,
    this.destinationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destinationId == null ? 'Add Destination' : 'Edit Destination'),
      ),
      body: const Center(
        child: Text('Add/Edit destination screen coming soon...'),
      ),
    );
  }
}
