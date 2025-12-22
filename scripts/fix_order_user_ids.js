const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixOrderUserIds() {
  const salesUserId = '3lSMmUcrVTd0XR4etpwJjRHYmBv2'; // Saran
  
  console.log(`Fixing orders with missing userId. Defaulting to: ${salesUserId}`);
  
  const ordersSnapshot = await db.collection('orders').get();
  let updatedCount = 0;
  
  const batch = db.batch();
  let operationCounter = 0;
  
  ordersSnapshot.forEach(doc => {
    const data = doc.data();
    if (!data.userId) {
      const ref = db.collection('orders').doc(doc.id);
      batch.update(ref, { userId: salesUserId });
      updatedCount++;
      operationCounter++;
    }
  });
  
  if (updatedCount > 0) {
    await batch.commit();
    console.log(`✅ Updated ${updatedCount} orders with missing userId.`);
  } else {
    console.log('No orders found with missing userId.');
  }
}

fixOrderUserIds();
