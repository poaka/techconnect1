const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');
const env = require('../config/env');
const { ApiError } = require('../middleware/errorHandler');
const { isValidEmail, isValidPhoneNumber, sanitizeEmail, sanitizePhone } = require('../utils/validators');

// In-memory fallback store for local development/testing without live Supabase
const mockUsers = new Map([
  ['admin@techconnect.cm', {
    id: '30000000-0000-0000-0000-000000000001',
    full_name: 'Admin TechConnect',
    email: 'admin@techconnect.cm',
    phone: '+237690000000',
    password_hash: bcrypt.hashSync('Password123!', 10),
    role: 'admin',
    avatar_url: null,
    created_at: new Date().toISOString()
  }],
  ['client@techconnect.cm', {
    id: '30000000-0000-0000-0000-000000000002',
    full_name: 'Jean Client',
    email: 'client@techconnect.cm',
    phone: '+237691111111',
    password_hash: bcrypt.hashSync('Password123!', 10),
    role: 'client',
    avatar_url: null,
    created_at: new Date().toISOString()
  }],
  ['samuel@techconnect.cm', {
    id: '30000000-0000-0000-0000-000000000003',
    full_name: 'Samuel Électricien',
    email: 'samuel@techconnect.cm',
    phone: '+237692222222',
    password_hash: bcrypt.hashSync('Password123!', 10),
    role: 'technician',
    avatar_url: null,
    created_at: new Date().toISOString()
  }]
]);

class AuthService {
  static generateToken(user) {
    return jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
        fullName: user.full_name
      },
      env.jwtSecret,
      { expiresIn: env.jwtExpiresIn }
    );
  }

  static async register({ fullName, email, phone, password, role = 'client' }) {
    if (!['client', 'technician'].includes(role)) {
      throw ApiError.badRequest('Rôle d\'utilisateur non valide');
    }

    const cleanEmail = sanitizeEmail(email);
    if (!cleanEmail || !isValidEmail(cleanEmail)) {
      throw ApiError.badRequest('Adresse email invalide (ex: nom@domaine.com)');
    }

    const cleanPhone = sanitizePhone(phone);
    if (cleanPhone && !isValidPhoneNumber(cleanPhone)) {
      throw ApiError.badRequest('Format de numéro de téléphone invalide (ex: +237690000000)');
    }

    console.log('[AuthService.register] Starting registration for:', cleanEmail, 'role:', role);

    if (supabase) {
      console.log('[AuthService.register] Using Supabase — checking existing user email...');
      const { data: existingEmailUser, error: lookupError } = await supabase
        .from('users')
        .select('id')
        .eq('email', cleanEmail)
        .maybeSingle();

      if (lookupError) {
        console.error('[AuthService.register] Email lookup error:', lookupError);
        throw ApiError.internal('Erreur lors de la vérification de l\'email');
      }

      if (existingEmailUser) {
        console.log('[AuthService.register] User email already exists:', existingEmailUser.id);
        throw ApiError.conflict('Un utilisateur avec cet email existe déjà');
      }

      if (cleanPhone) {
        console.log('[AuthService.register] Checking existing phone number in Supabase...');
        const { data: existingPhoneUser, error: phoneLookupError } = await supabase
          .from('users')
          .select('id')
          .eq('phone', cleanPhone)
          .maybeSingle();

        if (phoneLookupError) {
          console.error('[AuthService.register] Phone lookup error:', phoneLookupError);
        } else if (existingPhoneUser) {
          console.log('[AuthService.register] Phone number already registered:', existingPhoneUser.id);
          throw ApiError.conflict('Un utilisateur avec ce numéro de téléphone existe déjà');
        }
      }

      console.log('[AuthService.register] No existing user found. Hashing password...');
      const passwordHash = await bcrypt.hash(password, 10);

      console.log('[AuthService.register] Inserting new user into Supabase...');
      const { data: newUser, error } = await supabase
        .from('users')
        .insert([
          {
            full_name: fullName,
            email: cleanEmail,
            phone: cleanPhone || null,
            password_hash: passwordHash,
            role: role
          }
        ])
        .select('id, full_name, email, phone, role, avatar_url, created_at')
        .single();

      if (error) {
        console.error('[AuthService.register] Insert error:', error);
        throw ApiError.internal('Erreur lors de la création de l\'utilisateur');
      }

      console.log('[AuthService.register] User created successfully:', newUser.id);
      const token = this.generateToken(newUser);
      return { user: newUser, token };
    }

    // Local fallback
    if (mockUsers.has(cleanEmail)) {
      throw ApiError.conflict('Un utilisateur avec cet email existe déjà');
    }

    if (cleanPhone) {
      for (const u of mockUsers.values()) {
        if (u.phone === cleanPhone) {
          throw ApiError.conflict('Un utilisateur avec ce numéro de téléphone existe déjà');
        }
      }
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const newUser = {
      id: `user-${Date.now()}`,
      full_name: fullName,
      email: cleanEmail,
      phone: cleanPhone || null,
      password_hash: passwordHash,
      role: role,
      avatar_url: null,
      created_at: new Date().toISOString()
    };

    mockUsers.set(cleanEmail, newUser);

    const userToReturn = { ...newUser };
    delete userToReturn.password_hash;
    const token = this.generateToken(userToReturn);

    return { user: userToReturn, token };
  }

  static async login({ email, password }) {
    const emailLower = email.toLowerCase();
    console.log('[AuthService.login] Attempting login for:', emailLower);

    if (supabase) {
      let { data: user, error } = await supabase
        .from('users')
        .select('id, full_name, email, phone, password_hash, role, avatar_url, created_at')
        .eq('email', emailLower)
        .maybeSingle();

      if (error) {
        console.error('[AuthService.login] DB error:', error);
      }

      // Auto-upsert admin@techconnect.cm in Supabase if missing
      if (!user && emailLower === 'admin@techconnect.cm') {
        console.log('[AuthService.login] Admin missing in Supabase, auto-upserting...');
        const passwordHash = await bcrypt.hash(password, 10);
        const { data: createdAdmin, error: createAdminErr } = await supabase
          .from('users')
          .upsert([
            {
              full_name: 'Admin TechConnect',
              email: 'admin@techconnect.cm',
              phone: '+237690000000',
              password_hash: passwordHash,
              role: 'admin'
            }
          ], { onConflict: 'email' })
          .select('id, full_name, email, phone, password_hash, role, avatar_url, created_at')
          .single();

        if (createAdminErr) {
          console.error('[AuthService.login] Admin upsert error:', JSON.stringify(createAdminErr));
          throw ApiError.unauthorized('Erreur de création du compte admin. Vérifiez les logs du serveur.');
        }
        user = createdAdmin;
        console.log('[AuthService.login] Admin upserted successfully:', user.id);
      }

      if (!user) {
        throw ApiError.unauthorized('Email ou mot de passe incorrect');
      }

      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        throw ApiError.unauthorized('Email ou mot de passe incorrect');
      }

      delete user.password_hash;
      
      // Fetch technician profile if applicable, so frontend knows it's complete
      if (user.role === 'technician') {
        const { data: techProfile } = await supabase
          .from('technician_profiles')
          .select(`
            id, bio, years_experience, price_min, price_max, whatsapp, verified, availability, rating_avg, rating_count,
            city:cities(id, name, region:regions(id, name)),
            categories:technician_categories(category:categories(id, name, icon))
          `)
          .eq('user_id', user.id)
          .single();

        if (techProfile) {
          user.technician_profile = techProfile;
        }
      }

      const token = this.generateToken(user);
      console.log('[AuthService.login] Login successful for user:', user.id);

      return { user, token };
    }

    // Local fallback
    const user = mockUsers.get(emailLower);
    if (!user) {
      throw ApiError.unauthorized('Email ou mot de passe incorrect');
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      throw ApiError.unauthorized('Email ou mot de passe incorrect');
    }

    const userToReturn = { ...user };
    delete userToReturn.password_hash;
    const token = this.generateToken(userToReturn);

    return { user: userToReturn, token };
  }

  static async getMe(userId) {
    if (supabase) {
      const { data: user, error } = await supabase
        .from('users')
        .select('id, full_name, email, phone, role, avatar_url, created_at')
        .eq('id', userId)
        .single();

      if (error || !user) {
        throw ApiError.notFound('Utilisateur non trouvé');
      }

      let profileData = null;
      if (user.role === 'technician') {
        const { data: techProfile } = await supabase
          .from('technician_profiles')
          .select(`
            id, bio, years_experience, price_min, price_max, whatsapp, verified, availability, rating_avg, rating_count,
            city:cities(id, name, region:regions(id, name)),
            categories:technician_categories(category:categories(id, name, icon))
          `)
          .eq('user_id', userId)
          .single();

        profileData = techProfile;
      }

      return { ...user, technician_profile: profileData };
    }

    // Local fallback
    for (const u of mockUsers.values()) {
      if (u.id === userId) {
        const copy = { ...u };
        delete copy.password_hash;
        return copy;
      }
    }

    throw ApiError.notFound('Utilisateur non trouvé');
  }

  static async updateMe(userId, { fullName, phone }) {
    const updateData = {};
    if (fullName !== undefined) updateData.full_name = fullName;
    if (phone !== undefined) updateData.phone = phone;

    if (Object.keys(updateData).length === 0) {
      return this.getMe(userId);
    }

    if (supabase) {
      const { error } = await supabase
        .from('users')
        .update(updateData)
        .eq('id', userId);

      if (error) {
        throw ApiError.internal('Erreur lors de la mise à jour du profil');
      }

      return this.getMe(userId);
    }

    // Local fallback
    let userFound = false;
    for (const u of mockUsers.values()) {
      if (u.id === userId) {
        Object.assign(u, updateData);
        userFound = true;
        break;
      }
    }

    if (!userFound) {
      throw ApiError.notFound('Utilisateur non trouvé');
    }

    return this.getMe(userId);
  }

  static async uploadAvatar(userId, file, baseUrl = '') {
    if (!file) {
      throw ApiError.badRequest('Fichier image manquant');
    }

    const path = require('path');
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw ApiError.badRequest('Format non autorisé. Formats acceptés: JPEG, PNG, WEBP');
    }

    const ext = path.extname(file.originalname) || '.jpg';
    const filename = `avatar_${userId}_${Date.now()}${ext}`;

    if (supabase) {
      // ── Upload to Supabase Storage (avatars — public bucket) ───────────────
      const storagePath = `users/${filename}`;
      console.log(`[AuthService.uploadAvatar] Uploading to Supabase Storage: ${storagePath}`);

      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(storagePath, file.buffer, {
          contentType: file.mimetype,
          upsert: true, // overwrite previous avatar with same name
        });

      if (uploadError) {
        console.error('[AuthService.uploadAvatar] Storage upload error:', uploadError);
        throw ApiError.internal('Erreur lors du téléversement de la photo de profil');
      }

      // Get the public URL (avatars bucket is public)
      const { data: publicUrlData } = supabase.storage
        .from('avatars')
        .getPublicUrl(storagePath);

      const avatarUrl = publicUrlData.publicUrl;
      console.log(`[AuthService.uploadAvatar] Public URL: ${avatarUrl}`);

      const { error: dbError } = await supabase
        .from('users')
        .update({ avatar_url: avatarUrl })
        .eq('id', userId);

      if (dbError) {
        console.error('[AuthService.uploadAvatar] DB update error:', dbError);
        throw ApiError.internal('Erreur lors de la mise à jour de l\'avatar');
      }

      return { avatarUrl };
    }

    // ── Local fallback — write to disk ────────────────────────────────────────
    const fs = require('fs');
    const uploadsDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
    if (file.buffer) fs.writeFileSync(path.join(uploadsDir, filename), file.buffer);
    const avatarUrl = baseUrl ? `${baseUrl}/uploads/${filename}` : `uploads/${filename}`;

    for (const u of mockUsers.values()) {
      if (u.id === userId) { u.avatar_url = avatarUrl; break; }
    }

    console.log(`[AuthService.uploadAvatar] Avatar saved locally for user ${userId}: ${avatarUrl}`);
    return { avatarUrl };
  }


  static async changePassword(userId, oldPassword, newPassword) {
    console.log(`[AuthService.changePassword] Request to change password for user: ${userId}`);
    if (supabase) {
      const { data: user, error: fetchError } = await supabase
        .from('users')
        .select('id, password_hash')
        .eq('id', userId)
        .single();
        
      if (fetchError || !user) {
        console.error('[AuthService.changePassword] User not found:', fetchError);
        throw ApiError.notFound('Utilisateur non trouvé');
      }

      const isMatch = await bcrypt.compare(oldPassword, user.password_hash);
      if (!isMatch) {
        console.warn('[AuthService.changePassword] Old password mismatch');
        throw ApiError.unauthorized('L\'ancien mot de passe est incorrect');
      }

      const newPasswordHash = await bcrypt.hash(newPassword, 10);
      const { error: updateError } = await supabase
        .from('users')
        .update({ password_hash: newPasswordHash })
        .eq('id', userId);

      if (updateError) {
        console.error('[AuthService.changePassword] Update error:', updateError);
        throw ApiError.internal('Erreur lors du changement de mot de passe');
      }
      
      console.log('[AuthService.changePassword] Password changed successfully in Supabase');
      return true;
    }

    // Local fallback
    let userFound = false;
    for (const u of mockUsers.values()) {
      if (u.id === userId) {
        const isMatch = await bcrypt.compare(oldPassword, u.password_hash);
        if (!isMatch) {
          console.warn('[AuthService.changePassword] Local old password mismatch');
          throw ApiError.unauthorized('L\'ancien mot de passe est incorrect');
        }
        u.password_hash = await bcrypt.hash(newPassword, 10);
        userFound = true;
        console.log('[AuthService.changePassword] Password changed successfully in local mock');
        break;
      }
    }

    if (!userFound) {
      console.error('[AuthService.changePassword] User not found in local mock');
      throw ApiError.notFound('Utilisateur non trouvé');
    }

    return true;
  }
}

module.exports = AuthService;
