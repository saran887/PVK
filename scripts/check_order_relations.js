const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkOrderRelations() {
  console.log('Checking Order Relations...');
  
  // Get all users
  const usersSnapshot = await db.collection('users').get();
  const userIds = new Set();
  usersSnapshot.forEach(doc => {
    userIds.add(doc.id);
    console.log(`User: ${doc.id} (${doc.data().name})`);
  });
  
  // Get all shops
  const shopsSnapshot = await db.collection('shops').get();
  const shopIds = new Set();
  shopsSnapshot.forEach(doc => {
    shopIds.add(doc.id);
    console.log(`Shop: ${doc.id} (${doc.data().name})`);
  });
  
  // Get recent orders
  const ordersSnapshot = await db.collection('orders').limit(10).get();
  if (ordersSnapshot.empty) {
    console.log('No orders found.');
    return;
  }
  
  console.log('\nChecking Orders:');
  ordersSnapshot.forEach(doc => {
    const data = doc.data();
    const orderUserId = data.userId;
    const orderShopId = data.shopId;
    
    const userExists = userIds.has(orderUserId);
    const shopExists = shopIds.has(orderShopId);
    
    console.log(`Order ${doc.id}:`);
    console.log(`  - User ID: ${orderUserId} [${userExists ? 'VALID' : 'INVALID'}]`);
    console.log(`  - Shop ID: ${orderShopId} [${shopExists ? 'VALID' : 'INVALID'}]`);
    console.log(`  - Shop Name: ${data.shopName}`);
    console.log(`  - Amount: ${data.totalAmount}`);
  });
}

checkOrderRelations();
