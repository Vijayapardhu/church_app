const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onDailyMessageUpload = functions.firestore
    .document("daily_messages/{messageId}")
    .onCreate(async (snap, context) => {
      const messageData = snap.data();
      const usersSnapshot = await admin.firestore()
          .collection("users")
          .get();
      const tokens = [];
      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });
      if (tokens.length === 0) {
        console.log("No tokens found");
        return null;
      }
      const notification = {
        title: "New Daily Message",
        body: messageData.title || "A new message has been posted",
      };
      const message = {
        notification,
        tokens,
        data: {
          messageId: context.params.messageId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };
      try {
        const response = await admin.messaging().sendMulticast(message);
        console.log("Successfully sent message:", response);
        return response;
      } catch (error) {
        console.log("Error sending message:", error);
        return null;
      }
    });
