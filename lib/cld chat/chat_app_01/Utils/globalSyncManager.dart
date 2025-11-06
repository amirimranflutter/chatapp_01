import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/syncContactService.dart';
import 'package:provider/provider.dart';

import '../Providers/contact-Provider.dart';



class GlobalSyncManager {
  static final _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _stream;
  static bool _isListening = false; // ✅ Prevent multiple listeners

  /// ✅ Start listening for internet connection changes
  static void startSyncListener(BuildContext context) {
    if (_isListening) return; // already running
    _isListening = true;

    _stream = _connectivity.onConnectivityChanged.listen((results) async {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        print('🌐 Internet restored — syncing pending data...');

        try {
          // ✅ Get your provider instance safely
          final contactProvider =
          Provider.of<ContactProvider>(context, listen: false);

          // ✅ Run the sync process
          await contactProvider.syncContacts(context);
          SyncContactService().syncPendingDeletes(context);
          print("✅ Contacts synced successfully after reconnection!");
        } catch (e) {
          print("🔥 Error during auto-sync: $e");
        }
      }
    });

    print("🔔 GlobalSyncManager listener started (once)");
  }

  /// ✅ Check if network available
  static Future<bool> checkInternet() async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && result.first != ConnectivityResult.none;
  }

  /// 🧹 Stop listener
  static void dispose() {
    _stream?.cancel();
    _isListening = false;
    print("🧹 GlobalSyncManager listener disposed");
  }
}
