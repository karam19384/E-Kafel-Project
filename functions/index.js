const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// دالة لإرسال الإشعارات الجماعية
exports.sendBulkNotifications = functions.https.onCall(async (data, context) => {
  // التحقق من المصادقة
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const {messageText, recipientType, recipientIds} = data;

  try {
    // جلب أجهزة المستلمين
    const tokensSnapshot = await admin.firestore()
        .collection("users")
        .where("id", "in", recipientIds)
        .where("fcmToken", "!=", null)
        .get();

    const tokens = tokensSnapshot.docs
        .map((doc) => doc.data().fcmToken)
        .filter((token) => token !== null);

    if (tokens.length === 0) {
      return {success: false, message: "لا توجد أجهزة مسجلة"};
    }

    // إرسال الإشعارات
    const message = {
      notification: {
        title: "رسالة جديدة",
        body: messageText,
      },
      data: {
        type: "sms",
        recipientType: recipientType,
        senderId: context.auth.uid,
        timestamp: new Date().toISOString(),
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);

    // حفظ سجل الإرسال
    await admin.firestore().collection("message_logs").add({
      senderId: context.auth.uid,
      messageText: messageText,
      recipientType: recipientType,
      recipientCount: tokens.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      sentCount: response.successCount,
      failedCount: response.failureCount,
    };
  } catch (error) {
    console.error("Error sending notifications:", error);
    throw new functions.https.HttpsError("internal", "فشل في إرسال الرسائل");
  }
});

// دالة لمعالجة الرسائل المجدولة
exports.processScheduledMessages = functions.pubsub
    .schedule("every 5 minutes")
    .onRun(async (context) => {
      try {
        const now = new Date();

        // البحث عن الرسائل المجدولة وجاهزة للإرسال
        const scheduledMessages = await admin.firestore()
            .collection("messages")
            .where("scheduledTime", "<=", now)
            .where("isSent", "==", false)
            .get();

        const promises = scheduledMessages.docs.map(async (doc) => {
          const message = doc.data();

          // إرسال الرسالة
          const tokensSnapshot = await admin.firestore()
              .collection("users")
              .where("id", "in", message.recipientIds)
              .where("fcmToken", "!=", null)
              .get();

          const tokens = tokensSnapshot.docs
              .map((userDoc) => userDoc.data().fcmToken)
              .filter((token) => token !== null);

          if (tokens.length > 0) {
            const notificationMessage = {
              notification: {
                title: "رسالة مجدولة",
                body: message.messageText,
              },
              data: {
                type: "scheduled_sms",
                messageId: doc.id,
                timestamp: now.toISOString(),
              },
              tokens: tokens,
            };

            await admin.messaging().sendMulticast(notificationMessage);
          }

          // تحديث حالة الرسالة
          return doc.ref.update({
            isSent: true,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            processed: true,
          });
        });

        await Promise.all(promises);
        console.log(`تم معالجة ${scheduledMessages.size} رسالة مجدولة`);

        return null;
      } catch (error) {
        console.error("Error processing scheduled messages:", error);
        return null;
      }
    });

// دالة مساعدة للحصول على إحصائيات الرسائل
exports.getSMSStats = functions.https.onCall(async (data, context) => {
  try {
    const statsDoc = await admin.firestore()
        .collection("sms_stats")
        .doc("current")
        .get();

    const messagesCount = await admin.firestore()
        .collection("messages")
        .count()
        .get();

    return {
      success: true,
      stats: statsDoc.exists ? statsDoc.data() : {
        totalMessages: 0,
        sentMessages: 0,
        failedMessages: 0,
      },
      totalMessagesCount: messagesCount.data().count,
    };
  } catch (error) {
    console.error("Error getting SMS stats:", error);
    throw new functions.https.HttpsError("internal", "فشل في جلب الإحصائيات");
  }
});