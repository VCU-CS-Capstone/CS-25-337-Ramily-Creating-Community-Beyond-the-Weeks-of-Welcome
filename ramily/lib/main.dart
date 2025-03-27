import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ramily/Screens/login_screen.dart';
import 'package:ramily/services/user_service.dart';
import 'package:ramily/Screens/constants.dart' as constants;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services and ensure user data is complete
  final userService = UserService();
  
  // Regular initialization to ensure user documents are complete
  await userService.ensureUserDocument();
  await userService.syncUserNameData();
  
  runApp(const RamilyApp());
}

class RamilyApp extends StatelessWidget {
  const RamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAMily',
      theme: getAppTheme(),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// App theme configuration with VCU brand colors
ThemeData getAppTheme() {
  return ThemeData(
    // Base colors
    primaryColor: constants.kPrimaryColor,
    scaffoldBackgroundColor: constants.kVCUWhite,
    
    // Color scheme
    colorScheme: const ColorScheme.light(
      primary: constants.kPrimaryColor,
      secondary: constants.kVCUPurple,
      surface: constants.kVCUWhite,
      background: constants.kVCUWhite,
      error: constants.kVCURed,
      onPrimary: constants.kVCUWhite,
      onSecondary: constants.kVCUWhite,
      onSurface: constants.kDarkText,
      onBackground: constants.kDarkText,
      onError: constants.kVCUWhite,
    ),
    
    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: constants.kVCUWhite,
      foregroundColor: constants.kPrimaryColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: constants.kPrimaryColor),
      titleTextStyle: TextStyle(
        color: constants.kPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Elevated Button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: constants.kVCUGold,
        foregroundColor: constants.kPrimaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    
    // Text Button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: constants.kVCUPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    ),
    
    // Outlined Button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: constants.kPrimaryColor,
        side: const BorderSide(color: constants.kPrimaryColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: constants.kVCUWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: constants.kVCUPurple),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: constants.kVCURed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: Color(0xFFAAAAAA),
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        color: constants.kVCULightGrey,
        fontSize: 14,
      ),
    ),
    
    // Card theme
    cardTheme: CardTheme(
      color: constants.kVCUWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
    
    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return constants.kVCUPurple;
        }
        return null;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: constants.kVCUWhite,
      selectedItemColor: constants.kPrimaryColor,
      unselectedItemColor: constants.kVCULightText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    
    // Text theme
    textTheme: const TextTheme(
      // Headlines
      headlineLarge: TextStyle(
        fontSize: 24, 
        fontWeight: FontWeight.bold,
        color: constants.kPrimaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.bold,
        color: constants.kPrimaryColor,
      ),
      
      // Titles
      titleLarge: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w600,
        color: constants.kPrimaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.w600,
        color: constants.kPrimaryColor,
      ),
      
      // Body text
      bodyLarge: TextStyle(
        fontSize: 16, 
        color: constants.kDarkText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, 
        color: constants.kDarkText,
      ),
      bodySmall: TextStyle(
        fontSize: 12, 
        color: constants.kVCULightText,
      ),
    ),
    
    // Divider theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
      space: 1,
    ),
    
    // Tab bar theme
    tabBarTheme: const TabBarTheme(
      labelColor: constants.kVCUPurple,
      unselectedLabelColor: constants.kVCULightText,
      indicatorColor: constants.kVCUPurple,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
    ),
  );
}