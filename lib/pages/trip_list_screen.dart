import 'package:flutter/material.dart';
import 'package:trippulse/widgets/custom_bottom_bar.dart';
import '../services/database_service.dart';
import '../models/trip.dart';
import '../widgets/trip_card.dart';
import '../pages/create_trip_screen.dart';
import '../pages/detail_trip_screen.dart';
import '../pages/edit_trip_screen.dart';

class TripListScreen extends StatefulWidget {
  @override
  _TripListScreenState createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Trips",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Trip>>(
        future: db.trips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text("เพิ่มทริปแรกของคุณเลย!"));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final trip = snapshot.data![index];
              return Dismissible(
                key: Key(trip.id.toString()),
                background: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.edit, color: Colors.white, size: 30),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    // Swipe Left (Delete)
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Trip'),
                        content: const Text(
                          'Are you sure you want to delete this trip?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Swipe Right (Edit)
                    // We don't want to dismiss, just navigate
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTripScreen(trip: trip),
                      ),
                    );
                    setState(() {});
                    return false;
                  }
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    if (trip.id != null) {
                      await db.deleteTrip(trip.id!);
                      setState(() {
                        // snapshot.data!.removeAt(index); // This would be ideal if we had mutable list, but we rely on FutureBuilder rebuild
                        // Since we call setState, FutureBuilder will re-fire db.trips()
                      });
                    }
                  }
                },
                child: TripCard(
                  trip: trip,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDetailScreen(trip: trip),
                      ),
                    );
                    setState(() {}); // Refresh list after returning
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateTripScreen()),
        ).then((_) => setState(() {})),
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
          if (index != 0) {
            CustomBottomBar.navigateToIndex(context, index);
          }
        },
        variant: BottomBarVariant.material3,
        showLabels: true,
      ),
    );
  }
}
