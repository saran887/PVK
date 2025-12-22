const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateProductPrices() {
  try {
    console.log('Starting price update...');
    const productsRef = db.collection('products');
    const snapshot = await productsRef.get();

    if (snapshot.empty) {
      console.log('No products found.');
      return;
    }

    let updatedCount = 0;
    let skippedCount = 0;
    const batchSize = 500;
    let batch = db.batch();
    let operationCounter = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const buyingPrice = parseFloat(data.buyingPrice);

      if (!isNaN(buyingPrice) && buyingPrice > 0) {
        // Formula: Selling Price = Buying Price + (10% of Buying Price)
        // This matches the user's second request "like selling price = 0.10 * buying price" (interpreted as profit)
        // If you wanted "Selling = Buying + 10% of Selling", use: buyingPrice / 0.90
        
        const newSellingPrice = buyingPrice + (0.10 * buyingPrice);
        
        // Round to 2 decimal places
        const roundedPrice = Math.round(newSellingPrice * 100) / 100;

        const ref = productsRef.doc(doc.id);
        batch.update(ref, { 
          price: roundedPrice,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        updatedCount++;
        operationCounter++;
        console.log(`Product ${doc.id}: Buying=${buyingPrice} -> New Selling=${roundedPrice}`);
      } else {
        console.log(`Skipping product ${doc.id}: Invalid buyingPrice (${data.buyingPrice})`);
        skippedCount++;
      }

      if (operationCounter >= batchSize) {
        await batch.commit();
        batch = db.batch();
        operationCounter = 0;
        console.log('Committed batch...');
      }
    }

    if (operationCounter > 0) {
      await batch.commit();
    }

    console.log('-----------------------------------');
    console.log(`Update Complete.`);
    console.log(`Updated: ${updatedCount}`);
    console.log(`Skipped: ${skippedCount}`);
    console.log('-----------------------------------');

  } catch (error) {
    console.error('Error updating prices:', error);
  }
}

updateProductPrices();
