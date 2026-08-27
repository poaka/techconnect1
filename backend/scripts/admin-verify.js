#!/usr/bin/env node

/**
 * FixerPro237 Cameroun — Admin Verification CLI Utility
 * Stand-in script allowing platform administrator to review & approve technician identity documents
 */

const readline = require('readline');
const AdminService = require('../src/services/admin.service');
const supabase = require('../src/config/supabase');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

async function main() {
  console.log('\n=== FixerPro237 Cameroun — Outil de Vérification Admin ===\n');

  if (!supabase) {
    console.error('Erreur: Supabase non configuré. Veuillez vérifier le fichier .env');
    process.exit(1);
  }

  try {
    const documents = await AdminService.getPendingVerifications();

    if (documents.length === 0) {
      console.log('Aucun document de vérification en attente.');
      rl.close();
      return;
    }

    console.log(`Trouvé ${documents.length} document(s) :\n`);
    documents.forEach((doc, index) => {
      const techName = doc.technician?.user?.full_name || 'N/A';
      const techEmail = doc.technician?.user?.email || 'N/A';
      console.log(`[${index + 1}] ID: ${doc.id}`);
      console.log(`    Technicien : ${techName} (${techEmail})`);
      console.log(`    Type       : ${doc.document_type}`);
      console.log(`    URL        : ${doc.file_url}`);
      console.log(`    Statut     : ${doc.status}`);
      console.log(`    Soumis le  : ${doc.uploaded_at}\n`);
    });

    const choice = await question('Entrez le numéro du document à traiter (ou Q pour quitter) : ');
    if (choice.toUpperCase() === 'Q') {
      rl.close();
      return;
    }

    const docIndex = parseInt(choice, 10) - 1;
    if (isNaN(docIndex) || docIndex < 0 || docIndex >= documents.length) {
      console.log('Sélection invalide.');
      rl.close();
      return;
    }

    const selectedDoc = documents[docIndex];
    console.log(`\nTraitement du document [${selectedDoc.id}] pour ${selectedDoc.technician?.user?.full_name}`);
    const decision = await question('Décision (A = Approuver, R = Rejeter) : ');

    if (decision.toUpperCase() === 'A') {
      await AdminService.reviewDocument(selectedDoc.id, 'approved');
      console.log(`\n✅ Document ${selectedDoc.id} APPROUVÉ avec succès ! Profil technicien mis à jour.`);
    } else if (decision.toUpperCase() === 'R') {
      const reason = await question('Motif du rejet : ');
      await AdminService.reviewDocument(selectedDoc.id, 'rejected', reason);
      console.log(`\n❌ Document ${selectedDoc.id} REJETÉ.`);
    } else {
      console.log('Action annulée.');
    }

  } catch (error) {
    console.error('\nErreur lors du traitement :', error.message);
  } finally {
    rl.close();
  }
}

main();
