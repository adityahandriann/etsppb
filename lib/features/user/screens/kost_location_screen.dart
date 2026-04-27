import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class KostLocationScreen extends StatefulWidget {
  const KostLocationScreen({super.key});

  @override
  State<KostLocationScreen> createState() => _KostLocationScreenState();
}

class _KostLocationScreenState extends State<KostLocationScreen> {
  static final LatLng _kostLocation = LatLng(-7.2824, 112.7949); // Koordinat ITS Surabaya
  final MapController _mapController = MapController();
  final Location _location = Location();
  
  LatLng? _currentUserLocation;
  bool _isLoading = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();
      setState(() {
        _currentUserLocation = LatLng(locationData.latitude!, locationData.longitude!);
        _mapController.move(_currentUserLocation!, 15.0);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Kost'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      extendBodyBehindAppBar: true,
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _kostLocation,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.etsppb',
          ),
          MarkerLayer(
            markers: [
              // Penanda Lokasi Kost
              Marker(
                point: _kostLocation,
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Kost Kita', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ],
                ),
              ),
              // Penanda Lokasi Pengguna (jika ada)
              if (_currentUserLocation != null)
                Marker(
                  point: _currentUserLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'kost',
            onPressed: () => _mapController.move(_kostLocation, 15.0),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.home, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'user',
            onPressed: _isLoading ? null : _getCurrentLocation,
            backgroundColor: Colors.white,
            child: _isLoading 
              ? const CircularProgressIndicator()
              : const Icon(Icons.my_location, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
