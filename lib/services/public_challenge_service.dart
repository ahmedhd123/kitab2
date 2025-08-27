import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/public_challenge_model.dart';

/// خدمة التحديات العامة (قابلة للانضمام برابط/رمز)
class PublicChallengeService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<PublicChallengeModel> _publicChallenges = [];
  List<PublicChallengeModel> get publicChallenges => List.unmodifiable(_publicChallenges);

  // إنشاء تحدي عام جديد
  Future<PublicChallengeModel> createPublicChallenge({
    required String ownerId,
    required String title,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final now = DateTime.now();
    final invite = _genInviteToken();
    final data = {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'createdAt': Timestamp.fromDate(now),
      'status': 'active',
      'inviteToken': invite,
    };
    final ref = await _db.collection('public_challenges').add(data);
    final doc = await ref.get();
    final challenge = PublicChallengeModel.fromFirestore(doc);
    _publicChallenges.insert(0, challenge);
    notifyListeners();
    return challenge;
  }

  // جلب التحديات العامة النشطة
  Future<void> loadActiveChallenges() async {
    final q = await _db
        .collection('public_challenges')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .get();
    _publicChallenges = q.docs.map(PublicChallengeModel.fromFirestore).toList();
    notifyListeners();
  }

  // الانضمام لتحدي بواسطة inviteToken
  Future<void> joinByInvite({
    required String inviteToken,
    required String userId,
    String? displayName,
    required List<ChallengeBookEntry> books,
    required int durationDays,
  }) async {
    final challenge = await _findByToken(inviteToken);
    if (challenge == null) throw Exception('التحدي غير موجود');

    // حساب إجمالي الصفحات
    final pagesTarget = books.fold<int>(0, (sum, b) => sum + (b.pages));
    final participant = ChallengeParticipant(
      userId: userId,
      displayName: displayName,
      joinedAt: DateTime.now(),
      pagesTarget: pagesTarget,
      pagesRead: 0,
      durationDays: durationDays,
      books: books,
    );

    final participantsCol = _db
        .collection('public_challenges')
        .doc(challenge.id)
        .collection('participants');

    // منع التعديل على الآخرين: نكتب على وثيقة المشارك فقط
    await participantsCol.doc(userId).set(participant.toMap());
  }

  // تحديث التقدم (عدد الصفحات المقروءة)
  Future<void> updateProgress({
    required String challengeId,
    required String userId,
    required int pagesRead,
  }) async {
    await _db
        .collection('public_challenges')
        .doc(challengeId)
        .collection('participants')
        .doc(userId)
        .set({'pagesRead': pagesRead}, SetOptions(merge: true));
  }

  // إغلاق التحدي بعد انتهاء المدة (يمنع التعديلات)
  Future<void> closeIfExpired(String challengeId) async {
    final doc = await _db.collection('public_challenges').doc(challengeId).get();
    final c = PublicChallengeModel.fromFirestore(doc);
    if (DateTime.now().isAfter(c.endAt) && c.status != 'closed') {
      await _db.collection('public_challenges').doc(challengeId).update({'status': 'closed'});
    }
  }

  // جلب المشاركين لمشاهدة تقدمهم (للمُنظمين)
  Stream<List<ChallengeParticipant>> watchParticipants(String challengeId) {
    return _db
        .collection('public_challenges')
        .doc(challengeId)
        .collection('participants')
        .snapshots()
        .map((s) => s.docs.map(ChallengeParticipant.fromFirestore).toList());
  }

  // مراقبة تحدي واحد
  Stream<PublicChallengeModel> watchChallenge(String challengeId) {
    return _db
        .collection('public_challenges')
        .doc(challengeId)
        .snapshots()
        .map(PublicChallengeModel.fromFirestore);
  }

  Future<PublicChallengeModel?> _findByToken(String token) async {
    final q = await _db
        .collection('public_challenges')
        .where('inviteToken', isEqualTo: token)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return PublicChallengeModel.fromFirestore(q.docs.first);
  }

  String _genInviteToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
