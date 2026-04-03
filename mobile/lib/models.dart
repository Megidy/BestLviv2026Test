import 'package:flutter/material.dart';

enum AppScreen {
  login,
  home,
  detail,
  demand,
  scanner,
}

enum UrgencyLevel {
  normal,
  elevated,
  critical,
}

class ResourceRecord {
  const ResourceRecord({
    required this.name,
    required this.code,
    required this.manufacturer,
    required this.location,
    required this.currentStock,
    required this.threshold,
    required this.lastSync,
    required this.lastAudited,
    required this.receipt,
  });

  final String name;
  final String code;
  final String manufacturer;
  final String location;
  final String currentStock;
  final String threshold;
  final String lastSync;
  final String lastAudited;
  final String receipt;
}

class QueueItem {
  const QueueItem({
    required this.name,
    required this.code,
    required this.age,
    required this.status,
    required this.accent,
    required this.icon,
  });

  final String name;
  final String code;
  final String age;
  final String status;
  final Color accent;
  final IconData icon;
}
