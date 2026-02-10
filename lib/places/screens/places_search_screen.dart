import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/places_service.dart';
import '../../widgets/custom_bottom_bar.dart';

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
  final _service = PlacesService();
  final _controller = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<Place> _places = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.destinationName;
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.searchPlaces(
        query: _controller.text,
        lat: widget.lat,
        lon: widget.lon,
      );

      if (!mounted) return; // ⭐ สำคัญ

      setState(() {
        _places = results;
      });
    } catch (e) {
      if (!mounted) return; // ⭐ สำคัญ

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return; // ⭐ สำคัญ

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search places')),
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
          _SearchBar(controller: _controller, onSearch: _search),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

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
      itemBuilder: (_, i) => _PlaceItem(
        place: _places[i],
        onAdd: () {
          // TODO: wire to itinerary later
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${_places[i].name} added')));
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const _SearchBar({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: controller,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          hintText: 'Search attractions',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: onSearch,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _PlaceItem extends StatelessWidget {
  final Place place;
  final VoidCallback onAdd;

  const _PlaceItem({required this.place, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: place.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  place.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.place, size: 40),
        title: Text(place.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.category, style: const TextStyle(fontSize: 12)),
            if (place.distanceKm != null)
              Text(
                '${place.distanceKm!.toStringAsFixed(1)} km from center',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.blue),
          onPressed: onAdd,
        ),
      ),
    );
  }
}
