import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/review_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../models/review_model.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthFirebaseService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));
    }
    final svc = context.read<ReviewService>();
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعاتي')),
      body: StreamBuilder<List<ReviewModel>>(
        stream: svc.watchUserReviews(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(child: Text('لا توجد مراجعات حتى الآن'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = reviews[i];
              return Material(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text('⭐ ${r.rating.toStringAsFixed(1)} — ${r.userName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(r.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        await svc.deleteReview(r.id, r.bookId);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
