// Owner: Member 1.
import 'package:flutter/material.dart';
import '../models/station.dart';

class StationSelector extends StatelessWidget {
  final String title;
  final Station? selectedStation;
  final VoidCallback? onTap;
  final VoidCallback? onLocationPressed;

  const StationSelector({
    super.key,
    required this.title,
    this.selectedStation,
    this.onTap,
    this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(selectedStation?.nameEn ?? 'Tap to select a station'),
        onTap: onTap,
        trailing: IconButton(
          tooltip: 'Show station location',
          onPressed: onLocationPressed,
          icon: const Icon(Icons.location_on_outlined),
        ),
      ),
    );
  }
}
