import 'package:church_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kIsWeb) {
    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Request permission for web
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
      ],
      child: MaterialApp(
        title: "Christ's Chapel Church Velangi",
        theme: ThemeData(
          primaryColor: Colors.orange[700],
          scaffoldBackgroundColor: Colors.orange[50],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.orange[700],
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.orange[100],
            selectedItemColor: Colors.orange[700],
            unselectedItemColor: Colors.brown[300],
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/profile-creation': (context) => ProfileScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.user != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: Provider.of<FirestoreService>(context, listen: false).getUserProfile(authService.user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                // Automatically create user profile with 'member' role for new users
                final user = authService.user!;
                FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'role': 'member',
                  'createdAt': FieldValue.serverTimestamp(),
                  'email': user.email,
                  'displayName': user.displayName,
                }, SetOptions(merge: true));
                // Optionally, you can show a loading indicator while the profile is being created
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return HomeScreen();
            },
          );
        }

        return LoginScreen();
      },
    );
  }
}

class _RoleSelectionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Your Role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.person, color: Colors.orange[700]),
            title: Text('Member'),
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'role': 'member',
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.church, color: Colors.orange[700]),
            title: Text('Pastor'),
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'role': 'pastor',
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
