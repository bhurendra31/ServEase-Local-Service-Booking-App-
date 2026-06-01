import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingScreen extends StatefulWidget {
  final String providerId;

  const RatingScreen({super.key, required this.providerId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int selectedRating = 0;
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Provider')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ⭐ Star rating
            const Text(
              'Your Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < selectedRating
                        ? Colors.amber
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedRating = index + 1;
                    });
                  },
                );
              }),
            ),

            const SizedBox(height: 20),

            // ✍️ Review text
            TextField(
              controller: reviewController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your review...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Submit button
            ElevatedButton(
              onPressed: submitReview,
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Save review to Firestore
  Future<void> submitReview() async {
    if (selectedRating == 0) return;

    await FirebaseFirestore.instance.collection('reviews').add({
      'providerId': widget.providerId,
      'rating': selectedRating,
      'comment': reviewController.text,
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context);
  }
}
