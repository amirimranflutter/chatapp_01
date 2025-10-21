import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/networkHelpr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Providers/contact-Provider.dart';
import '../services/contactService/syncService.dart';
import '../Screens/contactScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final SyncService _syncService;
  late final ContactProvider _contactProvider;

  @override
  void initState() {
    super.initState();
    NetworkHelper().initConnectivityListener(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _contactProvider = Provider.of<ContactProvider>(context, listen: false);

      // ✅ Only initialize sync layers — not used yet
      _syncService = SyncService( );

      try {
        // ✅ Just load contacts from Hive for debugging
        // await _contactProvider.loadLocalContacts();
        debugPrint("✅ Local contacts loaded successfully");
      } catch (e) {
        debugPrint("❌ Error loading local contacts: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts Debug Mode0'),
      ),
      body: ContactsScreen(),
    );
  }
}
