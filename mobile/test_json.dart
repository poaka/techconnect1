// ignore_for_file: avoid_print
import 'dart:convert';
import 'lib/features/technicians/domain/technician_profile.dart';

void main() {
  const jsonStr = '''
  {
    "id": "40000000-0000-0000-0000-000000000001",
    "bio": "Électricien qualifié avec 8 ans d'expérience à Yaoundé. Spécialiste dépannage rapide et câblage moderne.",
    "years_experience": 8,
    "price_min": 5000,
    "price_max": 25000,
    "whatsapp": "+237692222222",
    "verified": true,
    "availability": "available",
    "rating_avg": 0,
    "rating_count": 0,
    "created_at": "2026-07-27T11:22:19.991628+00:00",
    "categories": [
      {
        "category": {
          "id": "20000000-0000-0000-0000-000000000001",
          "icon": "bolt",
          "name": "Électricien"
        }
      }
    ],
    "user": {
      "id": "30000000-0000-0000-0000-000000000003",
      "email": "samuel@fixerpro237.cm",
      "phone": "+237692222222",
      "full_name": "Samuel Électricien",
      "avatar_url": null
    },
    "city": {
      "id": "10000000-0000-0000-0000-000000000001",
      "name": "Yaoundé",
      "region": {
        "id": "00000000-0000-0000-0000-000000000001",
        "name": "Centre"
      }
    }
  }
  ''';
  try {
    final map = jsonDecode(jsonStr);
    final profile = TechnicianProfile.fromJson(map);
    print('SUCCESS: ${profile.fullName}, ${profile.categories.length} categories');
  } catch (e, st) {
    print('ERROR: \$e');
    print(st);
  }
}
