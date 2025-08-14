import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة مراجعة جديدة
  Future<void> addReview(ReviewModel review) async {
    try {
      await _firestore.collection('reviews').add(review.toMap());
      
      // تحديث متوسط التقييم للكتاب
      await _updateBookAverageRating(review.bookId);
    } catch (e) {
      print('خطأ في إضافة المراجعة: $e');
      throw e;
    }
  }

  // جلب مراجعات كتاب معين
  Future<List<ReviewModel>> getBookReviews(String bookId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('bookId', isEqualTo: bookId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب المراجعات: $e');
      return [];
    }
  }

  // تحديث مراجعة
  Future<void> updateReview(String reviewId, ReviewModel updatedReview) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .update(updatedReview.toMap());
      
      // تحديث متوسط التقييم للكتاب
      await _updateBookAverageRating(updatedReview.bookId);
    } catch (e) {
      print('خطأ في تحديث المراجعة: $e');
      throw e;
    }
  }

  // حذف مراجعة
  Future<void> deleteReview(String reviewId, String bookId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      
      // تحديث متوسط التقييم للكتاب
      await _updateBookAverageRating(bookId);
    } catch (e) {
      print('خطأ في حذف المراجعة: $e');
      throw e;
    }
  }

  // جلب مراجعات المستخدم
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب مراجعات المستخدم: $e');
      return [];
    }
  }

  // التحقق من وجود مراجعة للمستخدم على كتاب معين
  Future<ReviewModel?> getUserReviewForBook(String userId, String bookId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('bookId', isEqualTo: bookId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ReviewModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('خطأ في البحث عن مراجعة المستخدم: $e');
      return null;
    }
  }

  // تحديث متوسط التقييم للكتاب
  Future<void> _updateBookAverageRating(String bookId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('bookId', isEqualTo: bookId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        // لا توجد مراجعات، تعيين التقييم إلى 0
        await _firestore.collection('books').doc(bookId).update({
          'averageRating': 0.0,
          'totalReviews': 0,
        });
        return;
      }

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        final review = ReviewModel.fromFirestore(doc);
        totalRating += review.rating;
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('books').doc(bookId).update({
        'averageRating': averageRating,
        'totalReviews': reviewsSnapshot.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('خطأ في تحديث متوسط التقييم: $e');
    }
  }

  // إضافة إعجاب أو عدم إعجاب لمراجعة
  Future<void> toggleReviewLike(String reviewId, String userId, bool isLike) async {
    try {
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) return;

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      final likes = List<String>.from(reviewData['likes'] ?? []);
      final dislikes = List<String>.from(reviewData['dislikes'] ?? []);

      // إزالة المستخدم من القائمة الأخرى
      if (isLike) {
        dislikes.remove(userId);
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }
      } else {
        likes.remove(userId);
        if (dislikes.contains(userId)) {
          dislikes.remove(userId);
        } else {
          dislikes.add(userId);
        }
      }

      await _firestore.collection('reviews').doc(reviewId).update({
        'likes': likes,
        'dislikes': dislikes,
      });
    } catch (e) {
      print('خطأ في تحديث الإعجاب: $e');
    }
  }
}
