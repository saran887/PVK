const XLSX = require('xlsx');
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function importProductsFromExcel() {
  try {
    // Read Excel file
    const workbook = XLSX.readFile('D:\\pkv2\\ANIL FOODS ORDER FORMAT-sri vishnu.xlsx');
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    
    console.log('🔄 Starting product import from Excel...\n');
    console.log(`📊 Sheet: ${sheetName}`);
    console.log(`📋 Total rows: ${data.length}\n`);
    
    // Find header row and data start
    let headerRow = -1;
    let dataStartRow = -1;
    
    for (let i = 0; i < data.length; i++) {
      const row = data[i];
      if (row && row.includes && row.includes('PRODUCTS')) {
        headerRow = i;
        dataStartRow = i + 1;
        console.log(`📍 Found header at row ${i + 1}`);
        break;
      }
    }
    
    if (headerRow === -1) {
      throw new Error('Could not find PRODUCTS header in Excel file');
    }
    
    const headers = data[headerRow];
    console.log(`📋 Headers: ${headers.join(' | ')}\n`);
    
    // Column mapping based on Excel header: S.No | Item Code | PRODUCTS | GST Tax | HSN Code | ORDER QTY | Selling Price | Buying Price
    const snoCol = headers.findIndex(h => h && (h.toLowerCase().includes('s.no') || h.toLowerCase().includes('s no')));
    const itemCodeCol = headers.findIndex(h => h && h.toLowerCase().includes('item') && h.toLowerCase().includes('code'));
    const productNameCol = headers.findIndex(h => h && h.toLowerCase().includes('products'));
    const gstCol = headers.findIndex(h => h && h.toLowerCase().includes('gst') && h.toLowerCase().includes('tax'));
    const hsnCol = headers.findIndex(h => h && h.toLowerCase().includes('hsn') && h.toLowerCase().includes('code'));
    const orderQtyCol = headers.findIndex(h => h && (h.toLowerCase().includes('order') && h.toLowerCase().includes('qty') || h.toLowerCase().includes('stock')));
    const sellingPriceCol = headers.findIndex(h => h && h.toLowerCase().includes('selling') && h.toLowerCase().includes('price'));
    const buyingPriceCol = headers.findIndex(h => h && h.toLowerCase().includes('buying') && h.toLowerCase().includes('price'));
    
    console.log('📊 Column mapping:');
    console.log(`   S.No: ${snoCol}`);
    console.log(`   Item Code: ${itemCodeCol}`);
    console.log(`   Products: ${productNameCol}`);
    console.log(`   GST Tax: ${gstCol}`);
    console.log(`   HSN Code: ${hsnCol}`);
    console.log(`   Order Qty/Stock: ${orderQtyCol}`);
    console.log(`   Selling Price: ${sellingPriceCol} (${headers[sellingPriceCol]})`);
    console.log(`   Buying Price: ${buyingPriceCol} (${headers[buyingPriceCol]})\n`);
    
    const categories = new Map();
    const products = [];
    
    for (let i = dataStartRow; i < data.length; i++) {
      const row = data[i];
      
      // Skip empty rows
      if (!row || !row[productNameCol] || row[productNameCol].toString().trim() === '') continue;
      
      const sno = row[snoCol] ? String(row[snoCol]).trim() : '';
      const itemCode = row[itemCodeCol] ? String(row[itemCodeCol]).trim() : '';
      const productName = String(row[productNameCol]).trim();
      const gstRate = parseFloat(row[gstCol]) || 0;
      const hsnCode = String(row[hsnCol] || '').trim();
      const orderQty = parseFloat(row[orderQtyCol]) || 0;
      const sellingPrice = parseFloat(row[sellingPriceCol]) || 0;
      const buyingPrice = parseFloat(row[buyingPriceCol]) || 0;
      
      // Calculate Selling Price as Buying Price + 10%
      // If buying price is 0, fallback to original selling price or 0
      let calculatedSellingPrice = sellingPrice;
      if (buyingPrice > 0) {
        calculatedSellingPrice = buyingPrice * 1.10;
        // Round to 2 decimal places
        calculatedSellingPrice = Math.round(calculatedSellingPrice * 100) / 100;
      }
      
      // Use Item Code as Product ID if available, otherwise generate from name
      const productId = itemCode || productName
        .replace(/[^a-zA-Z0-9\s]/g, '')
        .replace(/\s+/g, '_')
        .toUpperCase()
        .substring(0, 20);
      
      // Extract category from product name
      let category = 'Food Products';
      
      if (productName.includes('APPALAM')) {
        category = 'Appalam';
      } else if (productName.includes('VERMICELLI')) {
        category = 'Vermicelli';
      } else if (productName.includes('NOODLES')) {
        category = 'Noodles';
      } else if (productName.includes('DOSA MIX') || productName.includes('MIX')) {
        category = 'Mixes';
      } else if (productName.includes('SALT')) {
        category = 'Salt';
      } else if (productName.includes('DHALL') || productName.includes('DHAL')) {
        category = 'Dhall';
      } else if (productName.includes('RAVA') || productName.includes('SOOJI')) {
        category = 'Rava';
      } else if (productName.includes('WHEAT')) {
        category = 'Wheat Products';
      } else if (productName.includes('MAIDA')) {
        category = 'Maida';
      } else if (productName.includes('RICE')) {
        category = 'Rice Products';
      } else if (productName.includes('RAGI')) {
        category = 'Ragi Products';
      } else if (productName.includes('PASTA')) {
        category = 'Pasta';
      } else if (productName.includes('POHA')) {
        category = 'Poha';
      } else if (productName.includes('BAJRA') || productName.includes('BAJRI')) {
        category = 'Bajra Products';
      } else if (productName.includes('SUJI') || productName.includes('SEMOLINA')) {
        category = 'Suji';
      } else if (productName.includes('OIL')) {
        category = 'Oils';
      } else if (productName.includes('FLOUR')) {
        category = 'Flour';
      }
      
      // Extract weight/quantity from product name
      let weight = '';
      let weightUnit = 'kg';
      
      // Look for patterns like "180G", "450G", "1KG", "9KG", etc.
      const weightMatch = productName.match(/(\d+(?:\.\d+)?)\s*(G|KG|ML|L|GM|KGS)/i);
      if (weightMatch) {
        weight = weightMatch[1];
        weightUnit = weightMatch[2].toLowerCase();
        // Normalize units
        if (weightUnit === 'gm' || weightUnit === 'g') weightUnit = 'g';
        if (weightUnit === 'kgs' || weightUnit === 'kg') weightUnit = 'kg';
        if (weightUnit === 'ml') weightUnit = 'ml';
        if (weightUnit === 'l') weightUnit = 'liter';
      }
      
      categories.set(category, true);
      
      const product = {
        sno: sno,
        itemCode: itemCode,
        productId: productId,
        name: productName,
        category: category,
        buyingPrice: buyingPrice,
        sellingPrice: calculatedSellingPrice,
        price: calculatedSellingPrice, // Ensure 'price' field is also updated as it's used in app
        weight: weight,
        weightUnit: weightUnit,
        quantity: orderQty,
        quantityUnit: 'pcs',
        orderQty: orderQty,
        gstRate: gstRate,
        hsnCode: hsnCode,
        description: `${productName} - HSN: ${hsnCode}`,
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      products.push(product);
      console.log(`✅ Parsed: ${productId} - ${productName}`);
      console.log(`   Item Code: ${itemCode} | S.No: ${sno} | Category: ${category}`);
      console.log(`   Selling: ₹${sellingPrice} | Buying: ₹${buyingPrice} | GST: ${gstRate}% | HSN: ${hsnCode}`);
    }
    
    
    console.log(`\n📊 Found ${products.length} products in ${categories.size} categories\n`);
    
    // First, create categories
    console.log('📁 Creating categories...');
    for (const category of categories.keys()) {
      try {
        await db.collection('categories').doc(category).set({
          name: category,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        console.log(`✅ Category: ${category}`);
      } catch (error) {
        console.log(`❌ Category error: ${category} - ${error.message}`);
      }
    }
    
    // Then, add products in batches
    console.log('\n📦 Adding products to database...');
    let successCount = 0;
    let errorCount = 0;
    let batchSize = 10;
    
    for (let i = 0; i < products.length; i += batchSize) {
      const batch = db.batch();
      const currentBatch = products.slice(i, i + batchSize);
      
      for (const product of currentBatch) {
        try {
          const docRef = db.collection('products').doc(product.productId);
          batch.set(docRef, product, { merge: true });
        } catch (error) {
          errorCount++;
          console.error(`❌ Batch error for ${product.productId}: ${error.message}`);
        }
      }
      
      try {
        await batch.commit();
        successCount += currentBatch.length;
        console.log(`✅ Batch ${Math.floor(i/batchSize) + 1}: Added ${currentBatch.length} products`);
        
        // Show progress for each product in batch
        for (const product of currentBatch) {
          console.log(`   📦 ${product.productId}: ${product.name} - ₹${product.sellingPrice}`);
        }
      } catch (error) {
        errorCount += currentBatch.length;
        console.error(`❌ Batch ${Math.floor(i/batchSize) + 1} failed: ${error.message}`);
      }
    }
    
    console.log('\n🎯 Import Complete!');
    console.log('═'.repeat(50));
    console.log(`📊 Summary:`);
    console.log(`   📝 Total products processed: ${products.length}`);
    console.log(`   ✅ Successfully imported: ${successCount}`);
    console.log(`   ❌ Failed imports: ${errorCount}`);
    console.log(`   📁 Categories created: ${categories.size}`);
    console.log(`   💾 Database: Products collection updated`);
    console.log('═'.repeat(50));
    
    if (successCount > 0) {
      console.log('\n🎉 Products are now available in your app!');
      console.log('📱 You can view them in:');
      console.log('   • Admin → Manage Products');
      console.log('   • Sales → Create Order → Product Selection');
    }
    
    process.exit(errorCount === 0 ? 0 : 1);
    
  } catch (error) {
    console.error('❌ Import failed:', error);
    console.error('📋 Stack trace:', error.stack);
    process.exit(1);
  }
}

importProductsFromExcel();
