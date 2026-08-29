const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const DispatchService = require('../src/services/dispatch.service');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function syncAllJobOffers() {
  console.log('=== SYNCHRONIZING JOB OFFERS FOR ALL SERVICE REQUESTS ===\n');

  // 1. Get all service requests
  const { data: requests, error } = await supabase
    .from('service_requests')
    .select('id, client_id, assigned_technician_id, category_id, city_id, status, created_at')
    .order('created_at', { ascending: false });

  if (error || !requests) {
    console.error('Error fetching requests:', error);
    return;
  }

  console.log(`Found ${requests.length} service requests in DB.`);

  for (const req of requests) {
    // Check if offers already exist for this request
    const { data: existingOffers } = await supabase
      .from('job_offers')
      .select('id, technician_id, status')
      .eq('service_request_id', req.id);

    if (existingOffers && existingOffers.length > 0) {
      console.log(`Request ${req.id} (${req.status}) already has ${existingOffers.length} offer(s).`);
      continue;
    }

    console.log(`\nSyncing request ${req.id} (status: ${req.status}, assignedTech: ${req.assigned_technician_id})...`);

    // Case A: Request is already assigned or completed
    if (req.assigned_technician_id) {
      const { data: inserted, error: insErr } = await supabase.from('job_offers').insert([{
        service_request_id: req.id,
        technician_id: req.assigned_technician_id,
        status: 'accepted',
        rank: 1,
        responded_at: new Date().toISOString()
      }]).select();

      if (insErr) {
        console.error(`Error inserting accepted offer for ${req.id}:`, insErr);
      } else {
        console.log(`✅ Created 'accepted' job_offer for assigned tech ${req.assigned_technician_id}`);
      }
    } else if (req.status === 'unassigned') {
      // Case B: Request is unassigned - find candidates and create 'sent' offers
      const technicians = await DispatchService.findAvailableTechnicians({
        categoryId: req.category_id,
        cityId: req.city_id,
        limit: 5
      });

      if (technicians.length > 0) {
        const offersToInsert = technicians.map((tech, index) => ({
          service_request_id: req.id,
          technician_id: tech.id,
          status: 'sent',
          rank: index + 1
        }));

        const { data: insertedOffers, error: offersErr } = await supabase
          .from('job_offers')
          .insert(offersToInsert)
          .select('id');

        if (offersErr) {
          console.error(`Error inserting offers for unassigned req ${req.id}:`, offersErr);
        } else {
          console.log(`✅ Created ${insertedOffers?.length || 0} 'sent' job_offers for unassigned req ${req.id}`);
        }
      } else {
        console.log(`No technicians found for unassigned req ${req.id}`);
      }
    }
  }

  // Verify final count in job_offers
  const { data: totalOffers } = await supabase.from('job_offers').select('id, service_request_id, technician_id, status, rank');
  console.log(`\n🎉 SYNCHRONIZATION COMPLETE! Total rows in job_offers table: ${totalOffers?.length || 0}`);
  totalOffers?.forEach((o, i) => {
    console.log(`[${i + 1}] ID: ${o.id} | Request: ${o.service_request_id} | Tech: ${o.technician_id} | Status: ${o.status}`);
  });
}

syncAllJobOffers().catch(console.error);
