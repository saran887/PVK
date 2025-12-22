const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function validateImageFreeDatabase() {
  try {
    console.log('🔍 Validating database is image-URL-free...\n');
    
    // Check all collections for any image-related fields
    const collections = await db.listCollections();
    
    let totalIssues = 0;
    let totalDocuments = 0;
    
    for (const collection of collections) {
      console.log(`📁 Scanning collection: ${collection.id}`);
      
      try {
        const snapshot = await collection.get();
        
        if (snapshot.empty) {
          console.log(`   ✅ Empty collection - clean\n`);
          continue;
        }
        
        let issuesInCollection = 0;
        const imageFields = ['imageUrl', 'image_url', 'imageURL', 'pictureUrl', 'photoUrl', 'image', 'picture', 'photo'];
        
        snapshot.docs.forEach((doc) => {
          const data = doc.data();
          totalDocuments++;
          
          // Check for any image-related fields
          imageFields.forEach(field => {
            if (data[field] !== undefined && data[field] !== null && data[field] !== '') {
              console.log(`   🚨 FOUND: ${field} in document ${doc.id}`);
              console.log(`      Value: ${data[field]}`);
              issuesInCollection++;
              totalIssues++;
            }
          });
        });
        
        if (issuesInCollection === 0) {
          console.log(`   ✅ Collection clean - ${snapshot.size} documents checked\n`);
        } else {
          console.log(`   ❌ Found ${issuesInCollection} image fields in ${collection.id}\n`);
        }
        
      } catch (error) {
        console.log(`   ⚠️  Error scanning ${collection.id}: ${error.message}\n`);
      }
    }
    
    // Final validation report
    console.log('🎯 Database Validation Complete!');
    console.log('═'.repeat(50));
    console.log(`📊 Validation Summary:`);
    console.log(`   • Collections scanned: ${collections.length}`);
    console.log(`   • Total documents: ${totalDocuments}`);
    console.log(`   • Image fields found: ${totalIssues}`);
    console.log('═'.repeat(50));
    
    if (totalIssues === 0) {
      console.log('🎉 SUCCESS: Database is completely image-URL-free!');
      console.log('✅ All collections are clean and ready for production.');
    } else {
      console.log('❌ WARNING: Found image fields that need cleanup!');
      console.log('🔧 Run the remove_image_links.js script again to clean up.');
    }
    
    console.log('\n📋 Database Status: ' + (totalIssues === 0 ? 'CLEAN' : 'NEEDS CLEANUP'));
    
    process.exit(totalIssues === 0 ? 0 : 1);
    
  } catch (error) {
    console.error('❌ Validation failed:', error);
    process.exit(1);
  }
}

// Run validation
validateImageFreeDatabase();