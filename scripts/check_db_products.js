const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkProducts() {
  const snapshot = await db.collection('products').limit(5).get();
  if (snapshot.empty) {
    console.log('No products found.');
    return;
  }

  snapshot.forEach(doc => {
    const data = doc.data();
    console.log(`ID: ${doc.id}`);
    console.log(`Name: ${data.name}`);
    console.log(`Buying Price: ${data.buyingPrice}`);
    console.log(`Selling Price: ${data.sellingPrice}`);
    console.log(`Price: ${data.price}`);
    console.log('---');
  });
}

checkProducts();
