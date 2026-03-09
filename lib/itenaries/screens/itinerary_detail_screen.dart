import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../maps/screens/general_map_screen.dart';
import '../../maps/services/geoapify_routing_service.dart';
import '../../places/models/place.dart';
import '../../places/services/wikimedia_image_service.dart';
import '../../trips/models/trip.dart';
import '../../trips/services/database_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../models/activity.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final Trip trip;
  final int dayNumber;

  const ItineraryDetailScreen({
    super.key,
    required this.trip,
    required this.dayNumber,
  });

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  bool _summaryExpanded = true;
  final GeoapifyRoutingService _routingService = GeoapifyRoutingService();
  Future<GeoapifyRouteResult>? _routeFuture;
  String _routeKey = '';

  DateTime _parseTripDate(String value) {
    try {
      return DateFormat('MMM dd, yyyy').parse(value);
    } catch (_) {
      return DateTime.parse(value);
    }
  }

  DateTime _dateForDay() {
    final start = _parseTripDate(widget.trip.startDate);
    return start.add(Duration(days: widget.dayNumber - 1));
  }

  Stream<List<Activity>> _dayActivitiesStream() {
    if (widget.trip.id == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id.toString())
        .collection('activities')
        .where('dayNumber', isEqualTo: widget.dayNumber)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            return Activity(
              id: doc.id,
              tripId: widget.trip.id.toString(),
              dayNumber: (data['dayNumber'] as num?)?.toInt() ?? 1,
              title: (data['title'] ?? '').toString(),
              location: data['location']?.toString(),
              time: data['time']?.toString(),
              imageUrl: data['imageUrl']?.toString(),
              category: data['category']?.toString(),
              lat: (data['lat'] as num?)?.toDouble(),
              lon: (data['lon'] as num?)?.toDouble(),
           );
          }).toList();

          return _sortActivitiesForRoute(list);
        });
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

      // Keep original add order when times are missing/identical.
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

  Future<GeoapifyRouteResult> _resolveRoute(List<Activity> activities) {
    final points = activities
        .where((a) => a.lat != null && a.lon != null)
        .map((a) => LatLng(a.lat!, a.lon!))
        .toList();

    if (points.length < 2) {
      return Future.value(
        const GeoapifyRouteResult(
          distanceKm: 0,
          durationMinutes: 0,
          path: [],
          pathSegments: [],
          segments: [],
          hasEstimatedSegments: false,
          waypointOrder: [],
        ),
      );
    }

    return _routingService.buildRoute(
      waypoints: points,
      mode: 'walk',
      optimizeOrder: false,
    );
  }

  Future<GeoapifyRouteResult> _getRouteFuture(List<Activity> activities) {
    final points = activities
        .where((a) => a.lat != null && a.lon != null)
        .map((a) => '${a.lat},${a.lon}')
        .join('|');

    if (points != _routeKey || _routeFuture == null) {
      _routeKey = points;
      _routeFuture = _resolveRoute(activities);
    }
    return _routeFuture!;
  }

  Future<void> _deleteActivity(Activity activity) async {
    if (activity.id == null) return;
    await DatabaseService().deleteActivity(widget.trip.id, activity.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${activity.title} removed')));
  }

  void _showActivitySheet(Activity activity) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildActivityImage(
                  activity,
                  width: double.infinity,
                  height: 180,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 36 / 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _metaChip(
                    Icons.location_city,
                    (activity.category ?? 'Landmark').toUpperCase(),
                  ),
                  const Spacer(),
                  _metaChip(
                    Icons.schedule_outlined,
                    activity.time ?? '2-3 hours',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                activity.location?.isNotEmpty == true
                    ? activity.location!
                    : 'No notes for this place yet.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Notes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2F66EA),
                        side: const BorderSide(color: Color(0xFF2F66EA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (activity.lat == null || activity.lon == null) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Location is missing for this activity',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pushNamed(
                          this.context,
                          '/general-map-screen',
                          arguments: GeneralMapArgs(
                            trip: widget.trip,
                            dayNumber: widget.dayNumber,
                            directionsOnly: true,
                            destinationLat: activity.lat,
                            destinationLon: activity.lon,
                            destinationLabel: activity.title,
                          ),
                        );
                      },
                      icon: const Icon(Icons.assistant_direction, size: 18),
                      label: const Text('Directions'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2F66EA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayDate = _dateForDay();
    final dayLabel =
        'Day ${widget.dayNumber} - ${DateFormat('MMMM d, yyyy').format(dayDate)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E2430)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          dayLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1E2430),
            fontWeight: FontWeight.w700,
            fontSize: 29 / 1.4,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.help_outline, color: Color(0xFF8C93A3)),
          ),
        ],
      ),
      body: StreamBuilder<List<Activity>>(
        stream: _dayActivitiesStream(),
        builder: (context, snapshot) {
          final activities = snapshot.data ?? const <Activity>[];
          final routeFuture = _getRouteFuture(activities);

          return FutureBuilder<GeoapifyRouteResult>(
            future: routeFuture,
            builder: (context, routeSnapshot) {
              final totalDistance = routeSnapshot.data?.distanceKm ?? 0.0;
              final estimatedMinutes = routeSnapshot.data?.durationMinutes ?? 0;
              final segments =
                  routeSnapshot.data?.segments ??
                  const <GeoapifyRouteSegment>[];
              final hasEstimated =
                  routeSnapshot.data?.hasEstimatedSegments ?? false;
              final waypointActivities = activities
                  .where((a) => a.lat != null && a.lon != null)
                  .toList();
              final waypointOrder =
                  routeSnapshot.data?.waypointOrder ?? const <int>[];
              final orderedWaypointActivities = _applyWaypointOrder(
                waypointActivities,
                waypointOrder,
              );
              final renderedActivities = _buildRenderedActivities(
                allActivities: activities,
                mappedActivities: waypointActivities,
                orderedMappedActivities: orderedWaypointActivities,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                children: [
                  _buildRouteSummary(
                    totalDistance,
                    estimatedMinutes,
                    segments,
                    orderedWaypointActivities,
                    hasEstimated,
                  ),
                  const SizedBox(height: 14),
                  if (renderedActivities.isEmpty)
                    _buildEmptyState()
                  else
                    ...renderedActivities.map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSwipeCard(activity),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 56,
        child: FloatingActionButton.extended(
          heroTag: 'itinerary-day-map-btn',
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/general-map-screen',
              arguments: GeneralMapArgs(
                trip: widget.trip,
                dayNumber: widget.dayNumber,
              ),
            );
          },
          icon: const Icon(Icons.map_outlined),
          label: const Text(
            'View Day on Map',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22 / 1.4),
          ),
          backgroundColor: const Color(0xFF2F66EA),
          foregroundColor: Colors.white,
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
          if (index != 0) CustomBottomBar.navigateToIndex(context, index);
        },
        variant: BottomBarVariant.material3,
      ),
    );
  }

  Widget _buildRouteSummary(
    double distanceKm,
    int estimatedMinutes,
    List<GeoapifyRouteSegment> segments,
    List<Activity> waypointActivities,
    bool hasEstimatedSegments,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF1)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route, color: Color(0xFF2F66EA)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route Summary',
                          style: TextStyle(
                            fontSize: 18 / 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km - $estimatedMinutes mins',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15 / 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _summaryExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF7B8395),
                  ),
                ],
              ),
            ),
          ),
          if (_summaryExpanded) ...[
            const Divider(height: 20),
            _summaryRow(
              Icons.straighten,
              'Total Distance',
              '${distanceKm.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 10),
            _summaryRow(
              Icons.schedule,
              'Estimated Time',
              '$estimatedMinutes mins',
            ),
            const SizedBox(height: 10),
            _summaryRow(Icons.directions_walk, 'Transport Mode', 'WALKING'),
            if (hasEstimatedSegments) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Some segments are estimated because walking route is unavailable.',
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
            if (segments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Segment Breakdown',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...segments.map((segment) {
                final fromIndex = segment.fromStop - 1;
                final toIndex = segment.toStop - 1;
                final fromName =
                    (fromIndex >= 0 && fromIndex < waypointActivities.length)
                    ? waypointActivities[fromIndex].title
                    : 'Stop ${segment.fromStop}';
                final toName =
                    (toIndex >= 0 && toIndex < waypointActivities.length)
                    ? waypointActivities[toIndex].title
                    : 'Stop ${segment.toStop}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stop ${segment.fromStop} $fromName -> Stop ${segment.toStop} $toName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${segment.distanceKm.toStringAsFixed(1)} km, ${segment.durationMinutes} mins${segment.isEstimated ? ' (est.)' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF1E2430),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Route calculated based on current place order',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2F66EA), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15 / 1.4),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E2430),
            fontSize: 23 / 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeCard(Activity activity) {
    return Dismissible(
      key: ValueKey('${activity.id}-${activity.dayNumber}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFE5262A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 6),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _deleteActivity(activity);
        return true;
      },
      child: InkWell(
        onTap: () => _showActivitySheet(activity),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7EAF1)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildActivityImage(activity, width: 72, height: 72),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: Color(0xFF1E2430),
                        fontSize: 30 / 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (activity.category ?? 'Landmark').toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF2F66EA),
                        fontWeight: FontWeight.w700,
                        fontSize: 16 / 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.location?.isNotEmpty == true
                          ? activity.location!
                          : 'No short description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15 / 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.time ?? '2-3 hours',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14 / 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.drag_handle, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF1)),
      ),
      child: Column(
        children: [
          Icon(Icons.travel_explore, color: Colors.grey.shade400, size: 32),
          const SizedBox(height: 8),
          const Text(
            'No places for this day yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E2430),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Go back and add activities to build your route.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
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

  List<Activity> _buildRenderedActivities({
    required List<Activity> allActivities,
    required List<Activity> mappedActivities,
    required List<Activity> orderedMappedActivities,
  }) {
    final mappedIds = mappedActivities.map((a) => a.id?.toString()).toSet();
    final unmapped = allActivities
        .where((a) => !mappedIds.contains(a.id?.toString()))
        .toList();
    return [...orderedMappedActivities, ...unmapped];
  }

  Widget _buildActivityImage(
    Activity activity, {
    required double width,
    required double height,
  }) {
    final directUrl = activity.imageUrl;
    if (directUrl != null && directUrl.isNotEmpty) {
      return Image.network(
        directUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _imagePlaceholder(height, width: width),
      );
    }

    final placeForResolve = Place(
      id: activity.id?.toString() ?? activity.title,
      name: activity.title,
      category: activity.category ?? 'landmark',
      description: activity.location ?? '',
      lat: activity.lat ?? widget.trip.lat ?? 0,
      lon: activity.lon ?? widget.trip.lon ?? 0,
      country: widget.trip.country,
      countryCode: widget.trip.countryCode,
      imageUrl: null,
      wikipediaTitle: null,
      wikimediaCommons: null,
      wikidataId: null,
      distanceKm: null,
      categories: const [],
    );

    return FutureBuilder<String?>(
      future: WikimediaImageService.instance.resolveImageUrl(placeForResolve),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url != null && url.isNotEmpty) {
          return Image.network(
            url,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _imagePlaceholder(height, width: width),
          );
        }
        return _imagePlaceholder(height, width: width);
      },
    );
  }

  Widget _imagePlaceholder(double height, {double? width}) {
    return Container(
      width: width ?? height,
      height: height,
      color: const Color(0xFFEDEFF5),
      child: const Icon(Icons.image, color: Color(0xFFB0B7C6)),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2F66EA)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2F66EA),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
