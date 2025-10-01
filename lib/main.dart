import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cld chat/chat_app_01/Screens/MainScreen.dart';
import 'cld chat/chat_app_01/Screens/authScreen.dart';
import 'cld chat/chat_app_01/auth/authService.dart';
import 'cld chat/chat_app_01/services/chatService.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: Constants.supabaseUrl,
      anonKey:Constants.supabaseAnonKey,
    );
  } catch (e) {
    print('Supabase init error: $e');
  }
  runApp( MyApp());
}


class MyApp extends StatelessWidget {
@override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthService()),
      ChangeNotifierProvider(create: (_) => ChatService()),
    ],
    child: MaterialApp(
      title: 'Flutter Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (authService.isLoading) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return authService.currentUser != null ? MainScreen() : AuthScreen();
        },
      ),
    ),
  );
}
}
