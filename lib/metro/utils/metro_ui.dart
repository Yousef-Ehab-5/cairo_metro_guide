import 'package:flutter/material.dart';

import '../online.dart';

Color lineColor(int line) {
  switch (line) {
    case 1:
      return const Color(0xFF175CD3);
    case 2:
      return const Color(0xFFB3261E);
    case 3:
      return const Color(0xFF13795B);
    default:
      return Colors.grey;
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<void> openStationMap(
  BuildContext context,
  String stationName,
) async {
  try {
    await onlineMetro.openStationMap(stationName);
  } catch (error) {
    if (context.mounted) {
      showMessage(context, error.toString());
    }
  }
}
