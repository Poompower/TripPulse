import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../widgets/trip_card.dart';
import 'create_trip_screen.dart';
import 'detail_trip_screen.dart';
import 'edit_trip_screen.dart';
import '../services/database_service.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final DatabaseService _db = DatabaseService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Trip>> _tripsFuture;
  bool _showSearchBar = false;
  String _query = '';
  final Map<String, bool> _favoriteOverrides = {};

  @override
  void initState() {
    super.initState();
    _tripsFuture = _db.trips();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 120;
    if (shouldShow != _showSearchBar) {
      setState(() => _showSearchBar = shouldShow);
    }
  }

  void _reloadTrips() {
    setState(() {
      _tripsFuture = _db.trips();
    });
  }

  bool _effectiveFavorite(Trip trip) {
    final key = trip.id?.toString();
    if (key == null) return trip.isFavorite;
    return _favoriteOverrides[key] ?? trip.isFavorite;
  }

  Future<void> _toggleFavorite(Trip trip) async {
    final tripId = trip.id?.toString();
    if (tripId == null) return;

    final current = _effectiveFavorite(trip);
    final next = !current;
    setState(() => _favoriteOverrides[tripId] = next);

    try {
      await _db.updateTripFavorite(tripId: tripId, isFavorite: next);
    } catch (_) {
      if (!mounted) return;
      setState(() => _favoriteOverrides[tripId] = current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorite status')),
      );
    }
  }

  List<Trip> _filterTrips(List<Trip> trips) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return trips;
    return trips.where((trip) {
      return trip.title.toLowerCase().contains(q) ||
          trip.destination.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTripScreen()),
    );
    _reloadTrips();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: _showSearchBar ? 120 : 72,
      titleSpacing: 16,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My Trips',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                    fontSize: 34 / 1.7,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openCreate,
                icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 28),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _showSearchBar
                ? Padding(
                    key: const ValueKey('search-bar'),
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search trips by destination or title...',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1D4ED8),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('search-empty')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: _buildAppBar(),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final trips = _filterTrips(snapshot.data ?? []);
          if (trips.isEmpty) {
            return const Center(child: Text('No trips found'));
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 110),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final tripForCard = Trip(
                id: trip.id,
                title: trip.title,
                destination: trip.destination,
                city: trip.city,
                country: trip.country,
                countryCode: trip.countryCode,
                lat: trip.lat,
                lon: trip.lon,
                startDate: trip.startDate,
                endDate: trip.endDate,
                currency: trip.currency,
                budget: trip.budget,
                isFavorite: _effectiveFavorite(trip),
              );

              return Dismissible(
                key: Key(trip.id.toString()),
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 30),
                ),
                secondaryBackground: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Trip'),
                            content: const Text(
                              'Are you sure you want to delete this trip?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  }

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTripScreen(trip: trip),
                    ),
                  );
                  _reloadTrips();
                  return false;
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart &&
                      trip.id != null) {
                    await _db.deleteTrip(trip.id!);
                    _reloadTrips();
                  }
                },
                child: TripCard(
                  trip: tripForCard,
                  onToggleFavorite: () => _toggleFavorite(trip),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDetailScreen(trip: trip),
                      ),
                    );
                    _reloadTrips();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
          if (index != 0) CustomBottomBar.navigateToIndex(context, index);
        },
        variant: BottomBarVariant.material3,
        showLabels: true,
      ),
    );
  }
}
