const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnNewOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const newOrder = snap.data();

    // Get all users with role 'employee'
    const usersRef = admin.firestore().collection('users');
    const employeesSnapshot = await usersRef.where('role', '==', 'employee').get();

    const tokens = [];
    employeesSnapshot.forEach(doc => {
      const user = doc.data();
      if (user.fcmToken) {
        tokens.push(user.fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log('No employee FCM tokens found');
      return;
    }

    const payload = {
      notification: {
        title: 'New Order Received',
        body: `A new order has been created: ${newOrder.orderId}`,
      },
      data: {
        orderId: newOrder.orderId,
        customerId: newOrder.customerId,
      },
    };

    // Send notification to all employee tokens
    const response = await admin.messaging().sendToDevice(tokens, payload);
    console.log('Notifications sent:', response);
  });
