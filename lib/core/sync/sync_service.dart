import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';

class SyncService {
  final SupabaseClient _supabase;
  final AppDatabase _db;

  SyncService(this._supabase, this._db);

  Future<void> pushPendingChanges() async {
    final pending = await _db.select(_db.syncQueue).get();

    for (final op in pending) {
      try {
        if (op.operation == 'INSERT') {
          // TODO: map entityType to table and serialize entityId payload
          await _supabase.from(op.entityType).insert({});
        } else if (op.operation == 'UPDATE') {
          await _supabase.from(op.entityType).update({}).eq('id', op.entityId);
        } else if (op.operation == 'DELETE') {
          await _supabase.from(op.entityType).delete().eq('id', op.entityId);
        }

        // Remove from local queue on successful push
        await (_db.delete(
          _db.syncQueue,
        )..where((tbl) => tbl.id.equals(op.id))).go();
      } catch (e) {
        // Log sync failure, item remains in queue for next attempt
        debugPrint('Sync error for operation ${op.id}: $e');
      }
    }
  }
}
