import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingMapScreen extends StatefulWidget {
  const LiveTrackingMapScreen({super.key});

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['SALES', 'DELIVERY'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          _markers.clear();
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final location = data['location'];
            if (location != null && location['lat'] != null && location['lng'] != null) {
              final marker = Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(location['lat'], location['lng']),
                infoWindow: InfoWindow(
                  title: data['name'] ?? doc.id,
                  snippet: data['role'] ?? '',
                ),
              );
              _markers[doc.id] = marker;
            }
          }
          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629), // Center of India
              zoom: 5,
            ),
            markers: Set<Marker>.of(_markers.values),
          );
        },
      ),
    );
  }
}
