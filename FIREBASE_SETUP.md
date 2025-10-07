# Firebase Setup Instructions

## Current Issues
The app was getting "Missing or insufficient permissions" errors when trying to access the Firestore `notifications` collection. This has been fixed by updating the security rules.

Additionally, you might see "The query requires an index" errors. This has been resolved by removing the composite query and sorting in memory instead.

## Solution

### Option 1: Deploy Firestore Security Rules (Recommended)

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase in your project** (if not already done):
   ```bash
   cd "vibe 1"
   firebase init firestore
   ```

4. **Deploy the security rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Option 2: Update Rules in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `vibe1-7215e`
3. Go to **Firestore Database** → **Rules**
4. Replace the existing rules with the content from `firestore.rules`
5. Click **Publish**

### Option 3: Temporary Development Rules (Not Recommended for Production)

If you want to allow all access for development:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Current App Behavior

The app is currently designed to:
- Work with local storage (UserDefaults) for notifications
- Attempt to sync with Firebase when possible
- Gracefully handle Firebase permission errors
- Continue functioning even if Firebase is unavailable

## Testing

After deploying the rules:
1. Create a habit with allies
2. Check that notifications appear in the notifications tab
3. Verify no permission errors in the console

## Index Issues (Resolved)

If you see "The query requires an index" errors:
- This has been fixed by removing the composite query
- Notifications are now sorted in memory instead of in the database query
- No additional index creation is needed

If you still see index errors, you can create the required index by:
1. Clicking the URL provided in the error message
2. Or manually creating a composite index in Firebase Console:
   - Go to Firestore Database → Indexes
   - Create composite index for `notifications` collection
   - Fields: `toUserId` (Ascending), `timestamp` (Descending)

## Production Considerations

For production, you should:
1. Implement proper user authentication (not anonymous)
2. Restrict rules to only allow necessary operations
3. Add proper error handling and user feedback
4. Consider implementing push notifications for real-time updates
