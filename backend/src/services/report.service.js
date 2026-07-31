const { supabase } = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class ReportService {
  static async createReport({ client_id, technician_id, reason, details }) {
    if (!supabase) throw ApiError.internal('Database unavailable');

    const { data, error } = await supabase
      .from('reports')
      .insert([{ client_id, technician_id, reason, details, status: 'pending' }])
      .select()
      .single();

    if (error) {
      console.error('[ReportService.createReport]', error);
      throw ApiError.internal('Failed to create report');
    }
    return data;
  }

  static async getReports(status) {
    if (!supabase) return [];

    let query = supabase
      .from('reports')
      .select(`
        id, reason, details, status, action_taken, created_at,
        client:users!client_id(id, full_name, email),
        technician:users!technician_id(id, full_name, email)
      `)
      .order('created_at', { ascending: false });
      
    if (status) {
      query = query.eq('status', status);
    }

    const { data, error } = await query;
    if (error) {
      console.error('[ReportService.getReports]', error);
      throw ApiError.internal('Failed to fetch reports');
    }
    return data || [];
  }

  static async resolveReport(id, action_taken) {
    if (!supabase) throw ApiError.internal('Database unavailable');

    const { data, error } = await supabase
      .from('reports')
      .update({ status: 'resolved', action_taken, resolved_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[ReportService.resolveReport]', error);
      throw ApiError.internal('Failed to resolve report');
    }
    return data;
  }
}

module.exports = ReportService;
