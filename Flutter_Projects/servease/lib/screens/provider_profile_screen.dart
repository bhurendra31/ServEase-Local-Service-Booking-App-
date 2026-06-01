import 'package:flutter/material.dart';
import 'booking_screen.dart';
import 'map_screen.dart';


class ProviderProfileScreen extends StatelessWidget {
  final String providerName;
  final String service;

  ProviderProfileScreen({
    super.key,
    required this.providerName,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              providerName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text('Service: $service'),
            const SizedBox(height: 10),

            Row(
              children: const [
                Icon(Icons.star, color: Colors.orange),
                SizedBox(width: 4),
                Text('4.5 Rating'),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.message),
                  label: const Text('WhatsApp'),
                ),
                ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  },
  child: const Text('View on Map'),
),

              ],
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      providerName: providerName,
                      service: service,
                    ),
                  ),
                );
              },
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }
}
