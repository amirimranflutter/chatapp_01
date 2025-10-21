import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../Providers/contact-Provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkHelper {
  // 1️⃣ Check current internet connection
  Future<bool> checkInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // 2️⃣ Listen for connectivity changes
  void initConnectivityListener(BuildContext context) {
    Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        // Auto-upload pending contacts when network is back
        Provider.of<ContactProvider>(context, listen: false)
            .uploadPendingContacts(context);
      }
    });
  }
}

