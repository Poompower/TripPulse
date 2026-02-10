import 'package:flutter/material.dart';

import '../models/place.dart';
import '../../models/trip.dart';
import '../services/places_service.dart';
import '../../services/database_service.dart';

import '../../widgets/custom_bottom_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/place_card_widget.dart';
import '../widgets/day_selector_bottom_sheet_widget.dart';
import '../widgets/filter_bottom_sheet_widget.dart';

class PlacesSearchScreen extends StatefulWidget {
  final String destinationName;
  final double? lat;
  final double? lon;

  const PlacesSearchScreen({
    super.key,
    required this.destinationName,
    this.lat,
    this.lon,
  });

  @override
  State<PlacesSearchScreen> createState() => _PlacesSearchScreenState();
}

class _PlacesSearchScreenState extends State<PlacesSearchScreen> {
  final PlacesService _placesService = PlacesService();
  final DatabaseService _databaseService = DatabaseService();

  // Search attractions controller
  final TextEditingController _searchController = TextEditingController();

  // ===== Search place context =====
  String _currentPlaceName = '';
  double? _currentLat;
  double? _currentLon;

  // ===== Filters =====
  Set<String> _selectedCategories = {};

  // ===== UI state =====
  bool _isLoading = false;
  String? _error;
  List<Place> _places = [];

  @override
  void initState() {
    super.initState();

    // initial context from trip destination
    _currentPlaceName = widget.destinationName;
    _currentLat = widget.lat;
    _currentLon = widget.lon;

    _searchController.text = '';
    _searchPlaces();
  }

  // ==========================================================
  // 🔍 Search place (Tokyo, Japan → geocode → lat/lon)
  // ==========================================================
  Future<void> _searchPlace(String placeName) async {
    if (placeName.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _placesService.geocodePlace(placeName);

      if (!mounted) return;

      setState(() {
        _currentPlaceName = placeName;
        _currentLat = result.lat;
        _currentLon = result.lon;
      });

      // after geocode → reload attractions
      await _searchPlaces();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Place not found';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==========================================================
  // 🔎 Search attractions (radius 5000, category filter)
  // ==========================================================
  Future<void> _searchPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _placesService.searchPlaces(
        query: _searchController.text,
        lat: _currentLat,
        lon: _currentLon,
        categories:
            _selectedCategories.isNotEmpty ? _selectedCategories.toList() : null,
      );

      if (!mounted) return;

      setState(() {
        _places = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==========================================================
  // 🏷 Open filter bottom sheet
  // ==========================================================
  Future<void> _openFilter() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheetWidget(
        selectedCategories: _selectedCategories,
        onApplyFilters: (categories) {
          setState(() {
            _selectedCategories = categories;
          });
          _searchPlaces();
        },
      ),
    );
  }

  // ==========================================================
  // ➕ Add Place → Select Trip → Select Day
  // ==========================================================
  Future<void> _onAddPlace(Place place) async {
    final trips = await _databaseService.trips();
    if (!mounted) return;

    final placeCountry = place.country?.toLowerCase();

    if (placeCountry == null || placeCountry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot determine country for this place')),
      );
      return;
    }

    // filter trip by country (Japan-level)
    final matchedTrips = trips.where((trip) {
      return trip.destination.toLowerCase().contains(placeCountry);
    }).toList();

    if (matchedTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trips match this place country')),
      );
      return;
    }

    // select trip
    final Trip? selectedTrip = await showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: matchedTrips.map((trip) {
            return ListTile(
              title: Text(trip.title),
              subtitle: Text(trip.destination),
              onTap: () => Navigator.pop(context, trip),
            );
          }).toList(),
        );
      },
    );

    if (selectedTrip == null || !mounted) return;

    // select day (real insert)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DaySelectorBottomSheetWidget(
        place: place,
        trip: selectedTrip,
      ),
    );
  }

  // ==========================================================
  // UI helpers
  // ==========================================================
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_places.isEmpty) {
      return const Center(child: Text('No places found'));
    }

    return ListView.builder(
      itemCount: _places.length,
      itemBuilder: (_, index) {
        final place = _places[index];
        return PlaceCardWidget(
          place: place,
          onTap: () {
            // future: place detail
          },
          onAdd: () => _onAddPlace(place),
        );
      },
    );
  }

  // ==========================================================
  // Build
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlaceName.isNotEmpty
            ? 'Places in $_currentPlaceName'
            : 'Search Places'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'Search place',
            onPressed: () {
              final controller = TextEditingController();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Search place'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Tokyo, Japan',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _searchPlace(controller.text);
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            CustomBottomBar.navigateToIndex(context, index);
          }
        },
        variant: BottomBarVariant.material3,
        showLabels: true,
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            onSearch: _searchPlaces,
            onOpenFilter: _openFilter,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
