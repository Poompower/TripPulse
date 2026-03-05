import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class GeoapifyRouteSegment {
  final int fromStop;
  final int toStop;
  final double distanceKm;
  final int durationMinutes;
  final bool isEstimated;

  const GeoapifyRouteSegment({
    required this.fromStop,
    required this.toStop,
    required this.distanceKm,
    required this.durationMinutes,
    this.isEstimated = false,
  });
}

class GeoapifyRouteResult {
  final double distanceKm;
  final int durationMinutes;
  final List<LatLng> path;
  final List<List<LatLng>> pathSegments;
  final List<GeoapifyRouteSegment> segments;
  final bool hasEstimatedSegments;
  final List<int> waypointOrder;

  const GeoapifyRouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.path,
    required this.pathSegments,
    required this.segments,
    required this.hasEstimatedSegments,
    required this.waypointOrder,
  });
}

class GeoapifyRoutingService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.geoapify.com/v1',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  String get _apiKey {
    final key = dotenv.env['GEOAPIFY_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Geoapify API key missing');
    }
    return key;
  }

  Future<GeoapifyRouteResult> buildRoute({
    required List<LatLng> waypoints,
    String mode = 'walk',
    bool optimizeOrder = false,
  }) async {
    if (waypoints.length < 2) {
      return const GeoapifyRouteResult(
        distanceKm: 0,
        durationMinutes: 0,
        path: [],
        pathSegments: [],
        segments: [],
        hasEstimatedSegments: false,
        waypointOrder: [],
      );
    }

    return _buildRouteUsingMatrix(
      waypoints: waypoints,
      mode: mode,
      optimizeOrder: optimizeOrder,
    );
  }

  Future<GeoapifyRouteResult> _buildRouteUsingMatrix({
    required List<LatLng> waypoints,
    required String mode,
    required bool optimizeOrder,
  }) async {
    const walkKmPerHour = 4.8;
    final distance = const Distance();
    final segments = <GeoapifyRouteSegment>[];
    final pathSegments = <List<LatLng>>[];
    var totalKm = 0.0;
    var totalMin = 0;

    List<dynamic>? grid;
    List<LatLng>? snappedSources;
    try {
      final matrixPayload = await _requestRouteMatrixPayload(
        waypoints: waypoints,
        mode: mode,
      );
      grid = matrixPayload.$1;
      snappedSources = matrixPayload.$2;
    } catch (e, st) {
      developer.log(
        'RouteMatrix API failed, using fallback estimation for segments',
        name: 'GeoapifyRouting',
        error: e,
        stackTrace: st,
      );
    }

    final effectivePoints =
        (snappedSources != null && snappedSources.length == waypoints.length)
        ? snappedSources
        : waypoints;
    final waypointOrder = optimizeOrder
        ? _optimizeWaypointOrder(grid: grid, pointCount: effectivePoints.length)
        : List<int>.generate(effectivePoints.length, (i) => i);
    final orderedPoints = waypointOrder.map((i) => effectivePoints[i]).toList();

    for (var i = 0; i < orderedPoints.length - 1; i++) {
      final from = orderedPoints[i];
      final to = orderedPoints[i + 1];
      final fromOriginalIndex = waypointOrder[i];
      final toOriginalIndex = waypointOrder[i + 1];

      double? km;
      int? min;
      var estimated = false;
      List<LatLng> legPath = const [];

      final matrixCell = _readMatrixCell(
        grid: grid,
        fromIndex: fromOriginalIndex,
        toIndex: toOriginalIndex,
      );
      if (matrixCell != null) {
        final meters = _asDouble(matrixCell['distance']);
        final seconds = _asDouble(matrixCell['time']);
        if (meters != null && seconds != null) {
          km = meters / 1000;
          min = (seconds / 60).round();
        }
      }

      // If matrix has no value, try routing API for this leg before estimating straight line.
      if (km == null || min == null) {
        final routingLeg = await _requestRoutingLeg(
          from: from,
          to: to,
          mode: mode,
        );
        if (routingLeg != null) {
          km = routingLeg.distanceKm;
          min = routingLeg.durationMinutes;
          legPath = routingLeg.path;
        }
      }

      if (km == null || min == null) {
        estimated = true;
        km = distance.as(LengthUnit.Kilometer, from, to);
        min = ((km / walkKmPerHour) * 60).round();
      }

      // Always try to get walking geometry for map rendering,
      // even when matrix already returned distance/time.
      if (legPath.length <= 1) {
        final routingLeg = await _requestRoutingLeg(
          from: from,
          to: to,
          mode: mode,
        );
        if (routingLeg != null && routingLeg.path.length > 1) {
          legPath = routingLeg.path;
        }
      }

      if (legPath.length > 1) {
        pathSegments.add(legPath);
      } else {
        developer.log(
          'No routing geometry for leg ${i + 1}->${i + 2}',
          name: 'GeoapifyRouting',
        );
      }

      totalKm += km;
      totalMin += min;
      segments.add(
        GeoapifyRouteSegment(
          fromStop: i + 1,
          toStop: i + 2,
          distanceKm: km,
          durationMinutes: min,
          isEstimated: estimated,
        ),
      );
    }
    final mergedPath = <LatLng>[];
    if (pathSegments.isEmpty && orderedPoints.length >= 2) {
      final fullPath = await _requestRoutingPathForWaypoints(
        waypoints: orderedPoints,
        mode: mode,
      );
      if (fullPath.length > 1) {
        pathSegments.add(fullPath);
        developer.log(
          'Using full-waypoints routing geometry fallback',
          name: 'GeoapifyRouting',
        );
      }
    }

    for (final segmentPath in pathSegments) {
      if (mergedPath.isEmpty) {
        mergedPath.addAll(segmentPath);
      } else if (segmentPath.isNotEmpty) {
        mergedPath.addAll(segmentPath.skip(1));
      }
    }

    return GeoapifyRouteResult(
      distanceKm: totalKm,
      durationMinutes: totalMin,
      path: mergedPath,
      pathSegments: pathSegments,
      segments: segments,
      hasEstimatedSegments: segments.any((s) => s.isEstimated),
      waypointOrder: waypointOrder,
    );
  }

  List<int> _optimizeWaypointOrder({
    required List<dynamic>? grid,
    required int pointCount,
  }) {
    final fallback = List<int>.generate(pointCount, (i) => i);
    if (pointCount < 3 || grid == null) return fallback;

    final visited = <int>{0};
    final order = <int>[0];
    var current = 0;

    while (order.length < pointCount) {
      int? bestIndex;
      double? bestDistance;
      for (var candidate = 0; candidate < pointCount; candidate++) {
        if (visited.contains(candidate)) continue;
        final cell = _readMatrixCell(
          grid: grid,
          fromIndex: current,
          toIndex: candidate,
        );
        final d = _asDouble(cell?['distance']);
        if (d == null || d <= 0) continue;
        if (bestDistance == null || d < bestDistance) {
          bestDistance = d;
          bestIndex = candidate;
        }
      }

      if (bestIndex == null) {
        for (var candidate = 0; candidate < pointCount; candidate++) {
          if (!visited.contains(candidate)) {
            bestIndex = candidate;
            break;
          }
        }
      }

      if (bestIndex == null) break;
      visited.add(bestIndex);
      order.add(bestIndex);
      current = bestIndex;
    }

    return order.length == pointCount ? order : fallback;
  }

  Future<(List<dynamic>?, List<LatLng>?)> _requestRouteMatrixPayload({
    required List<LatLng> waypoints,
    required String mode,
  }) async {
    final points = waypoints
        .map((p) => {'location': [p.longitude, p.latitude]})
        .toList();

    final response = await _dio.post(
      '/routematrix',
      queryParameters: {'apiKey': _apiKey},
      options: Options(
        headers: const {'Content-Type': 'application/json'},
      ),
      data: {
        'mode': mode,
        'sources': points,
        'targets': points,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) return (null, null);

    final grid = data['sources_to_targets'] ??
        data['sourcesToTargets'] ??
        data['matrix'];
    final snappedSources = _parseSnappedLocations(data['sources']);
    if (grid is List) return (grid, snappedSources);
    return (null, snappedSources);
  }

  Map<String, dynamic>? _readMatrixCell({
    required List<dynamic>? grid,
    required int fromIndex,
    required int toIndex,
  }) {
    if (grid == null) return null;
    // flat list shape: [{source_index,target_index,distance,time}, ...]
    if (grid.isNotEmpty && grid.first is Map) {
      for (final item in grid) {
        if (item is! Map) continue;
        final map = _normalizeMap(item);
        final s = (map['source_index'] as num?)?.toInt();
        final t = (map['target_index'] as num?)?.toInt();
        if (s == fromIndex && t == toIndex) return map;
      }
      return null;
    }

    // matrix shape: [[{...},{...}], [...]]
    if (fromIndex < 0 || fromIndex >= grid.length) return null;
    final row = grid[fromIndex];
    if (row is! List) return null;
    if (toIndex < 0 || toIndex >= row.length) return null;
    final cell = row[toIndex];
    if (cell is Map) return _normalizeMap(cell);
    return null;
  }

  Map<String, dynamic> _normalizeMap(Map raw) {
    return <String, dynamic>{
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  List<LatLng>? _parseSnappedLocations(dynamic sourcesRaw) {
    if (sourcesRaw is! List) return null;
    final points = <LatLng>[];
    for (final item in sourcesRaw) {
      if (item is! Map) return null;
      final mapped = item['location'];
      if (mapped is! List || mapped.length < 2) return null;
      final lon = (mapped[0] as num?)?.toDouble();
      final lat = (mapped[1] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      points.add(LatLng(lat, lon));
    }
    return points;
  }

  Future<_RoutingLegResult?> _requestRoutingLeg({
    required LatLng from,
    required LatLng to,
    required String mode,
  }) async {
    try {
      final response = await _dio.get(
        '/routing',
        queryParameters: {
          'waypoints':
              '${from.longitude},${from.latitude}|${to.longitude},${to.latitude}',
          'mode': mode,
          'apiKey': _apiKey,
        },
      );
      final features = response.data['features'] as List?;
      if (features == null || features.isEmpty) return null;
      final first = features.first as Map<String, dynamic>;
      final properties = first['properties'] as Map<String, dynamic>? ?? {};
      final distanceMeters = _asDouble(properties['distance']);
      final timeSeconds = _asDouble(properties['time']);
      final geometry = first['geometry'] as Map<String, dynamic>? ?? {};
      final path = _parseCoordinatesToPath(geometry['coordinates']);
      if (distanceMeters == null || timeSeconds == null) return null;
      return _RoutingLegResult(
        distanceKm: distanceMeters / 1000,
        durationMinutes: (timeSeconds / 60).round(),
        path: path,
      );
    } catch (e, st) {
      developer.log(
        'Routing leg request failed',
        name: 'GeoapifyRouting',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<List<LatLng>> _requestRoutingPathForWaypoints({
    required List<LatLng> waypoints,
    required String mode,
  }) async {
    if (waypoints.length < 2) return const [];
    final waypointParam = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join('|');
    try {
      final response = await _dio.get(
        '/routing',
        queryParameters: {
          'waypoints': waypointParam,
          'mode': mode,
          'apiKey': _apiKey,
        },
      );
      final features = response.data['features'] as List?;
      if (features == null || features.isEmpty) return const [];
      final first = features.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>? ?? {};
      return _parseCoordinatesToPath(geometry['coordinates']);
    } catch (e, st) {
      developer.log(
        'Full-waypoints routing geometry request failed',
        name: 'GeoapifyRouting',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  List<LatLng> _parseCoordinatesToPath(dynamic coordinates) {
    final points = <LatLng>[];

    void visit(dynamic node) {
      if (node is List && node.length >= 2 && node[0] is num && node[1] is num) {
        points.add(
          LatLng((node[1] as num).toDouble(), (node[0] as num).toDouble()),
        );
        return;
      }
      if (node is List) {
        for (final child in node) {
          visit(child);
        }
      }
    }

    visit(coordinates);
    return points;
  }
}

class _RoutingLegResult {
  final double distanceKm;
  final int durationMinutes;
  final List<LatLng> path;

  const _RoutingLegResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.path,
  });
}
