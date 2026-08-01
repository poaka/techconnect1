const supabase = require('../src/config/supabase');

async function cleanTestDoc() {
  try {
    await supabase.from('technician_documents').delete().eq('id', '55154f75-2e5e-4a52-8c55-a61bd73dabdb');
    console.log('Cleaned test doc.');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

cleanTestDoc();
