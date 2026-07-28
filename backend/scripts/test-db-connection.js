const env = require('../src/config/env');
const supabase = require('../src/config/supabase');

async function testConnection() {
  console.log('\n=================================================');
  console.log('📡 TEST DE CONNEXION SUPABASE DATABASE');
  console.log('=================================================\n');

  console.log(`URL Supabase : ${env.supabaseUrl}`);
  console.log(`Clé Service Role : OK\n`);

  if (!supabase) {
    console.error('❌ ÉCHEC : Le client Supabase n\'est pas initialisé.');
    process.exit(1);
  }

  try {
    const { data, error } = await supabase
      .from('categories')
      .select('id, name')
      .limit(5);

    if (error) {
      if (error.code === 'PGRST205' || error.message.includes('Could not find the table')) {
        console.log('✅ CONNEXION AU SERVEUR SUPABASE : RÉUSSIE ! 🎉');
        console.log('⚠️  STATUT DE LA BASE : Les tables ne sont pas encore créées.\n');
        console.log('👉 PROCHAINE ÉTAPE RAPIDE :');
        console.log('1. Ouvrez votre tableau de bord Supabase : https://supabase.com/dashboard/project/ceiyakomwgrzyprgevsq/sql/new');
        console.log('2. Copiez le contenu de "database/schema.sql"');
        console.log('3. Collez-le dans l\'Éditeur SQL (SQL Editor) et cliquez sur "Run"\n');
      } else {
        console.error('❌ ERREUR SUPABASE :', error.message);
        console.error('Code :', error.code);
      }
      process.exit(0);
    }

    console.log(`✅ CONNEXION RÉUSSIE & TABLES DÉJÀ EXÉCUTÉES ! 🎉`);
    console.log(`Catégories trouvées : ${data.length}`);
    data.forEach(c => console.log(` - ${c.name}`));
    console.log('\n=================================================\n');

  } catch (err) {
    console.error('❌ ERREUR :', err.message);
    process.exit(1);
  }
}

testConnection();
