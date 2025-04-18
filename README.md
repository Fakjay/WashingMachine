# WashingMachine - Padel Tennis Pairing App

A dynamic iOS app for padel tennis players that automatically pairs players into balanced teams and manages matches.

## Features

- **Dynamic Player Pairing**: Automatically pairs players based on skill level, creating balanced matches
- **Score Tracking**: Input match scores and track player performance
- **ELO Rating System**: Players' ratings change based on match results
- **Match Management**: Create, join, and manage padel tennis matches
- **User Profiles**: Personalized profiles with stats, match history, and skill ratings

## Technical Overview

### Architecture

The app is built with SwiftUI for iOS and uses Firebase for backend services:

- **Frontend**: SwiftUI
- **Authentication**: Firebase Authentication
- **Database**: Firestore
- **Storage**: Firebase Storage (for profile pictures)
- **Notifications**: Firebase Cloud Messaging and Apple Push Notification Service

### Key Components

1. **Authentication System**
   - Email/password login
   - OAuth support (Apple, Google)
   - User profile management

2. **Match Management**
   - Create matches with configurable rules
   - Join existing matches
   - Public and private matches with invite codes

3. **Pairing Algorithm**
   - ELO-based player rating system
   - Balanced team creation
   - Avoids repeat pairings in the same match

4. **Score Tracking**
   - Set-by-set score input
   - Automatic winner determination
   - Player stats tracking

## Testing

The application includes a comprehensive test suite to ensure code quality and functionality:

### Test Categories

1. **Model Tests**
   - `UserTests`: Validates user model properties and computed values
   - `MatchTests`: Tests match creation and state management
   - `MatchSetTests`: Verifies the scoring functionality

2. **Service Tests**
   - `AuthServiceTests`: Tests authentication workflows
   - `MatchServiceTests`: Validates match creation and updates
   - `NotificationServiceTests`: Ensures notifications are properly handled

### Running Tests

1. Open the project in Xcode
2. Select the WashingMachine scheme
3. Press ⌘U or navigate to Product > Test
4. View test results in the Test Navigator

### Test Coverage

The tests cover:
- Model initialization and property validation
- Computed property calculations
- Service operation success and failure scenarios
- Firebase integration points (with mocking)

## Getting Started

### Prerequisites

- Xcode 14.0+
- iOS 15.0+
- Swift 5.7+
- Firebase account

### Setup

1. Clone the repository
2. Create a Firebase project and download the `GoogleService-Info.plist` file
3. Replace the placeholder `GoogleService-Info.plist` with your Firebase configuration
4. Open the project in Xcode and build

### Firebase Configuration

The app requires the following Firebase services:

- Authentication (with Email/Password enabled)
- Firestore Database
- Cloud Storage
- Cloud Messaging (for push notifications)

## Usage

### Creating a Match

1. Navigate to the Matches tab
2. Tap the "+" button
3. Fill in match details:
   - Location
   - Date and time
   - Number of players
   - Court numbers
   - Match rules
4. Set visibility (public or private)
5. Tap "Create Match"

### Joining a Match

1. Browse available matches on the Matches tab
2. Tap on a match to view details
3. Tap "Register" to join
4. For private matches, enter the invite code

### Playing a Match

1. Once all players are registered, the app generates the first round of pairings
2. Play your match on the assigned court
3. Enter the score after completion
4. New pairings are generated for the next round based on updated ratings
5. Continue until all rounds are completed

## License

This project is licensed under the MIT License

## Acknowledgments

- Design inspiration: [Selfcare App UI on Dribbble](https://dribbble.com/shots/24229066-Selfcare-App-UI) 