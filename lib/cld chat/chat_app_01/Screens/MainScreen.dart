import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/contact-Provider.dart';
import '../Screens/contactScreen.dart';
import '../Utils/globalSyncManager.dart';
import '../services/contactService/hive_db_service.dart';
import '../services/contactService/syncService.dart';

// These are placeholders for your other pages
import 'callScreen.dart';
import 'chatListScreen.dart'; // Page 1
import 'profileScreen.dart';  // Page 4

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final SyncContactService _syncService;
  // final currentUser=AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    _syncService = SyncContactService();
    // GlobalSyncManager().initConnectivityListener(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      await contactProvider.loadContacts();
      // final authService = Provider.of<AuthService>(context, listen: false);

      debugPrint("✅ Contacts preloaded at startup");
    });
    GlobalSyncManager.startSyncListener(context);

    // ✅ Trigger one-time sync check when app opens
    Future.delayed(const Duration(seconds: 1), () async {
      final hasInternet = await GlobalSyncManager.checkInternet();
      final hasPending = await HiveDBService().hasPendingContacts();

      if (hasPending && hasInternet) {
        print("🚀 Pending contacts found — starting sync now...");
        await SyncContactService().syncContacts(context);
      } else {
        print("💤 No pending contacts or offline — skipping startup sync");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
       ChatContactListScreen(),
      const CallsScreen(),
      const ContactsScreen(),
      // ProfileScreen(userId: currentUser!.id),
      ProfileScreen(),
    ];
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: "Calls",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Contacts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
