# Quick Deploy Guide

## Deploy Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

## Test Notification

Create a transaction in Firebase Console or app:
```javascript
{
  "note": "Tabung Masjid",
  "value": 1000,  // RM10.00
  "tarikh": "2025-12-02",
  "jumlahRM": "RM10.00"
}
```

All logged-in devices will receive notification! ✅

## Useful Commands

```bash
# View logs
firebase functions:log

# Test via HTTP
curl https://<region>-<project>.cloudfunctions.net/sendTestNotification

# Cleanup invalid tokens
curl https://<region>-<project>.cloudfunctions.net/cleanupInvalidTokens
```

## What Notifications Look Like

- **RM1-5:** "Ding dong! Your surau's tabung has received RM{X}"
- **RM10-20:** "Alhamdulillah! Your surau's tabung has received RM{X}"
- **RM50:** "Subhanallah! Your surau's tabung has received RM50"
- **RM100:** "MasyaAllah! Your surau's tabung has received RM100"
- **Other:** "{note} detected: RM{amount}"

See `DEPLOYMENT.md` for detailed instructions.
