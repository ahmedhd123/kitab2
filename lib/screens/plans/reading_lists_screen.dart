import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/reading_list_service.dart';
import '../../models/reading_list_model.dart';

class ReadingListsScreen extends StatelessWidget {
  const ReadingListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthFirebaseService>();
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));
    }
    final svc = context.read<ReadingListService>();

    return Scaffold(
      appBar: AppBar(title: const Text('قوائم القراءة')),
      body: StreamBuilder<List<ReadingListModel>>(
        stream: svc.watchUserLists(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lists = snapshot.data ?? [];
          if (lists.isEmpty) {
            return const Center(child: Text('لا توجد قوائم حتى الآن'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final l = lists[i];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(l.description ?? 'بدون وصف'),
                trailing: Text(l.privacy.name),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createList(context, userId),
        icon: const Icon(Icons.add),
        label: const Text('إنشاء قائمة'),
      ),
    );
  }

  Future<void> _createList(BuildContext context, String userId) async {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    var privacy = ReadingListPrivacy.private;
    final svc = context.read<ReadingListService>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اسم القائمة', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: nameC, decoration: const InputDecoration(hintText: 'مثال: كتب أرغب في قراءتها')),
                  const SizedBox(height: 8),
                  const Text('الوصف (اختياري)'),
                  TextField(controller: descC, decoration: const InputDecoration(hintText: 'وصف مختصر')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('الخصوصية:'),
                      const SizedBox(width: 8),
                      DropdownButton<ReadingListPrivacy>(
                        value: privacy,
                        items: ReadingListPrivacy.values
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                            .toList(),
                        onChanged: (v) => setState(() => privacy = v ?? ReadingListPrivacy.private),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameC.text.trim();
                        if (name.isEmpty) return;
                        await svc.createList(userId: userId, name: name, description: descC.text.trim(), privacy: privacy);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
