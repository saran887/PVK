const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function testConnection() {
  try {
    console.log('🔄 Testing database connection...\n');
    
    // List all collections
    const collections = await db.listCollections();
    console.log('📁 Available collections:');
    collections.forEach(collection => {
      console.log(`   • ${collection.id}`);
    });
    console.log();
    
    // Get products count
    const productsSnapshot = await db.collection('products').get();
    console.log(`📦 Products collection: ${productsSnapshot.size} documents`);
    
    // Show sample product if exists
    if (!productsSnapshot.empty) {
      const sampleProduct = productsSnapshot.docs[0].data();
      console.log('\n🔍 Sample product:');
      console.log(JSON.stringify(sampleProduct, null, 2));
    }
    
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error testing connection:', error);
    process.exit(1);
  }
}

// Run the test
testConnection();