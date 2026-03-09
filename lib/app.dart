import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'maps/screens/general_map_screen.dart';
import 'places/screens/places_search_screen.dart';
import 'trips/models/trip.dart';
import 'trips/screens/create_trip_screen.dart';
import 'trips/screens/detail_trip_screen.dart';
import 'trips/screens/edit_trip_screen.dart';
import 'trips/screens/trip_list_screen.dart';
import 'users/screens/login_screen.dart';
import 'users/screens/profile_screen.dart';
import 'users/screens/signup_screen.dart';

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
                return MaterialPageRoute(
                  builder: (_) => const CreateTripScreen(),
                );
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
                final args = settings.arguments;
                if (args is GeneralMapArgs) {
                  return MaterialPageRoute(
                    builder: (_) => GeneralMapScreen(
                      trip: args.trip,
                      dayNumber: args.dayNumber,
                      directionsOnly: args.directionsOnly,
                      destinationLat: args.destinationLat,
                      destinationLon: args.destinationLon,
                      destinationLabel: args.destinationLabel,
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (_) => const GeneralMapScreen(),
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
