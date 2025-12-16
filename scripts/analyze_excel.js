const XLSX = require('xlsx');

async function importProductsFromExcel() {
  try {
    // Read Excel file
    const workbook = XLSX.readFile('D:\\pkv2\\ANIL FOODS ORDER FORMAT-sri vishnu.xlsx');
    
    // Get first sheet
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    
    // Convert to JSON
    const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    
    console.log('=== Excel File Structure ===');
    console.log('Sheet Name:', sheetName);
    console.log('Total Rows:', data.length);
    console.log('\n=== Headers (First Row) ===');
    console.log(data[0]);
    
    console.log('\n=== Sample Data (First 20 Rows) ===');
    for (let i = 0; i < Math.min(20, data.length); i++) {
      console.log(`Row ${i}:`, data[i]);
    }
    
    console.log('\n\nPlease review the structure above and update the script with:');
    console.log('- Which column has Product ID?');
    console.log('- Which column has Product Name?');
    console.log('- Which column has Category?');
    console.log('- Which column has Price?');
    console.log('- Which column has Weight/Quantity?');
    console.log('- Which column has Units?');
    
  } catch (error) {
    console.error('Error:', error);
  }
}

importProductsFromExcel();
