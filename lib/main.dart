import 'package:chat_app_cld/cld%20chat/chat_app_01/AuthServices/authLocalService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/globalSyncManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cld chat/chat_app_01/AuthServices/authSyncService.dart';
import 'cld chat/chat_app_01/Providers/chatProvider.dart';
import 'cld chat/chat_app_01/Providers/contact-Provider.dart';
import 'cld chat/chat_app_01/Providers/profileProvider.dart';
import 'cld chat/chat_app_01/Screens/MainScreen.dart';
import 'cld chat/chat_app_01/Screens/chatScreen.dart';
import 'cld chat/chat_app_01/Screens/profileScreen.dart';
import 'cld chat/chat_app_01/Screens/splashScreen.dart';
import 'cld chat/chat_app_01/auth/authScreen.dart';
import 'cld chat/chat_app_01/Utils/constant.dart';
import 'cld chat/chat_app_01/models/userModel.dart';
import 'cld chat/chat_app_01/services/MessageServices/localMessage.dart';
import 'cld chat/chat_app_01/services/MessageServices/messageRepository.dart';
import 'cld chat/chat_app_01/services/MessageServices/remoteMessage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Hive
  await Hive.initFlutter();

  Hive.registerAdapter(UserModelAdapter());
  await Hive.deleteFromDisk();
  await AuthLocalService.init();


  // ✅ Initialize Supabase
  try {
    await Supabase.initialize(
      url: Constants.supabaseUrl,
      anonKey: Constants.supabaseAnonKey,
    );
    print("✅ Supabase initialized successfully");
  } catch (e) {
    print("⚠️ Supabase initialization error: $e");
  }

  // ✅ Prepare message repository
  final repo = MessageRepository(
    HiveMessageService(),
    SupabaseMessageService(),
  );

  // ✅ Run app
  runApp(MyApp(repo: repo));
}

class MyApp extends StatelessWidget {
  final MessageRepository repo;

  const MyApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthSyncService()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            repo,
            currentUserId: Supabase.instance.client.auth.currentUser?.id ?? '',
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          // ✅ Start global sync listener here
          GlobalSyncManager.startSyncListener(context);

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Chat',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => SplashScreen(),
              '/loginScreen': (context) => AuthScreen(),
              '/mainScreen': (context) => MainScreen(),
              '/profile': (context) => ProfileScreen(),
              // '/chat': (context) => ChatScreen(),

            },
          );
        },
      ),
    );
  }
}

