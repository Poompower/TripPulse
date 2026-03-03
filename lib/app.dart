import 'package:flutter/material.dart';

import 'models/trip.dart';
import 'pages/trip_list_screen.dart';
import 'pages/create_trip_screen.dart';
import 'pages/detail_trip_screen.dart';
import 'pages/edit_trip_screen.dart';
import 'package:sizer/sizer.dart';
import 'places/screens/places_search_screen.dart';

class TripPulseApp extends StatelessWidget {
  const TripPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
      return MaterialApp(
        title: 'TripPulse',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),

        // หน้าแรก
        home: TripListScreen(),

        // Route กลางของแอป
        onGenerateRoute: (settings) {
          switch (settings.name) {
            // ---------------- TRIP ----------------
            case '/trip-list-screen':
              return MaterialPageRoute(builder: (_) => TripListScreen());

            case '/trip/create':
              return MaterialPageRoute(builder: (_) => const CreateTripScreen());

            case '/trip/detail':
              final trip = settings.arguments as Trip;
              return MaterialPageRoute(
                builder: (_) => TripDetailScreen(trip: trip),
              );

            case '/trip/edit':
              final trip = settings.arguments as Trip;
              return MaterialPageRoute(
                builder: (_) => EditTripScreen(trip: trip),
              );

            // ---------------- PLACES ----------------
            case '/places-search-screen':
              return MaterialPageRoute(
                builder: (_) => const PlacesSearchScreen(destinationName: ''),
              );

            // existing detailed places search route (keeps compatibility)
            case '/places/search':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => PlacesSearchScreen(
                  destinationName: args['destinationName'],
                  lat: args['lat'],
                  lon: args['lon'],
                ),
              );

            // ---------------- MAP / OTHER ----------------
            case '/general-map-screen':
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Map')),
                  body: const Center(
                    child: Text('General Map Screen (not implemented)'),
                  ),
                ),
              );

            // ---------------- DEFAULT ----------------
            default:
              return null;
          }
        },
      );
    });
  }
}
