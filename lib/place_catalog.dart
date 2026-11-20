import 'package:flutter/material.dart';

// Photo and category badge for each destination, so Profile and Edit
// Schedule Trip can show the same place image that Search uses.
class PlaceInfo {
  const PlaceInfo({
    required this.imageAsset,
    required this.badge,
    required this.badgeColor,
  });

  final String imageAsset;
  final String badge;
  final Color badgeColor;
}

class PlaceCatalog {
  static const _historical = Color(0xFF1E88E5);
  static const _food = Color(0xFFE59A12);
  static const _nature = Color(0xFF00897B);
  static const _leisure = Color(0xFF55995C);

  static const _places = <String, PlaceInfo>{
    'ILOMOCA': PlaceInfo(
      imageAsset: 'assets/images/search-ilomoca.jpg',
      badge: 'HISTORICAL',
      badgeColor: _historical,
    ),
    'The Granary': PlaceInfo(
      imageAsset: 'assets/images/search-granary.jpg',
      badge: 'FOOD',
      badgeColor: _food,
    ),
    'Iloilo River Esplanade': PlaceInfo(
      imageAsset: 'assets/images/search-esplanade.jpg',
      badge: 'NATURE',
      badgeColor: _nature,
    ),
    'Festive Walk Mall': PlaceInfo(
      imageAsset: 'assets/images/search-festive.jpg',
      badge: 'LEISURE',
      badgeColor: _leisure,
    ),
  };

  // Returns null for a destination that has no saved photo.
  static PlaceInfo? lookup(String destination) => _places[destination];
}
