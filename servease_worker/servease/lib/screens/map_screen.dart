import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLatLng;
  final Set<Marker> _markers = {};

  // ================= LOCATION PERMISSION =================
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enable location permission from settings"),
        ),
      );
    }
  }

  // ================= GET USER LOCATION =================
  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _userLatLng = LatLng(position.latitude, position.longitude);

    // Static nearest office (demo)
    const LatLng officeLatLng = LatLng(26.7288, 85.9250);

    _markers.add(
      const Marker(
        markerId: MarkerId("office"),
        position: officeLatLng,
        infoWindow: InfoWindow(title: "Nearest Office"),
      ),
    );

    setState(() {});
  }

  // ================= CALL & WHATSAPP =================
  Future<void> _launchExternal(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot open app")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _requestLocationPermission();
    await _getUserLocation();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Services")),
      body: _userLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userLatLng!,
                      zoom: 14,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(_userLatLng!, 14),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            _launchExternal("tel:9800000000"),
                        icon: const Icon(Icons.call),
                        label: const Text("Call"),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => _launchExternal(
                            "https://wa.me/9779800000000"),
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text(
                          "WhatsApp",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
