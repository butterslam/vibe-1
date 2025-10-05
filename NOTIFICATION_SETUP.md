# Push Notification Setup Instructions

## Xcode Project Configuration

To enable push notifications in your app, you need to add the following capability:

### 1. Add Push Notifications Capability
1. Open your project in Xcode
2. Select the "vibe 1" target
3. Go to the "Signing & Capabilities" tab
4. Click the "+ Capability" button
5. Add "Push Notifications"

### 2. Background Modes (Optional but Recommended)
1. In the same "Signing & Capabilities" tab
2. Click "+ Capability" again
3. Add "Background Modes"
4. Check "Remote notifications"

## How It Works

The app now includes a complete notification system:

### NotificationManager
- Handles all notification scheduling and management
- Requests permission on app launch
- Schedules notifications 5 minutes before each habit's scheduled time
- Automatically updates notifications when habits are added, edited, or deleted

### Notification Scheduling
- Notifications are scheduled for each day selected by the user
- They trigger 5 minutes before the habit's scheduled time
- Notifications repeat weekly on the selected days
- Each notification includes:
  - Title: "Time for [Habit Name]!"
  - Body: "Your habit is starting in 5 minutes"
  - Sound and badge

### Automatic Management
- When a habit is added: Notification is automatically scheduled
- When a habit is edited: Notification is rescheduled with new settings
- When a habit is deleted: Notification is removed
- When the app launches: All notifications are rescheduled to ensure accuracy

## Testing Notifications

1. Add a habit with a time 6-7 minutes from now
2. Close the app or put it in the background
3. Wait for the notification to appear 5 minutes before the habit time

Note: Notifications only appear when the app is in the background or closed. They won't appear when the app is in the foreground.
