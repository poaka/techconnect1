const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class NotificationsService {
  static async getNotifications(userId) {
    if (!supabase) return { notifications: [], unreadCount: 0 };

    const { data: notifications, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[NotificationsService.getNotifications error]', error);
      throw ApiError.internal('Erreur lors de la récupération des notifications');
    }

    const unreadCount = notifications ? notifications.filter(n => !n.is_read).length : 0;

    return {
      notifications: notifications || [],
      unreadCount
    };
  }

  static async markAsRead(userId, notificationId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const { data, error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', notificationId)
      .eq('user_id', userId)
      .select()
      .single();

    if (error || !data) {
      throw ApiError.notFound('Notification non trouvée');
    }

    return data;
  }

  static async markAllAsRead(userId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) {
      console.error('[NotificationsService.markAllAsRead error]', error);
      throw ApiError.internal('Erreur lors de la mise à jour des notifications');
    }

    return { message: 'Toutes les notifications ont été marquées comme lues' };
  }
}

module.exports = NotificationsService;
