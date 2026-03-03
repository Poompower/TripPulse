import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'models/trip.dart';
import 'pages/create_trip_screen.dart';
import 'pages/detail_trip_screen.dart';
import 'pages/edit_trip_screen.dart';
import 'pages/login_screen.dart';
import 'pages/profile_screen.dart';
import 'pages/signup_screen.dart';
import 'pages/trip_list_screen.dart';
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
          home: const LoginScreen(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case '/signup':
                return MaterialPageRoute(builder: (_) => const SignupScreen());
              case '/profile-screen':
                return MaterialPageRoute(builder: (_) => const ProfileScreen());

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

              case '/places-search-screen':
                return MaterialPageRoute(
                  builder: (_) => const PlacesSearchScreen(destinationName: ''),
                );
              case '/places/search':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => PlacesSearchScreen(
                    destinationName: args['destinationName'],
                    lat: args['lat'],
                    lon: args['lon'],
                  ),
                );

              case '/general-map-screen':
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Map')),
                    body: const Center(
                      child: Text('General Map Screen (not implemented)'),
                    ),
                  ),
                );

              default:
                return null;
            }
          },
        );
      },
    );
  }
}
