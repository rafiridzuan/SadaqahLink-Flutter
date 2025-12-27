# Firebase Cloud Functions - Deployment Guide

## 📦 What's Included

### Main Function: `sendTransactionNotification`
**Trigger:** `/transactions/{trxId}` (onCreate)

**What it does:**
1. ✅ Detects new transaction in Firebase Realtime Database
2. ✅ Reads transaction data: `note`, `value`, `tarikh`, `jumlahRM`
3. ✅ Converts value to RM: `rm = value / 100`
4. ✅ Fetches **all FCM tokens** from **all users**: `users/{uid}/fcmTokens/{deviceId}`
5. ✅ Sends push notification to **every device**
6. ✅ Handles failed tokens gracefully

**Notification Body:**
- RM1: "Ding dong! Your surau's tabung has received RM1"
- RM5: "Ding dong! Your surau's tabung has received RM5"
- RM10: "Alhamdulillah! Your surau's tabung has received RM10"
- RM20: "Alhamdulillah! Your surau's tabung has received RM20"
- RM50: "Subhanallah! Your surau's tabung has received RM50"
- RM100: "MasyaAllah! Your surau's tabung has received RM100"
- Other: "{note} detected: RM{amount}"

---

### Bonus Function: `cleanupInvalidTokens`
**Trigger:** HTTP endpoint

**What it does:**
- Validates all FCM tokens in database
- Removes expired/invalid tokens automatically
- Returns cleanup summary

**Access:** `https://<region>-<project-id>.cloudfunctions.net/cleanupInvalidTokens`

---

### Bonus Function: `sendTestNotification`
**Trigger:** HTTP endpoint

**What it does:**
- Sends test notification to all registered devices
- Useful for testing the notification system
- Returns success/failure count

**Access:** `https://<region>-<project-id>.cloudfunctions.net/sendTestNotification`

---

## 🚀 Deployment Steps

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Test Locally (Optional)

```bash
# Start Firebase emulator
firebase emulators:start

# Or just functions emulator
npm run serve
```

### 3. Deploy to Firebase

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendTransactionNotification
```

### 4. Verify Deployment

After deployment, you should see output like:
```
✔  functions[sendTransactionNotification] Successful create operation.
✔  functions[cleanupInvalidTokens] Successful create operation.
✔  functions[sendTestNotification] Successful create operation.

Function URL (sendTestNotification): https://us-central1-your-project.cloudfunctions.net/sendTestNotification
Function URL (cleanupInvalidTokens): https://us-central1-your-project.cloudfunctions.net/cleanupInvalidTokens
```

---

## 🧪 Testing

### Test 1: Automatic Notification (Transaction Created)

**Method:** Create a new transaction in Firebase Realtime Database

```javascript
// In Firebase Console or your app
const newTransaction = {
  note: "Tabung Masjid",
  value: 1000,  // RM10.00 (in cents)
  tarikh: "2025-12-02",
  jumlahRM: "RM10.00"
};

// Add to /transactions
firebase.database().ref('transactions').push(newTransaction);
```

**Expected Result:**
- All logged-in users receive notification
- Notification body: "Alhamdulillah! Your surau's tabung has received RM10"
- Check Cloud Functions logs in Firebase Console

---

### Test 2: Manual Test Notification

**Method:** Call the HTTP endpoint

```bash
# Using curl
curl https://us-central1-your-project.cloudfunctions.net/sendTestNotification

# Or open in browser
https://us-central1-your-project.cloudfunctions.net/sendTestNotification
```

**Expected Response:**
```json
{
  "success": true,
  "totalTokens": 5,
  "successCount": 5,
  "failureCount": 0
}
```

---

### Test 3: Cleanup Invalid Tokens

**Method:** Call the cleanup endpoint

```bash
curl https://us-central1-your-project.cloudfunctions.net/cleanupInvalidTokens
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Cleaned up 2 invalid tokens",
  "totalCleaned": 2
}
```

---

## 📊 Monitoring

### View Logs in Firebase Console

1. Go to Firebase Console → Functions
2. Click on `sendTransactionNotification`
3. Click "Logs" tab
4. You'll see:
   - Transaction details
   - Number of tokens found
   - Success/failure counts
   - Error messages (if any)

### Sample Log Output

```
New transaction -NDx12345: {note: "Tabung Masjid", value: 1000, ...}
Processing donation: Tabung Masjid - RM10.00
User abc123: 2 tokens
User xyz789: 1 tokens
Total tokens to send: 3
Successfully sent to 3 devices
```

---

## 🔧 Troubleshooting

### Issue: No notifications received

**Possible causes:**
1. ❌ No FCM tokens in database → Log in on the Flutter app first
2. ❌ Tokens expired → Run `cleanupInvalidTokens` then re-login
3. ❌ Function not deployed → Run `firebase deploy --only functions`

**Debug:**
```bash
# Check function logs
firebase functions:log --only sendTransactionNotification

# Test with manual notification
curl https://<your-url>/sendTestNotification
```

---

### Issue: Function deployment failed

**Solution:**
```bash
# Check Node.js version (should be 18)
node --version

# Reinstall dependencies
cd functions
rm -rf node_modules package-lock.json
npm install

# Deploy again
firebase deploy --only functions
```

---

## 📝 Database Structure Expected

```
database/
├── transactions/
│   └── {trxId}/
│       ├── note: "Tabung Masjid"
│       ├── value: 1000          # cents (RM10.00)
│       ├── tarikh: "2025-12-02"
│       └── jumlahRM: "RM10.00"
│
└── users/
    ├── {uid1}/
    │   └── fcmTokens/
    │       ├── device1: "token_abc123..."
    │       └── device2: "token_xyz789..."
    └── {uid2}/
        └── fcmTokens/
            └── device3: "token_def456..."
```

---

## 🎯 Expected Behavior

1. **New transaction created** → Cloud Function triggers automatically
2. Function reads all users from `/users`
3. Collects all FCM tokens from all users
4. Sends notification to **all tokens at once**
5. Logs success/failure counts
6. Returns result

**Result:** Every logged-in device receives the notification simultaneously! 🎉

---

## 🔒 Security Notes

- ✅ Functions run with admin privileges (can read all data)
- ✅ HTTP endpoints are public (consider adding authentication if needed)
- ✅ Invalid tokens are automatically handled and can be cleaned up
- ✅ No sensitive data exposed in notifications

---

## 📱 Integration with Flutter App

The Flutter app already has everything setup:
- ✅ FCM tokens saved on login
- ✅ Tokens removed on logout
- ✅ Automatic token refresh
- ✅ Notifications handled in all states (foreground, background, terminated)

**No changes needed in Flutter app!** Just deploy the Cloud Functions and it works! 🚀

---

## 🆘 Need Help?

Check Firebase Console → Functions → Logs for detailed error messages.

Common commands:
```bash
# View logs
firebase functions:log

# Delete a function
firebase functions:delete sendTransactionNotification

# Redeploy
firebase deploy --only functions
```
