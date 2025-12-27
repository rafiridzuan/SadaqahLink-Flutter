const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function: Send push notification when new transaction is created
 * Calculates today's total and sends to all devices
 */
exports.sendTransactionNotification = functions.database
    .ref("/transactions/{trxId}")
    .onCreate(async (snapshot, context) => {
        try {
            const trxId = context.params.trxId;
            const transaction = snapshot.val();

            console.log(`New transaction ${trxId}:`, transaction);

            // Extract transaction data
            let note = transaction.note || "Donation";
            let value = transaction.value || 0;
            const tarikh = transaction.tarikh || "";

            // Fallback: If value is 0, try to parse from note (e.g. "RM10")
            if (value === 0 && note) {
                const match = note.match(/RM\s*(\d+)/i);
                if (match && match[1]) {
                    value = parseInt(match[1]) * 100; // Convert to cents
                    console.log(`Parsed value from note: ${value} cents`);
                }
            }

            // Convert value to RM (value is in cents)
            const rm = (value / 100).toFixed(2);

            console.log(`Processing donation: ${note} - RM${rm}`);

            // Calculate today's total donations (same logic as dashboard)
            const today = new Date();
            const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
            const todayTimestamp = todayStart.getTime();

            const allTransactionsSnapshot = await admin.database().ref("transactions").once("value");
            let todayTotal = 0;

            if (allTransactionsSnapshot.exists()) {
                const transactions = allTransactionsSnapshot.val();
                for (const txId in transactions) {
                    const tx = transactions[txId];

                    // Parse transaction date
                    let txDate;
                    if (tx.tarikh) {
                        txDate = new Date(tx.tarikh);
                    } else if (tx.timestamp) {
                        txDate = new Date(tx.timestamp);
                    } else {
                        continue;
                    }

                    // Check if transaction is from today
                    const txStart = new Date(txDate.getFullYear(), txDate.getMonth(), txDate.getDate());

                    if (txStart.getTime() >= todayTimestamp) {
                        todayTotal += (tx.value || 0) / 100;
                    }
                }
            }

            const todayTotalFormatted = todayTotal.toFixed(2);
            console.log(`Today's total: RM${todayTotalFormatted}`);

            // Get all users from database
            const usersSnapshot = await admin.database().ref("users").once("value");

            if (!usersSnapshot.exists()) {
                console.log("No users found in database");
                return null;
            }

            const users = usersSnapshot.val();
            const allTokens = [];

            // Collect all FCM tokens from all users
            for (const uid in users) {
                const user = users[uid];

                if (user.fcmTokens && typeof user.fcmTokens === "object") {
                    const tokens = Object.values(user.fcmTokens);
                    allTokens.push(...tokens);
                    console.log(`User ${uid}: ${tokens.length} tokens`);
                }
            }

            if (allTokens.length === 0) {
                console.log("No FCM tokens found for any user");
                return null;
            }

            console.log(`Total tokens to send: ${allTokens.length}`);

            // Create custom notification based on amount
            const amountInt = Math.floor(value / 100);
            let title = "";
            let body = "";

            switch (amountInt) {
                case 1:
                    title = `RM1. Total RM${todayTotalFormatted}`;
                    body = "Ding dong! RM1 just landed! Every sen counts!";
                    break;
                case 5:
                    title = `RM5. Total RM${todayTotalFormatted}`;
                    body = "Wohoo! RM5 incoming! Tabung getting thicc!";
                    break;
                case 10:
                    title = `RM10. Total RM${todayTotalFormatted}`;
                    body = "Alhamdulillah! RM10 detected! Someone's feeling generous today!";
                    break;
                case 20:
                    title = `RM20. Total RM${todayTotalFormatted}`;
                    body = "MasyaAllah! RM20 punya power! Tabung naik taraf!";
                    break;
                case 50:
                    title = `RM50. Total RM${todayTotalFormatted}`;
                    body = "Subhanallah! RM50 confirmed! Tabung berdentang-dentang!";
                    break;
                case 100:
                    title = `RM100. Total RM${todayTotalFormatted}`;
                    body = "JACKPOT! RM100 masuk! Boss mode activated!";
                    break;
                default:
                    title = "Your surau's tabung has received";
                    body = `RM${rm}! Total RM${todayTotalFormatted} - Barakallah`;
            }

            // Send to all tokens with high priority for background notifications
            // NOTE: We are sending DATA-ONLY message (no notification block)
            // This forces the Flutter app's background handler to wake up and show the notification manually
            // This bypasses Android's "heads-up" suppression for subsequent notifications
            const response = await admin.messaging().sendEachForMulticast({
                tokens: allTokens,
                data: {
                    title: title,
                    body: body,
                    trxId: trxId,
                    note: note,
                    amount: rm,
                    todayTotal: todayTotalFormatted,
                    tarikh: tarikh,
                    type: "transaction",
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    tag: `donation_${Date.now()}_${Math.random()}`,
                },
                android: {
                    priority: "high",
                },
                apns: {
                    headers: {
                        "apns-priority": "10",
                    },
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                            contentAvailable: true,
                            category: "DONATION",
                        },
                    },
                },
            });

            console.log("Successfully sent message:", response);

            // Check for failed tokens
            if (response.failureCount > 0) {
                console.log(`${response.failureCount} tokens failed`);

                response.responses.forEach((resp, index) => {
                    if (!resp.success) {
                        console.error(`Token ${index} failed:`, resp.error);
                    }
                });
            }

            console.log(`Successfully sent to ${response.successCount} devices`);

            return {
                success: true,
                totalSent: response.successCount,
                totalFailed: response.failureCount,
            };
        } catch (error) {
            console.error("Error sending notification:", error);
            return null;
        }
    });

/**
 * Optional: Clean up invalid FCM tokens
 */
exports.cleanupInvalidTokens = functions.https.onRequest(async (req, res) => {
    try {
        const usersSnapshot = await admin.database().ref("users").once("value");

        if (!usersSnapshot.exists()) {
            return res.status(200).json({ success: true, message: "No users found" });
        }

        const users = usersSnapshot.val();
        let totalCleaned = 0;

        for (const uid in users) {
            const user = users[uid];

            if (user.fcmTokens && typeof user.fcmTokens === "object") {
                for (const deviceId in user.fcmTokens) {
                    const token = user.fcmTokens[deviceId];

                    try {
                        await admin.messaging().send({
                            token: token,
                            data: { type: "validation" },
                            dryRun: true,
                        });
                    } catch (error) {
                        console.log(`Removing invalid token for user ${uid}, device ${deviceId}`);
                        await admin.database()
                            .ref(`users/${uid}/fcmTokens/${deviceId}`)
                            .remove();
                        totalCleaned++;
                    }
                }
            }
        }

        return res.status(200).json({
            success: true,
            message: `Cleaned up ${totalCleaned} invalid tokens`,
            totalCleaned: totalCleaned,
        });
    } catch (error) {
        console.error("Error cleaning up tokens:", error);
        return res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Optional: Send test notification to all users
 */
exports.sendTestNotification = functions.https.onRequest(async (req, res) => {
    try {
        const usersSnapshot = await admin.database().ref("users").once("value");

        if (!usersSnapshot.exists()) {
            return res.status(200).json({ success: false, message: "No users found" });
        }

        const users = usersSnapshot.val();
        const allTokens = [];

        for (const uid in users) {
            const user = users[uid];
            if (user.fcmTokens && typeof user.fcmTokens === "object") {
                const tokens = Object.values(user.fcmTokens);
                allTokens.push(...tokens);
            }
        }

        if (allTokens.length === 0) {
            return res.status(200).json({ success: false, message: "No tokens found" });
        }

        const response = await admin.messaging().sendEachForMulticast({
            tokens: allTokens,
            notification: {
                title: "SmartSadaqah Test",
                body: "This is a test notification from Cloud Functions",
            },
            data: {
                type: "test",
                timestamp: new Date().toISOString(),
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "donation_channel_v3",
                    priority: "max",
                    defaultSound: true,
                },
            },
        });

        return res.status(200).json({
            success: true,
            totalTokens: allTokens.length,
            successCount: response.successCount,
            failureCount: response.failureCount,
        });
    } catch (error) {
        console.error("Error sending test notification:", error);
        return res.status(500).json({ success: false, error: error.message });
    }
});
