const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function deleteAllProducts() {
  try {
    console.log('🔄 Starting deletion of all products from database...\n');
    
    // Get all products
    const productsSnapshot = await db.collection('products').get();
    
    if (productsSnapshot.empty) {
      console.log('📦 No products found in database - nothing to delete.');
      process.exit(0);
    }
    
    console.log(`📦 Found ${productsSnapshot.size} products to delete\n`);
    
    // Delete products in batches for better performance
    const batchSize = 100;
    let deletedCount = 0;
    
    for (let i = 0; i < productsSnapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const currentBatch = productsSnapshot.docs.slice(i, i + batchSize);
      
      currentBatch.forEach(doc => {
        batch.delete(doc.ref);
        const data = doc.data();
        console.log(`❌ Queued for deletion: ${data.name || 'Unknown Product'} (${doc.id})`);
      });
      
      // Execute the batch deletion
      await batch.commit();
      deletedCount += currentBatch.length;
      console.log(`✅ Batch ${Math.floor(i/batchSize) + 1}: Deleted ${currentBatch.length} products\n`);
    }
    
    console.log('🎯 Product Deletion Complete!');
    console.log('═'.repeat(50));
    console.log(`📊 Summary:`);
    console.log(`   📝 Total products found: ${productsSnapshot.size}`);
    console.log(`   ❌ Products deleted: ${deletedCount}`);
    console.log(`   📂 Products collection: Now empty`);
    console.log('═'.repeat(50));
    
    console.log('\n✅ All products have been successfully deleted from the database!');
    console.log('📱 The products collection is now empty and ready for fresh data.');
    
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error deleting products:', error);
    console.error('📋 Stack trace:', error.stack);
    process.exit(1);
  }
}

// Run the deletion
deleteAllProducts();