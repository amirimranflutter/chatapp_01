import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/profileScreen.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/splashScreen.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/constant.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/hive_db_service.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/profileService.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cld chat/chat_app_01/Providers/contact-Provider.dart';
import 'cld chat/chat_app_01/Screens/MainScreen.dart';
import 'cld chat/chat_app_01/auth/authScreen.dart';
import 'cld chat/chat_app_01/databaseServices/authDBService.dart';
import 'cld chat/chat_app_01/services/authService.dart';
import 'cld chat/chat_app_01/services/chatService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await HiveAuthService.init();

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: Constants.supabaseUrl,
      anonKey: Constants.supabaseAnonKey,
    );
  } catch (e) {
    print('Supabase init error: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(
          create: (_) => ContactProvider()
        ),
        ChangeNotifierProvider(create: (_) => ProfileService()),
      ],
      child: MaterialApp(
        title: 'Flutter Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        //     home: Consumer<AuthService>(
        //       builder: (context, authService, _) {
        //         if (authService.isLoading) {
        //           return Scaffold(
        //             body: Center(child: CircularProgressIndicator()),
        //           );
        //         }
        //         return authService.currentUser != null ? MainScreen() : AuthScreen();
        //       },
        //     ),
        //     home: SplashScreen(),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/loginScreen': (context) => AuthScreen(),
          '/mainScreen': (context) => MainScreen(),

          // '/main':(context)=>ProfileScreen(userId: userId),
        },
      ),
    );
  }
}
