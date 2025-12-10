const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Try to load service account key
const serviceAccountPath = path.join(__dirname, 'service-account-key.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Error: service-account-key.json not found!');
  console.error('');
  console.error('Please follow these steps:');
  console.error('1. Go to Firebase Console → Project Settings → Service Accounts');
  console.error('2. Click "Generate New Private Key"');
  console.error('3. Save the file as "service-account-key.json" in the scripts folder');
  console.error('4. Make sure the file is in: ' + serviceAccountPath);
  process.exit(1);
}

const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupDatabase() {
  try {
    console.log('🗑️  Starting database cleanup...');

    // Delete all products
    const productsSnapshot = await db.collection('products').get();
    const productBatch = db.batch();
    productsSnapshot.docs.forEach((doc) => {
      productBatch.delete(doc.ref);
    });
    await productBatch.commit();
    console.log(`✅ Deleted ${productsSnapshot.size} products`);

    // Delete all locations
    const locationsSnapshot = await db.collection('locations').get();
    const locationBatch = db.batch();
    locationsSnapshot.docs.forEach((doc) => {
      locationBatch.delete(doc.ref);
    });
    await locationBatch.commit();
    console.log(`✅ Deleted ${locationsSnapshot.size} locations`);

    // Delete all shops
    const shopsSnapshot = await db.collection('shops').get();
    const shopBatch = db.batch();
    shopsSnapshot.docs.forEach((doc) => {
      shopBatch.delete(doc.ref);
    });
    await shopBatch.commit();
    console.log(`✅ Deleted ${shopsSnapshot.size} shops`);

    console.log('✨ Database cleanup completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error cleaning up database:', error);
    process.exit(1);
  }
}

cleanupDatabase();
