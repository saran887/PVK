const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkProduct() {
  try {
    // Check a known product ID from the logs
    const productId = '30000441'; 
    const doc = await db.collection('products').doc(productId).get();
    
    if (doc.exists) {
      console.log('Product Data:', doc.data());
    } else {
      console.log('Product not found');
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

checkProduct();
