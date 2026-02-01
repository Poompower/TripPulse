import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/trip.dart';
import '../widgets/trip_card.dart';
import '../pages/create_trip_screen.dart';

class TripListScreen extends StatefulWidget {
  @override
  _TripListScreenState createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Trips", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      body: FutureBuilder<List<Trip>>(
        future: db.trips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("เพิ่มทริปแรกของคุณเลย!"));
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => TripCard(trip: snapshot.data![index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTripScreen())).then((_) => setState(() {})),
        child: Icon(Icons.add),
      ),
    );
  }
}