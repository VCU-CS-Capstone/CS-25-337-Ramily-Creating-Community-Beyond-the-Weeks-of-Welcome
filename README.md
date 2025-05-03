# *CS25-337 Project Description*
Freshmen and transfer students are seeking a deeper sense of belonging and community, as well as better connection to opportunities available during their time at VCU. Students shared that they felt overwhelmed having to figure out their academic, professional, and social lives all at once, especially in their first year at VCU. Students said that they also felt overwhelmed by the number of resources on campus. For example, students named 22 mobile apps that they had downloaded and used as they were trying to settle into life at VCU. da Vinci student teams proposed a homegrown, VCU mobile app that integrates key features from VCU Mobile (e.g., class schedule) and RamsConnect (e.g., student groups), and newly designed features aimed at enhancing students’ sense of belonging at VCU. The ultimate impact being facilitating a deeper connection between students & campus environment, improved mental health & student academic success, and improved student retention.

## *Sponsoring Company or Organization*
VCU da Vinci Center for Innovation

## *Short Project Description*
The directory structure in this GitHub is to allow the project to have all its resources self-contained.
Open Source software should not just be a repository of code.  There are a number of directories to help you and others who will 
follow in your footsteps.  It'll also allow the Linux Foundation OMP Mentorship program to keep track of your project and get
a better understanding of the problems you encountered during the development of this project. 

RAMily: Complete Documentation
==============================

Project Overview
----------------

RAMily is a mobile application designed to foster a sense of belonging among VCU students by facilitating connections based on academic and personal interests. The app features a matching system that pairs students with compatible peers, a traditions system that encourages exploration of iconic campus locations, and aims to consolidate multiple VCU services into a single platform.

Table of Contents
-----------------

1.  [Setup & Installation](#setup--installation)
2.  [System Requirements](#system-requirements)
3.  [Project Structure](#project-structure)
4.  [Key Features](#key-features)
5.  [Technical Implementation](#technical-implementation)
6.  [Firebase Configuration](#firebase-configuration)
7.  [Running the App](#running-the-app)
8.  [Debugging](#debugging)
9.  [Testing](#testing)
10. [Extending the App](#extending-the-app)

Setup & Installation
--------------------

### Prerequisites

-   Flutter SDK (version 3.0.0 or higher)
-   Dart SDK (version 2.17.0 or higher)
-   Visual Studio Code with Flutter and Dart extensions
-   Git
-   Firebase account
-   Android Studio Emulator or physical device for testing

### Clone the Repository

bash

```
git clone https://github.com/yourusername/ramily.git
cd ramily
```

### Install Dependencies

bash

```
flutter pub get
```

### VS Code Setup

1.  Open VS Code
2.  Install the following extensions:
    -   Flutter (Dart-Code.flutter)
    -   Dart (Dart-Code.dart-code)
    -   Firebase Explorer (jsayol.firebase-explorer) [Optional]
3.  Open the project folder in VS Code:

    ```
    File > Open Folder > [select ramily folder]
    ```

4.  Configure VS Code launch settings by creating `.vscode/launch.json`:

    json

    ```
    {
      "version": "0.2.0",
      "configurations": [
        {
          "name": "ramily",
          "request": "launch",
          "type": "dart",
          "flutterMode": "debug"
        }
      ]
    }
    ```

System Requirements
-------------------

### Development Environment

-   **Operating System**: Windows 10/11, macOS 10.15+, or Linux
-   **RAM**: 8GB minimum, 16GB recommended
-   **Disk Space**: 2GB for Flutter SDK, 1GB for project
-   **VS Code**: Version 1.60.0 or higher

### Target Devices

-   **Android**: API level 21 (Android 5.0) or higher
-   **iOS**: iOS 11.0 or higher

Project Structure
-----------------

The project follows a standard Flutter app structure with several key directories:

-   `/lib`: Contains all Dart code for the application
    -   `/Screens`: UI screens of the application
    -   `/services`: Business logic and services
    -   `/models`: Data models

### Key Files

-   `main.dart`: Entry point of the application
-   `firebase_options.dart`: Firebase configuration
-   `constants.dart`: App-wide constants including VCU brand colors
-   `matching_screen.dart`: Matching feature implementation
-   `traditions_screen.dart`: Traditions feature implementation
-   `chat_screen.dart` & `chat_detail_screen.dart`: Messaging functionality
-   `profile_creation_screen.dart`: User onboarding and profile setup
-   `profile_editor.dart`: Profile editing functionality

Key Features
------------

### User Authentication

RAMily uses Firebase Authentication to manage its users securely. Users create accounts with their email and a profile with their:

-   Name
-   Major
-   Pronouns
-   Interests (5 required)
-   Bio (using prompt-based system)

### Matching System

The custom matching algorithm considers:

-   Academic focus (major proximity using category-based scoring)
-   Personal interests (with bonuses for multiple shared interests)
-   Bio keyword compatibility
-   Pronouns compatibility
-   User-adjustable weighting between academic and social factors

Users can adjust the priority between academic and social matching using an intuitive slider interface that ranges from 30-70% in either direction.

### Traditions Feature

The traditions system encourages campus exploration through:

-   Location-based verification (±8m accuracy) of campus landmarks
-   Points system with varied values for different locations
-   Progress visualization with circular indicator
-   Special handling for seasonal events
-   Rewards for completing all non-seasonal traditions
-   Gamification elements to increase engagement

### Messaging

RAMily includes a real-time messaging system that:

-   Requires mutual connection acceptance
-   Provides unread message indicators
-   Shows delivery/read status
-   Includes message request management with approve/decline options
-   Supports reporting functionality

### Rambassadors Program

A key future feature that connects new students with upperclassmen mentors:

-   Personalized guidance for incoming freshmen and transfer students
-   Campus resource navigation assistance
-   Peer-to-peer support during transition to university life
-   Mentor matching based on academic pathways and interests
-   Schedule check-ins and progress tracking

### App Consolidation

RAMily aims to reduce "app fatigue" by integrating multiple VCU services into one platform:

-   Combines features from VCU Mobile and RamsConnect
-   Centralizes access to student groups, academic resources, and events
-   Streamlines student experience through unified interface
-   Reduces the need for multiple app downloads (students reported using up to 22 different apps)

Technical Implementation
------------------------

### Frontend

-   **Framework**: Flutter/Dart
-   **State Management**: Combination of StatefulWidget and Provider pattern
-   **UI Components**: Custom widgets built with Material Design following VCU branding
-   **Navigation**: Custom navigator implementation with TabController

### Backend

-   **Database**: Firebase Firestore
-   **Authentication**: Firebase Auth with custom JWT implementation
-   **Real-time Data**: Firebase Realtime Database
-   **Storage**: Local storage for profile images with path references in Firestore

### Key Algorithms

-   **Matching Algorithm**: The app uses a sophisticated weighted scoring system:
    -   Major proximity (1.0 for same major, 0.67 for same subcategory, 0.33 for same category)
    -   Interest overlap with bonuses for multiple shared interests
    -   Bio keyword compatibility based on common terms
    -   Small bonus for compatible pronouns
    -   User-controlled weighting using majorMultiplier value
    -   Final score curve applied for better distribution

Firebase Configuration
----------------------

### Setup Firebase Project

1.  Go to [Firebase Console](https://console.firebase.google.com/)
2.  Create a new project named "RAMily"
3.  Enable Firebase Authentication (Email/Password)
4.  Create a Firestore Database in production mode with appropriate rules
5.  Set up Firebase Realtime Database for chat functionality

### Database Structure

Key collections in Firestore:

-   `users`: User profiles and preferences
-   `chats`: Chat room metadata
-   `users/{userId}/user_chats`: Active chats for a user
-   `users/{userId}/message_requests`: Pending chat requests
-   `chats/{chatId}/messages`: Individual messages in a chat

### Connect Flutter App to Firebase

1.  Install the Firebase CLI:

    bash

    ```
    npm install -g firebase-tools
    ```

2.  Login to Firebase:

    bash

    ```
    firebase login
    ```

3.  Configure Firebase for Flutter:

    bash

    ```
    dart pub global activate flutterfire_cli
    flutterfire configure --project=your-firebase-project-id
    ```

4.  This will generate the necessary `firebase_options.dart` file
5.  Download the google-services.json file and place it in:

    ```
    android/app/google-services.json
    ```

6.  Download the GoogleService-Info.plist file and place it in:

    ```
    ios/Runner/GoogleService-Info.plist
    ```

7.  Ensure your firebase_options.dart file is correctly configured

Running the App
---------------

### Launch from VS Code

1.  Open the project in VS Code
2.  Select a device from the Device Selector in the status bar
3.  Click the "Run" button or press F5
4.  Alternatively, press Ctrl+F5 for release mode

### Debug with VS Code

1.  Set breakpoints by clicking in the gutter next to line numbers
2.  Launch the app in debug mode (F5)
3.  Use the Debug Console to inspect variables
4.  Use the Debug toolbar to control execution

### Run from Command Line

bash

```
flutter run
```

### Build Release Version

#### Android

bash

```
flutter build apk --release
```

#### iOS (requires macOS)

bash

```
flutter build ios --release
```

Debugging
---------

### Using VS Code Debugging Tools

1.  **Flutter DevTools**:
    -   Access from VS Code: View > Command Palette > Flutter: Open DevTools
    -   Use the Inspector to examine widget tree
    -   Use the Performance tab to identify bottlenecks
2.  **Console Logging**:
    -   View logs in VS Code's Debug Console
    -   Filter logs using the dropdown in the Debug Console
3.  **Hot Reload**:
    -   Make code changes and press Ctrl+F5 or click the Hot Reload button
    -   Use Hot Restart (Shift+F5) if state needs to be reset

### Common Issues

1.  **Firebase Connection Issues**
    -   Check internet connectivity
    -   Verify Firebase configuration in `firebase_options.dart`
    -   Check Firebase console for service status
2.  **Build Errors**
    -   Run `flutter clean` followed by `flutter pub get`
    -   Check VS Code Problems panel for specific error details
3.  **UI Layout Issues**
    -   Use Flutter DevTools Layout Explorer
    -   Add `debugPaintSizeEnabled = true` in `main.dart` to visualize layouts

Testing
-------

### Running Tests in VS Code

Use the Testing view in VS Code:

1.  Click the flask icon in the Activity Bar
2.  Click the Run button next to a test or test group

### Manual Testing Checklist

1.  **Authentication Flow**
    -   Register new account
    -   Log in with existing account
    -   Password reset flow
2.  **Profile Management**
    -   Create profile with all fields
    -   Edit profile information
    -   Verify changes persist after logout/login
3.  **Matching System**
    -   Adjust slider and verify results change
    -   View match details and verify calculations
    -   Send connection requests
    -   Filter matches by pronouns or major
4.  **Traditions System**
    -   View all traditions
    -   Mark traditions as complete/incomplete
    -   Verify progress indicator updates
    -   Test prize redemption modal
5.  **Messaging**
    -   Send and receive messages
    -   Accept/decline message requests
    -   Verify read receipts
    -   Test reporting functionality

Extending the App
-----------------

### Adding New Screens

1.  Create a new Dart file in the `/Screens` directory
2.  Add navigation to the screen in `main_navigator.dart`
3.  Update any related navigation methods in other files

### Modifying the Matching Algorithm

The matching algorithm is defined in `matching_screen.dart`. Key functions to modify:

-   `calculateProximityPoints`: Determines academic compatibility
-   `calculateMatchScore`: Computes overall match score
-   `getMajorCategoryAndSubcategory`: Maps majors to categories

### Adding New Traditions

1.  Modify the `_traditionsList` in `traditions_screen.dart`
2.  Add new images to `assets/traditions/`
3.  Update the point values and descriptions as needed

### Implementing Rambassadors

The Rambassadors mentorship program will be a future feature connecting new students with upperclassmen volunteers:

1.  Create mentor profiles with areas of expertise
2.  Implement a matching system similar to the main matching feature
3.  Add mentor request and confirmation workflow
4.  Develop messaging templates for common questions

### App Consolidation

For integrating additional VCU services:

1.  Identify APIs and integration points for existing VCU platforms
2.  Create adapter services in the `/services` directory
3.  Implement authentication delegation to maintain secure access
4.  Build unified interface elements for consistent user experience

### Customizing Appearance

1.  Modify VCU brand colors in `constants.dart`
2.  Update theme configuration in `main.dart`
3.  Adjust widget styles in individual screen files

## Project Team
- *Manjari Kumarappan*  - *VCU da Vinci Center for Innovation* - Mentor
- *Lukasz Kurgan* - *VCU Computer Science Department* - Faculty Advisor
- *Tariq Gafar* - *Computer Science* - Student Team Member
- *DaJuan Hackett* - *Computer Science* - Student Team Member
- *Ziad Kashef* - *Computer Science* - Student Team Member - ziadkashef@gmail.com
- *Raleigh Norris* - *Computer Science* - Student Team Member
