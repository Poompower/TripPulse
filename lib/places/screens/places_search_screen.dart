import 'package:flutter/material.dart';

import '../../trips/models/trip.dart';
import '../../trips/services/database_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../models/place.dart';
import '../services/places_service.dart';
import '../widgets/category_filter_chips_widget.dart';
import '../widgets/day_selector_bottom_sheet_widget.dart';
import '../widgets/filter_bottom_sheet_widget.dart';
import '../widgets/place_card_widget.dart';
import '../widgets/search_bar_widget.dart';

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

  // Search attractions inside current place results.
  final TextEditingController _searchController = TextEditingController();

  // Search place context (e.g., Tokyo, Japan).
  final TextEditingController _placeController = TextEditingController();

  String _currentPlaceName = '';
  double? _currentLat;
  double? _currentLon;

  List<({String name, double lat, double lon})> _suggestions = [];

  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];

  Set<String> _selectedCategories = {};
  List<Map<String, dynamic>> _categoryData = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _currentPlaceName = widget.destinationName;
    _currentLat = widget.lat;
    _currentLon = widget.lon;

    debugPrint('INIT -> $_currentPlaceName');
    _searchPlaces();
  }

  Future<void> _onSearchPlaceChanged(String value) async {
    debugPrint('Autocomplete typing: $value');

    if (value.trim().length < 3) {
      debugPrint('Autocomplete skipped (<3 chars)');
      setState(() => _suggestions = []);
      return;
    }

    try {
      final results = await _placesService.searchPlaceSuggestions(value);
      if (!mounted) return;

      debugPrint('Autocomplete result count: ${results.length}');
      setState(() => _suggestions = results);
    } catch (e) {
      debugPrint('Autocomplete ERROR: $e');
      if (!mounted) return;
      setState(() => _suggestions = []);
    }
  }

  Future<void> _onSelectPlaceSuggestion(
    ({String name, double lat, double lon}) place,
  ) async {
    debugPrint('Selected place: ${place.name}');
    FocusScope.of(context).unfocus();

    setState(() {
      _currentPlaceName = place.name;
      _currentLat = place.lat;
      _currentLon = place.lon;
      _suggestions = [];
      _placeController.text = place.name;
    });

    await _searchPlaces();
  }

  // Load place results from API and then apply local filter once.
  Future<void> _searchPlaces() async {
    debugPrint('---- API CALL ----');
    debugPrint('Lat/Lon: $_currentLat / $_currentLon');
    debugPrint('Query: ${_searchController.text}');

    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _placesService.searchPlaces(
        query: _searchController.text,
        lat: _currentLat,
        lon: _currentLon,
      );

      debugPrint('API result count: ${results.length}');
      if (!mounted) return;

      setState(() {
        _allPlaces = results;
        _buildCategoryData();
      });

      _applyLocalFilter();

      debugPrint('Places loaded: ${_allPlaces.length}');
      debugPrint('Categories built: ${_categoryData.length}');
    } catch (e) {
      debugPrint('SEARCH ERROR: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _allPlaces = [];
        _filteredPlaces = [];
        _categoryData = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Client-side filter by selected categories and search text.
  void _applyLocalFilter() {
    debugPrint('Applying local filter: $_selectedCategories');

    final searchText = _searchController.text.trim().toLowerCase();

    _filteredPlaces = _allPlaces.where((place) {
      final matchCategory =
          _selectedCategories.isEmpty ||
          _selectedCategories.any(
            (cat) => place.category.toLowerCase().contains(cat.toLowerCase()),
          );

      final matchSearch =
          searchText.isEmpty || place.name.toLowerCase().contains(searchText);

      return matchCategory && matchSearch;
    }).toList();

    debugPrint('Filtered result count: ${_filteredPlaces.length}');
    setState(() {});
  }

  Future<void> _openFilter() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheetWidget(
        selectedCategories: _selectedCategories,
        onApplyFilters: (categories) {
          debugPrint('Filter applied: $categories');
          _selectedCategories = categories;
          _applyLocalFilter();
        },
      ),
    );
  }

  void _buildCategoryData() {
    final Map<String, int> counter = {};

    for (final place in _allPlaces) {
      final cat = place.category;
      if (cat.isNotEmpty) {
        counter[cat] = (counter[cat] ?? 0) + 1;
      }
    }

    _categoryData = counter.entries
        .map((e) => {'name': e.key, 'count': e.value})
        .toList();
  }

  Future<void> _onAddPlace(Place place) async {
    debugPrint('Add place: ${place.name}');
    final trips = await _databaseService.trips();
    if (!mounted) return;

    final placeCountry = place.country?.toLowerCase();
    final placeCountryCode = place.countryCode?.toUpperCase();

    final matchedTrips = trips.where((trip) {
      if (placeCountryCode != null &&
          placeCountryCode.isNotEmpty &&
          trip.countryCode != null &&
          trip.countryCode!.isNotEmpty) {
        return trip.countryCode!.toUpperCase() == placeCountryCode;
      }

      if (placeCountry != null &&
          placeCountry.isNotEmpty &&
          trip.country != null &&
          trip.country!.isNotEmpty) {
        return trip.country!.toLowerCase() == placeCountry;
      }

      return trip.destination.toLowerCase().contains(placeCountry ?? '');
    }).toList();

    if (matchedTrips.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No matching trips')));
      return;
    }

    final Trip? selectedTrip = await showModalBottomSheet<Trip>(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: matchedTrips.map((trip) {
          return ListTile(
            title: Text(trip.title),
            subtitle: Text(trip.destination),
            onTap: () => Navigator.pop(context, trip),
          );
        }).toList(),
      ),
    );

    if (!mounted) return;
    if (selectedTrip == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) =>
          DaySelectorBottomSheetWidget(place: place, trip: selectedTrip),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      debugPrint('UI -> loading');
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      debugPrint('UI -> error: $_error');
      return Center(child: Text(_error!));
    }

    if (_filteredPlaces.isEmpty) {
      debugPrint('UI -> empty');
      return const Center(child: Text('No places found'));
    }

    return ListView.builder(
      itemCount: _filteredPlaces.length,
      itemBuilder: (_, index) {
        final place = _filteredPlaces[index];
        return PlaceCardWidget(
          place: place,
          onTap: () {},
          onAdd: () => _onAddPlace(place),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPlaceName.isNotEmpty
              ? 'Places in $_currentPlaceName'
              : 'Search Places',
        ),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _placeController,
              onChanged: _onSearchPlaceChanged,
              decoration: const InputDecoration(
                hintText: 'Search place (e.g. Tokyo, Japan)',
                prefixIcon: Icon(Icons.public),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                shrinkWrap: true,
                children: _suggestions.map((s) {
                  return ListTile(
                    leading: const Icon(Icons.place),
                    title: Text(s.name),
                    onTap: () => _onSelectPlaceSuggestion(s),
                  );
                }).toList(),
              ),
            ),
          SearchBarWidget(
            controller: _searchController,
            onSearch: _applyLocalFilter,
            onOpenFilter: _openFilter,
          ),
          if (_categoryData.isNotEmpty)
            CategoryFilterChipsWidget(
              categories: _categoryData,
              selectedCategories: _selectedCategories,
              onCategoryToggle: (cat) {
                setState(() {
                  if (_selectedCategories.contains(cat)) {
                    _selectedCategories.remove(cat);
                  } else {
                    _selectedCategories.add(cat);
                  }
                });
                _applyLocalFilter();
              },
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
