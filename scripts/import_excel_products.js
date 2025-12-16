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
    
    console.log('Starting product import...\n');
    
    // Data starts at row 16 (index 15 is header, 16+ is data)
    // Column mapping:
    // 0: S.No
    // 1: Item Code (Product ID)
    // 2: PRODUCTS (Product Name)
    // 4: GST Tax
    // 5: HSN Code
    // 6: ORDER QTY (not used - customer specific)
    // 7: PRICE (Price+Tax)
    // 8: VALUE (not used - calculated field)
    
    const categories = new Map();
    const products = [];
    
    for (let i = 16; i < data.length; i++) {
      const row = data[i];
      
      // Skip empty rows
      if (!row || !row[1] || !row[2]) continue;
      
      const productCode = String(row[1]).trim();
      const productName = String(row[2]).trim();
      const price = parseFloat(row[7]) || 0;
      const gstRate = parseFloat(row[4]) || 0;
      const hsnCode = String(row[5] || '').trim();
      
      // Extract category from product name
      // Common patterns: "ROASTED VERMICELLI", "JIRA DHALL", etc.
      let category = 'Uncategorized';
      
      // Try to extract category from product name
      if (productName.includes('VERMICELLI')) {
        category = 'Vermicelli';
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
      } else if (productName.includes('NOODLES')) {
        category = 'Noodles';
      } else if (productName.includes('PASTA')) {
        category = 'Pasta';
      } else if (productName.includes('POHA')) {
        category = 'Poha';
      } else if (productName.includes('BAJRA') || productName.includes('BAJRI')) {
        category = 'Bajra Products';
      } else if (productName.includes('SUJI') || productName.includes('SEMOLINA')) {
        category = 'Suji';
      }
      
      // Extract weight/quantity from product name
      let weight = '';
      let weightUnit = '';
      
      // Look for patterns like "180G", "450G", "1KG", "9KG", etc.
      const weightMatch = productName.match(/(\d+(?:\.\d+)?)\s*(G|KG|ML|L|GM|KGS)/i);
      if (weightMatch) {
        weight = weightMatch[1];
        weightUnit = weightMatch[2].toUpperCase();
        // Normalize units
        if (weightUnit === 'GM') weightUnit = 'G';
        if (weightUnit === 'KGS') weightUnit = 'KG';
      }
      
      categories.set(category, true);
      
      const product = {
        productId: productCode,
        name: productName,
        category: category,
        price: price,
        weight: weight,
        weightUnit: weightUnit,
        quantity: '',  // Not in Excel
        quantityUnit: '',  // Not in Excel
        gstRate: gstRate,
        hsnCode: hsnCode,
        imageUrl: '',  // Not in Excel
        location: '',  // Not in Excel
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      products.push(product);
      console.log(`✓ Parsed: ${productCode} - ${productName} (${category})`);
    }
    
    console.log(`\n Found ${products.length} products in ${categories.size} categories\n`);
    
    // First, create categories
    console.log('Creating categories...');
    for (const category of categories.keys()) {
      await db.collection('categories').doc(category).set({
        name: category,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.log(`✓ Category: ${category}`);
    }
    
    // Then, add products
    console.log('\nAdding products to Firestore...');
    let successCount = 0;
    let errorCount = 0;
    
    for (const product of products) {
      try {
        // Use productId as document ID
        await db.collection('products').doc(product.productId).set(product, { merge: true });
        successCount++;
        console.log(`✓ ${product.productId}: ${product.name}`);
      } catch (error) {
        errorCount++;
        console.error(`✗ Failed to add ${product.productId}: ${error.message}`);
      }
    }
    
    console.log(`\n=== Import Complete ===`);
    console.log(`Total products: ${products.length}`);
    console.log(`Success: ${successCount}`);
    console.log(`Errors: ${errorCount}`);
    console.log(`Categories: ${categories.size}`);
    
    process.exit(0);
    
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

importProductsFromExcel();
