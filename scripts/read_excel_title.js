const XLSX = require('xlsx');

async function readExcelTitle() {
  try {
    console.log('📄 Reading Excel file title...\n');
    
    // Read Excel file
    const workbook = XLSX.readFile('D:\\pkv2\\ANIL FOODS ORDER FORMAT-sri vishnu.xlsx');
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    
    console.log(`📊 Sheet Name: ${sheetName}\n`);
    
    // Read first several rows to find title information
    console.log('📋 Excel Content (First 20 rows):\n');
    
    for (let i = 0; i < Math.min(20, data.length); i++) {
      const row = data[i];
      if (row && row.length > 0) {
        // Filter out empty cells
        const nonEmptyContent = row.filter(cell => cell !== undefined && cell !== null && cell !== '');
        
        if (nonEmptyContent.length > 0) {
          console.log(`Row ${i + 1}: ${nonEmptyContent.join(' | ')}`);
          
          // Look for title-like content (usually in first few rows)
          if (i < 10) {
            const rowText = nonEmptyContent.join(' ');
            if (rowText.length > 10 && (
                rowText.includes('ANIL') || 
                rowText.includes('FOODS') || 
                rowText.includes('ORDER') || 
                rowText.includes('FORMAT') ||
                rowText.toLowerCase().includes('company') ||
                rowText.toLowerCase().includes('title')
              )) {
              console.log(`\n🎯 Potential Title Found at Row ${i + 1}: "${rowText}"\n`);
            }
          }
        }
      }
    }
    
    // Look for merged cells or special formatting that might indicate title
    console.log('\n🔍 Analysis:');
    console.log(`   📁 File: ANIL FOODS ORDER FORMAT-sri vishnu.xlsx`);
    console.log(`   📄 Sheet: ${sheetName}`);
    console.log(`   📊 Total rows: ${data.length}`);
    
    // Try to identify the main title
    let title = '';
    for (let i = 0; i < Math.min(15, data.length); i++) {
      const row = data[i];
      if (row && row.length > 0) {
        const rowText = row.filter(cell => cell !== undefined && cell !== null && cell !== '').join(' ');
        if (rowText.includes('ANIL FOODS') || (rowText.includes('ANIL') && rowText.includes('FOODS'))) {
          title = rowText.trim();
          break;
        }
      }
    }
    
    if (title) {
      console.log(`\n📌 Excel Title: "${title}"`);
    } else {
      console.log(`\n📌 File Name as Title: "ANIL FOODS ORDER FORMAT-sri vishnu"`);
    }
    
  } catch (error) {
    console.error('❌ Error reading Excel file:', error);
  }
}

readExcelTitle();