import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SelectLocationMapScreen extends StatefulWidget {
  const SelectLocationMapScreen({super.key});

  @override
  State<SelectLocationMapScreen> createState() =>
      _SelectLocationMapScreenState();
}

class _SelectLocationMapScreenState extends State<SelectLocationMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  String _currentAddress = 'Move map to select location';
  bool _loadingAddress = false;

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  void initState() {
    super.initState();
    _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng = LatLng(position.latitude, position.longitude);
    _selectedLatLng = latLng;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 16),
    );

    _updateAddress(latLng);
  }

  Future<void> _updateAddress(LatLng latLng) async {
    setState(() => _loadingAddress = true);

    final placemarks = await placemarkFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );

    final place = placemarks.first;

    setState(() {
      _currentAddress =
          '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      _loadingAddress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(26.7284, 85.9210), // Janakpur default
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              _selectedLatLng = position.target;
            },
            onCameraIdle: () {
              if (_selectedLatLng != null) {
                _updateAddress(_selectedLatLng!);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // 📍 CENTER PIN
          const Center(
            child: Icon(
              Icons.location_pin,
              size: 48,
              color: Colors.red,
            ),
          ),

          // 🔽 BOTTOM ADDRESS CARD
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _loadingAddress
                      ? const LinearProgressIndicator()
                      : Text(
                          _currentAddress,
                          style: const TextStyle(fontSize: 14),
                        ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context, {
                          'address': _currentAddress,
                          'lat': _selectedLatLng!.latitude,
                          'lng': _selectedLatLng!.longitude,
                        });
                      },
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

