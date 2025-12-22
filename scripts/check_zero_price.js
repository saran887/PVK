const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkProducts() {
  const snapshot = await db.collection('products').where('buyingPrice', '==', 0).get();
  console.log(`Found ${snapshot.size} products with Buying Price 0`);
  
  if (!snapshot.empty) {
    snapshot.docs.slice(0, 5).forEach(doc => {
      const data = doc.data();
      console.log(`ID: ${doc.id}, Name: ${data.name}, Buying: ${data.buyingPrice}, Selling: ${data.sellingPrice}`);
    });
  }
  
  // Also check a few normal ones to be sure
  const normalSnapshot = await db.collection('products').where('buyingPrice', '>', 0).limit(3).get();
  console.log('\nNormal products:');
  normalSnapshot.forEach(doc => {
    const data = doc.data();
    console.log(`ID: ${doc.id}, Name: ${data.name}, Buying: ${data.buyingPrice}, Selling: ${data.sellingPrice}`);
  });
}

checkProducts();
