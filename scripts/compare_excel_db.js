const XLSX = require('xlsx');
const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function compareExcelAndDb() {
  // Read Excel
  const workbook = XLSX.readFile('D:\\pkv2\\ANIL FOODS ORDER FORMAT-sri vishnu.xlsx');
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 });

  let headerRow = -1;
  for (let i = 0; i < data.length; i++) {
    if (data[i] && data[i].includes && data[i].includes('PRODUCTS')) {
      headerRow = i;
      break;
    }
  }

  const headers = data[headerRow];
  const itemCodeCol = headers.findIndex(h => h && h.toLowerCase().includes('item') && h.toLowerCase().includes('code'));
  const buyingPriceCol = headers.findIndex(h => h && h.toLowerCase().includes('buying') && h.toLowerCase().includes('price'));
  const sellingPriceCol = headers.findIndex(h => h && h.toLowerCase().includes('selling') && h.toLowerCase().includes('price'));

  console.log('Comparing first 5 products...');
  console.log('Format: [Item Code] Excel Buying / Excel Selling  VS  DB Buying / DB Selling');

  for (let i = headerRow + 1; i < headerRow + 6; i++) {
    const row = data[i];
    if (!row) continue;
    
    const itemCode = String(row[itemCodeCol]).trim();
    const excelBuying = row[buyingPriceCol];
    const excelSelling = row[sellingPriceCol];

    // Fetch from DB
    // Note: My import script uses itemCode as ID if available, or generates it.
    // Let's try to find by itemCode field first
    const snapshot = await db.collection('products').where('itemCode', '==', itemCode).get();
    
    if (snapshot.empty) {
      console.log(`[${itemCode}] Not found in DB`);
    } else {
      const doc = snapshot.docs[0];
      const dbData = doc.data();
      console.log(`[${itemCode}] Excel: ${excelBuying} / ${excelSelling}  VS  DB: ${dbData.buyingPrice} / ${dbData.sellingPrice}`);
    }
  }
}

compareExcelAndDb();
