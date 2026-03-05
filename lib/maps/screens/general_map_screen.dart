import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../itenaries/models/activity.dart';
import '../../places/services/places_service.dart';
import '../../trips/models/trip.dart';
import '../../trips/services/database_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../services/geoapify_routing_service.dart';
import '../services/location_service.dart';

class GeneralMapArgs {
  final Trip? trip;
  final int? dayNumber;

  const GeneralMapArgs({this.trip, this.dayNumber});
}

class GeneralMapScreen extends StatefulWidget {
  final Trip? trip;
  final int? dayNumber;

  const GeneralMapScreen({super.key, this.trip, this.dayNumber});

  @override
  State<GeneralMapScreen> createState() => _GeneralMapScreenState();
}

class _GeneralMapScreenState extends State<GeneralMapScreen> {
  final MapController _mapController = MapController();
  final GeoapifyRoutingService _routingService = GeoapifyRoutingService();
  final PlacesService _placesService = PlacesService();
  final DatabaseService _databaseService = DatabaseService();
  LatLng? _currentLocation;
  bool _loadingLocation = false;
  Object? _locationError;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitiesSub;
  List<Activity> _dayActivities = const [];
  bool _hasFittedDayBounds = false;
  GeoapifyRouteResult? _routeResult;
  bool _loadingRoute = false;
  bool _hydratingCoordinates = false;
  final Set<String> _geocodeAttemptedKeys = <String>{};
  List<Activity> _orderedRouteActivities = const [];

  LatLng get _fallbackCenter => const LatLng(13.7563, 100.5018);

  LatLng get _tripCenter {
    final lat = widget.trip?.lat;
    final lon = widget.trip?.lon;
    if (lat == null || lon == null) return _fallbackCenter;
    return LatLng(lat, lon);
  }

  LatLng get _mapCenter => _currentLocation ?? _tripCenter;

  List<Activity> get _routeActivities {
    final base = _dayActivities.where((a) => a.lat != null && a.lon != null).toList();
    if (_orderedRouteActivities.isNotEmpty) return _orderedRouteActivities;
    return _sortActivitiesForRoute(base);
  }

  List<LatLng> get _dayActivityPoints =>
      _routeActivities.map((a) => LatLng(a.lat!, a.lon!)).toList();

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _listenDayActivities();
  }

  List<Activity> _sortActivitiesForRoute(List<Activity> activities) {
    final indexed = activities.asMap().entries.toList();
    indexed.sort((a, b) {
      final aMinutes = _parseTimeToMinutes(a.value.time);
      final bMinutes = _parseTimeToMinutes(b.value.time);

      if (aMinutes != null && bMinutes != null) {
        final cmp = aMinutes.compareTo(bMinutes);
        if (cmp != 0) return cmp;
      } else if (aMinutes != null && bMinutes == null) {
        return -1;
      } else if (aMinutes == null && bMinutes != null) {
        return 1;
      }

      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  int? _parseTimeToMinutes(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;

    final m12 = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$').firstMatch(value);
    if (m12 != null) {
      var hour = int.parse(m12.group(1)!);
      final minute = int.parse(m12.group(2)!);
      final period = m12.group(3)!.toUpperCase();
      if (hour == 12) hour = 0;
      if (period == 'PM') hour += 12;
      return (hour * 60) + minute;
    }

    final m24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (m24 != null) {
      final hour = int.parse(m24.group(1)!);
      final minute = int.parse(m24.group(2)!);
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return (hour * 60) + minute;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _activitiesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e);
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _listenDayActivities() {
    final tripId = widget.trip?.id;
    final day = widget.dayNumber;
    if (tripId == null || day == null) return;

    _activitiesSub = FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId.toString())
        .collection('activities')
        .where('dayNumber', isEqualTo: day)
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            return Activity(
              id: doc.id,
              tripId: tripId.toString(),
              dayNumber: (data['dayNumber'] as num?)?.toInt() ?? day,
              title: (data['title'] ?? '').toString(),
              location: data['location']?.toString(),
              time: data['time']?.toString(),
              imageUrl: data['imageUrl']?.toString(),
              category: data['category']?.toString(),
              lat: (data['lat'] as num?)?.toDouble(),
              lon: (data['lon'] as num?)?.toDouble(),
            );
          }).toList();

          if (!mounted) return;
          setState(() => _dayActivities = list);
          _hydrateMissingCoordinates(list);
          _refreshRouteSummary();
          _fitMapToDayMarkers();
        });
  }

  Future<void> _hydrateMissingCoordinates(List<Activity> activities) async {
    final tripId = widget.trip?.id;
    if (tripId == null || _hydratingCoordinates) return;

    final missing = activities.where((a) {
      if (a.lat != null && a.lon != null) return false;
      final key = '${a.id ?? a.title}|${a.dayNumber}';
      return !_geocodeAttemptedKeys.contains(key);
    }).toList();

    if (missing.isEmpty) return;

    _hydratingCoordinates = true;
    try {
      for (final activity in missing) {
        final key = '${activity.id ?? activity.title}|${activity.dayNumber}';
        _geocodeAttemptedKeys.add(key);

        final queryParts = <String>[
          activity.title,
          if (activity.location != null && activity.location!.isNotEmpty)
            activity.location!,
          if (widget.trip?.destination.isNotEmpty == true) widget.trip!.destination,
        ];
        final query = queryParts.join(' ').trim();
        if (query.isEmpty) continue;

        try {
          final suggestions = await _placesService.searchPlaceSuggestions(query);
          if (suggestions.isEmpty) continue;

          final best = suggestions.first;
          final updated = Activity(
            id: activity.id,
            tripId: activity.tripId,
            dayNumber: activity.dayNumber,
            title: activity.title,
            location: activity.location,
            time: activity.time,
            imageUrl: activity.imageUrl,
            category: activity.category,
            lat: best.lat,
            lon: best.lon,
          );

          await _databaseService.insertActivity(updated);
        } catch (_) {
          // keep best-effort behavior; next items should continue.
        }
      }
    } finally {
      _hydratingCoordinates = false;
    }
  }

  Future<void> _refreshRouteSummary() async {
    final points = _dayActivityPoints;
    if (points.length < 2) {
      if (!mounted) return;
      setState(
        () {
          _routeResult = const GeoapifyRouteResult(
            distanceKm: 0,
            durationMinutes: 0,
            path: [],
            pathSegments: [],
            segments: [],
            hasEstimatedSegments: false,
            waypointOrder: [],
          );
          _orderedRouteActivities = _sortActivitiesForRoute(_dayActivities
              .where((a) => a.lat != null && a.lon != null)
              .toList());
        },
      );
      return;
    }

    setState(() => _loadingRoute = true);
    try {
      final result = await _routingService.buildRoute(
        waypoints: points,
        mode: 'walk',
        optimizeOrder: false,
      );
      if (!mounted) return;
      setState(() {
        _routeResult = result;
        _orderedRouteActivities = _applyWaypointOrder(
          _sortActivitiesForRoute(
            _dayActivities.where((a) => a.lat != null && a.lon != null).toList(),
          ),
          result.waypointOrder,
        );
      });
      _fitMapToDayMarkers();
    } catch (_) {
      if (!mounted) return;
      setState(() => _routeResult = null);
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  List<Activity> _applyWaypointOrder(
    List<Activity> activities,
    List<int> order,
  ) {
    if (activities.isEmpty || order.isEmpty) return activities;
    final ordered = <Activity>[];
    for (final idx in order) {
      if (idx >= 0 && idx < activities.length) {
        ordered.add(activities[idx]);
      }
    }
    return ordered.isEmpty ? activities : ordered;
  }

  void _fitMapToDayMarkers() {
    if (widget.dayNumber == null) return;
    final points = _dayActivityPoints;
    if (points.isEmpty) return;
    if (_hasFittedDayBounds && points.length == 1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final routePoints = _routeResult?.pathSegments.expand((e) => e).toList() ?? const <LatLng>[];
      final fitPoints = routePoints.length > 1 ? routePoints : points;
      if (fitPoints.length == 1) {
        _mapController.move(fitPoints.first, 15.0);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(fitPoints),
            padding: const EdgeInsets.fromLTRB(48, 120, 48, 220),
          ),
        );
      }
      _hasFittedDayBounds = true;
    });
  }

  DateTime? _dateForDay() {
    if (widget.trip == null || widget.dayNumber == null) return null;
    try {
      final start = DateFormat('MMM dd, yyyy').parse(widget.trip!.startDate);
      return start.add(Duration(days: widget.dayNumber! - 1));
    } catch (_) {
      return null;
    }
  }

  String _titleText() {
    if (widget.trip == null || widget.dayNumber == null) return 'Map';
    final dayDate = _dateForDay();
    if (dayDate == null) return 'Day ${widget.dayNumber} Map';
    return 'Day ${widget.dayNumber} - ${DateFormat('MMM d').format(dayDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _dayActivityPoints.isNotEmpty
                  ? _dayActivityPoints.first
                  : _mapCenter,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.trippulse',
              ),
              if ((_routeResult?.pathSegments.isNotEmpty ?? false))
                PolylineLayer(
                  polylines: _routeResult!.pathSegments
                      .where((segmentPath) => segmentPath.length > 1)
                      .map(
                        (segmentPath) => Polyline(
                          points: segmentPath,
                          color: const Color(0xFF0B57D0).withValues(alpha: 0.95),
                          strokeWidth: 6,
                        ),
                      )
                      .toList(),
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _circleAction(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x15000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _titleText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2430),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _circleAction(
                    icon: Icons.my_location,
                    onTap: () {
                      final current = _currentLocation;
                      if (current == null) return;
                      _mapController.move(current, 15.5);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (widget.trip != null && widget.dayNumber != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route, color: Color(0xFF2F66EA)),
                          const SizedBox(width: 8),
                          Text(
                            'Places for day ${widget.dayNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (_loadingRoute)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Text(
                              '${_routeActivities.length}/${_dayActivities.length} mapped',
                              style: const TextStyle(color: Color(0xFF667085)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.straighten,
                            size: 16,
                            color: Color(0xFF2F66EA),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(_routeResult?.distanceKm ?? 0).toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Color(0xFF344054),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: Color(0xFF2F66EA),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_routeResult?.durationMinutes ?? 0} mins',
                            style: const TextStyle(
                              color: Color(0xFF344054),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (_routeResult?.hasEstimatedSegments == true) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Some legs are estimated (no walking route from API).',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((_routeResult?.segments.length ?? 0) > 0) ...[
                        const SizedBox(height: 8),
                        ..._routeResult!.segments.take(3).map((segment) {
                          final fromIndex = segment.fromStop - 1;
                          final toIndex = segment.toStop - 1;
                          final fromName = (fromIndex >= 0 &&
                                  fromIndex < _routeActivities.length)
                              ? _routeActivities[fromIndex].title
                              : 'Stop ${segment.fromStop}';
                          final toName =
                              (toIndex >= 0 && toIndex < _routeActivities.length)
                              ? _routeActivities[toIndex].title
                              : 'Stop ${segment.toStop}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Stop ${segment.fromStop} $fromName -> Stop ${segment.toStop} $toName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${segment.distanceKm.toStringAsFixed(1)} km, ${segment.durationMinutes} mins${segment.isEstimated ? ' (est.)' : ''}',
                                  style: const TextStyle(
                                    color: Color(0xFF344054),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 10),
                      if (_dayActivities.isEmpty)
                        const Text(
                          'No places yet. Add activities in itinerary first.',
                          style: TextStyle(color: Color(0xFF667085)),
                        )
                      else if (_routeActivities.isEmpty)
                        Text(
                          _hydratingCoordinates
                              ? 'Resolving place coordinates for map...'
                              : 'Places found, but coordinates are missing.',
                          style: const TextStyle(color: Color(0xFF667085)),
                        )
                      else
                        ..._routeActivities.take(3).map((a) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '- ${a.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF344054),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          if (_loadingLocation || _locationError != null)
            Positioned(
              top: 96,
              left: 16,
              right: 16,
              child: _locationStatusBanner(),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) CustomBottomBar.navigateToIndex(context, index);
        },
        variant: BottomBarVariant.material3,
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    for (var i = 0; i < _routeActivities.length; i++) {
      final activity = _routeActivities[i];

      markers.add(
        Marker(
          point: LatLng(activity.lat!, activity.lon!),
          width: 58,
          height: 58,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Stop ${i + 1}: ${activity.title}')),
              );
            },
            child: _numberPin(i + 1),
          ),
        ),
      );
    }

    if (widget.trip?.lat != null && widget.trip?.lon != null) {
      markers.add(
        Marker(
          point: LatLng(widget.trip!.lat!, widget.trip!.lon!),
          width: 52,
          height: 52,
          child: _pin(
            color: const Color(0xFF2F66EA),
            icon: Icons.flag,
          ),
        ),
      );
    }

    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 44,
          height: 44,
          child: _pin(
            color: const Color(0xFF00A86B),
            icon: Icons.my_location,
          ),
        ),
      );
    }

    if (markers.isEmpty) {
      markers.add(
        Marker(
          point: _fallbackCenter,
          width: 52,
          height: 52,
          child: _pin(
            color: const Color(0xFF2F66EA),
            icon: Icons.location_on,
          ),
        ),
      );
    }

    return markers;
  }

  Widget _pin({required Color color, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _numberPin(int order) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF2F66EA),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Text(
          '$order',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _circleAction({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: const Color(0xFF1E2430)),
        ),
      ),
    );
  }

  Widget _locationStatusBanner() {
    if (_loadingLocation) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Getting current location...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Unable to access current location. Showing destination area instead.',
        style: TextStyle(color: Color(0xFF7A4D00)),
      ),
    );
  }
}
