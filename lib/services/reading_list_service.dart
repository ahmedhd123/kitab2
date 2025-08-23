import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reading_list_model.dart';

class ReadingListService extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  Future<ReadingListModel> createList({
    required String userId,
    required String name,
    String? description,
    ReadingListPrivacy privacy = ReadingListPrivacy.private,
  }) async {
    final now = DateTime.now();
    final ref = await _db.collection('reading_lists').add({
      'userId': userId,
      'name': name,
      'description': description,
      'privacy': privacy.name,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    final snap = await ref.get();
    final model = ReadingListModel.fromFirestore(snap);
    notifyListeners();
    return model;
  }

  Stream<List<ReadingListModel>> watchUserLists(String userId) {
    return _db
        .collection('reading_lists')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final items = s.docs.map((d) => ReadingListModel.fromFirestore(d)).toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Future<void> deleteList(String listId) async {
    // تنبيه: حذف العناصر الفرعية ليس تلقائياً؛ نكتفي بحذف الوثيقة الآن
    await _db.collection('reading_lists').doc(listId).delete();
    notifyListeners();
  }

  Future<ReadingListItemModel> addItem({
    required String listId,
    required String userId,
    required ReadingListItemSource source,
    DocumentReference? bookRef,
    String? externalBookId,
    String priority = 'normal',
    String? notes,
  }) async {
    final now = DateTime.now();
    final items = _db.collection('reading_lists').doc(listId).collection('items');
    final ref = await items.add({
      'userId': userId,
      'source': source.name,
      'bookRef': bookRef,
      'externalBookId': externalBookId,
      'status': ReadingListItemStatus.planned.name,
      'priority': priority,
      'notes': notes,
      'addedAt': Timestamp.fromDate(now),
    });
    final snap = await ref.get();
    final model = ReadingListItemModel.fromFirestore(snap);
    notifyListeners();
    return model;
  }

  Stream<List<ReadingListItemModel>> watchItems(String listId) {
    return _db
        .collection('reading_lists')
        .doc(listId)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ReadingListItemModel.fromFirestore(d)).toList());
  }

  Future<void> updateItemStatus({
    required String listId,
    required String itemId,
    required ReadingListItemStatus status,
  }) async {
    await _db
        .collection('reading_lists')
        .doc(listId)
        .collection('items')
        .doc(itemId)
        .update({'status': status.name});
    notifyListeners();
  }

  Future<void> removeItem({required String listId, required String itemId}) async {
    await _db.collection('reading_lists').doc(listId).collection('items').doc(itemId).delete();
    notifyListeners();
  }
}
