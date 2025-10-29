import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/syncService.dart';

class GlobalSyncManager {
  static final _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _stream;
  static bool _isListening = false; // ✅ Prevent duplicate listeners

  static void startSyncListener(BuildContext context) {
    if (_isListening) return; // ✅ Skip if already started
    _isListening = true;

    _stream = _connectivity.onConnectivityChanged.listen((results) async {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        print('🌐 Network available — syncing pending data');
        await SyncContactService().syncContacts(context);
        SyncContactService().syncPendingDeletes(context);
        // Optionally: await SyncService().syncMessages(context);
      }
    });

    print("🔔 GlobalSyncManager listener started once");
  }

  static Future<bool> checkInternet() async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && result.first != ConnectivityResult.none;
  }

  static void dispose() {
    _stream?.cancel();
    _isListening = false;
  }

}
