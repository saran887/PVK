const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkProducts() {
  // Check specific ID from Row 16
  const doc = await db.collection('products').doc('30000441').get();
  if (!doc.exists) {
    console.log('Product 30000441 not found.');
  } else {
    const data = doc.data();
    console.log(`ID: ${doc.id}`);
    console.log(`Name: ${data.name}`);
    console.log(`Buying Price: ${data.buyingPrice}`);
    console.log(`Selling Price: ${data.sellingPrice}`);
    console.log(`Price: ${data.price}`);
  }
}

checkProducts();
