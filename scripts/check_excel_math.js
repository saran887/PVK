const XLSX = require('xlsx');

function checkExcelMath() {
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

  if (headerRow === -1) {
    console.log('Header not found');
    return;
  }

  const headers = data[headerRow];
  const buyingPriceCol = headers.findIndex(h => h && h.toLowerCase().includes('buying') && h.toLowerCase().includes('price'));
  const sellingPriceCol = headers.findIndex(h => h && h.toLowerCase().includes('selling') && h.toLowerCase().includes('price'));

  console.log(`Buying Col: ${buyingPriceCol}, Selling Col: ${sellingPriceCol}`);

  let mismatchCount = 0;
  for (let i = headerRow + 1; i < data.length; i++) {
    const row = data[i];
    if (!row || !row[buyingPriceCol]) continue;

    const buying = parseFloat(row[buyingPriceCol]);
    const selling = parseFloat(row[sellingPriceCol]);
    
    if (isNaN(buying) || isNaN(selling)) continue;

    const calculated = buying * 1.10;
    // Allow small floating point difference
    if (Math.abs(selling - calculated) > 0.1) {
      console.log(`Row ${i+1}: Buying ${buying}, Excel Selling ${selling}, Calc ${calculated}`);
      mismatchCount++;
    }
  }
  
  if (mismatchCount === 0) {
    console.log('All rows match Buying * 1.10 logic');
  } else {
    console.log(`Found ${mismatchCount} mismatches`);
  }
}

checkExcelMath();
