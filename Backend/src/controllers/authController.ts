import { Request, Response } from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import db from "../db/db";
import { EmailService } from "../utils/EmailService";
import { SupabaseService } from "../utils/SupabaseService";
import { EntitlementService } from "../services/entitlementService";
import { SocialAuthVerifier, VerifiedSocialProfile } from "../utils/SocialAuthVerifier";

const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

export const signup = async (req: Request, res: Response) => {
  try {
    const email = req.body.email;
    const mobile_number = req.body.mobile_number || req.body.mobile;
    const password = req.body.password;
    const name = req.body.name || req.body.fullName || "User";

    if (!email && !mobile_number) {
      return res.status(400).json({ error: "Email or mobile number is required" });
    }

    const query = db("users").where(function () {
      if (email) this.where({ email });
      if (mobile_number) this.orWhere({ mobile_number });
    });

    const existingUser = await query.first();
    if (existingUser) {
      if (existingUser.status === "PENDING") {
        const otp = generateOTP();
        const otpHash = await bcrypt.hash(otp, 10);
        const expiresAt = new Date(Date.now() + 10 * 60000);

        await db("otps").insert({
          user_id: existingUser.id,
          otp_hash: otpHash,
          expires_at: expiresAt,
        });

        console.log(`\n========================================\n>>> SIGNUP OTP: ${otp} for ${email || mobile_number}\n========================================\n`);
        const emailSent = await EmailService.sendOTP(email || mobile_number, otp);

        return res.status(200).json({
          message: emailSent
            ? "Account pending verification. OTP sent."
            : "Account pending verification. Enter the 6-digit code to continue.",
          otp: (!emailSent || process.env.NODE_ENV !== "production") ? otp : undefined
        });
      }
      return res.status(400).json({ error: "User already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const [user] = await db("users")
      .insert({
        email: email || null,
        mobile_number: mobile_number || null,
        password_hash: hashedPassword,
        name,
        status: "PENDING",
      })
      .returning(["id", "email", "mobile_number", "name"]);

    const otp = generateOTP();
    const otpHash = await bcrypt.hash(otp, 10);
    const expiresAt = new Date(Date.now() + 10 * 60000); // 10 mins expiry

    await db("otps").insert({
      user_id: user.id,
      otp_hash: otpHash,
      expires_at: expiresAt,
    });

    console.log(`\n========================================\n>>> SIGNUP OTP: ${otp} for ${email || mobile_number}\n========================================\n`);
    const emailSent = await EmailService.sendOTP(email || mobile_number, otp);

    return res.status(201).json({
      message: emailSent
        ? "User registered successfully. OTP sent for verification."
        : "User registered successfully. Enter the 6-digit code to continue.",
      otp: (!emailSent || process.env.NODE_ENV !== "production") ? otp : undefined
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const verifyOtp = async (req: Request, res: Response) => {
  try {
    const { email, mobile_number, otp } = req.body;
    if ((!email && !mobile_number) || !otp) {
      return res.status(400).json({ error: "Email/mobile and OTP are required" });
    }

    const userQuery = db("users").where(email ? { email } : { mobile_number });
    const user = await userQuery.first();
    if (!user) return res.status(404).json({ error: "User not found" });

    const otpRecord = await db("otps")
      .where({ user_id: user.id, used: false })
      .andWhere("expires_at", ">", new Date())
      .orderBy("created_at", "desc")
      .first();

    let isMatch = false;
    if (otpRecord) {
      isMatch = await bcrypt.compare(otp, otpRecord.otp_hash);
      if (isMatch) {
        await db("otps").where({ id: otpRecord.id }).update({ used: true });
      }
    }

    if (!isMatch && email && SupabaseService.isConfigured()) {
      isMatch = await SupabaseService.verifyOtp(email, otp);
    }

    if (!isMatch) return res.status(400).json({ error: "Invalid or expired OTP" });

    await db("users")
      .where({ id: user.id })
      .update({
        status: "ACTIVE",
        email_verified: !!email,
        mobile_verified: !!mobile_number,
        last_login_at: new Date()
      });

    const token = jwt.sign(
      { id: user.id, role: user.role || "USER" },
      process.env.JWT_SECRET || "supersecretjwt",
      { expiresIn: "7d" }
    );

    const entitlement = await EntitlementService.getEntitlement(user.id);

    res.json({
      message: "Verification successful",
      token,
      user: {
        id: user.id,
        email: user.email,
        mobile_number: user.mobile_number,
        name: user.name,
        role: user.role || "USER",
        avatar: user.avatar,
        is_subscribed: user.is_subscribed || false
      },
      entitlement
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const { email, mobile_number, password } = req.body || {};
    if ((!email && !mobile_number) || !password) {
      return res.status(400).json({ error: "Email/mobile and password are required" });
    }

    const user = await db("users").where(email ? { email } : { mobile_number }).first();
    if (!user) return res.status(400).json({ error: "Invalid credentials" });

    if (user.status === "PENDING") {
      return res.status(403).json({ error: "Account pending verification" });
    }
    if (user.status !== "ACTIVE") {
      return res.status(403).json({ error: "Account is not active" });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) return res.status(400).json({ error: "Invalid credentials" });

    await db("users").where({ id: user.id }).update({ last_login_at: new Date() });

    const token = jwt.sign(
      { id: user.id, role: user.role || "USER" },
      process.env.JWT_SECRET || "supersecretjwt",
      { expiresIn: "7d" }
    );

    const entitlement = await EntitlementService.getEntitlement(user.id);

    return res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        mobile_number: user.mobile_number,
        name: user.name,
        role: user.role || "USER",
        avatar: user.avatar,
        is_subscribed: user.is_subscribed || false
      },
      entitlement
    });
  } catch (error: any) {
    console.error("[Login Error]:", error);
    return res.status(500).json({ error: error?.message || "Internal server error" });
  }
};

export const forgotPassword = async (req: Request, res: Response) => {
  try {
    const { email, mobile_number } = req.body;
    if (!email && !mobile_number) {
      return res.status(400).json({ error: "Email or mobile number is required" });
    }

    const user = await db("users").where(email ? { email } : { mobile_number }).first();
    if (!user) return res.status(404).json({ error: "User not found" });

    const otp = generateOTP();
    const otpHash = await bcrypt.hash(otp, 10);
    const expiresAt = new Date(Date.now() + 10 * 60000);

    await db("otps").insert({
      user_id: user.id,
      otp_hash: otpHash,
      expires_at: expiresAt,
    });

    const emailSent = await EmailService.sendOTP(email || mobile_number, otp);

    return res.json({
      message: emailSent ? "Password reset OTP sent" : "Password reset OTP generated",
      otp: (!emailSent || process.env.NODE_ENV !== "production") ? otp : undefined
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const resetPassword = async (req: Request, res: Response) => {
  try {
    const { email, mobile_number, otp, new_password } = req.body;
    if ((!email && !mobile_number) || !otp || !new_password) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const user = await db("users").where(email ? { email } : { mobile_number }).first();
    if (!user) return res.status(404).json({ error: "User not found" });

    const otpRecord = await db("otps")
      .where({ user_id: user.id, used: false })
      .andWhere("expires_at", ">", new Date())
      .orderBy("created_at", "desc")
      .first();

    if (!otpRecord) return res.status(400).json({ error: "Invalid or expired OTP" });

    const isMatch = await bcrypt.compare(otp, otpRecord.otp_hash);
    if (!isMatch) return res.status(400).json({ error: "Invalid or expired OTP" });

    const hashedPassword = await bcrypt.hash(new_password, 10);
    
    await db.transaction(async (trx) => {
      await trx("otps").where({ id: otpRecord.id }).update({ used: true });
      await trx("users").where({ id: user.id }).update({ password_hash: hashedPassword });
    });

    res.json({ message: "Password reset successfully" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const socialLogin = async (req: Request, res: Response) => {
  try {
    const { provider, email, name, avatar } = req.body;
    if (!email) {
      return res.status(400).json({ error: "Email is required for social login" });
    }

    let user = await db("users").where({ email }).first();
    if (!user) {
      const randomPassword = Math.random().toString(36).slice(-10);
      const hashedPassword = await bcrypt.hash(randomPassword, 10);
      const [newUser] = await db("users")
        .insert({
          email,
          name: name || `${provider ? provider.charAt(0).toUpperCase() + provider.slice(1) : "Social"} User`,
          password_hash: hashedPassword,
          status: "ACTIVE",
          email_verified: true,
          avatar: avatar || null,
          role: "USER"
        })
        .returning("*");
      user = newUser;
    } else {
      if (user.status === "PENDING") {
        await db("users").where({ id: user.id }).update({ status: "ACTIVE", email_verified: true });
        user.status = "ACTIVE";
      }
      await db("users").where({ id: user.id }).update({ last_login_at: new Date() });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role || "user" },
      process.env.JWT_SECRET || "supersecretjwt",
      { expiresIn: "7d" }
    );

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        mobile_number: user.mobile_number,
        name: user.name,
        role: user.role || "user",
        avatar: user.avatar
      }
    });
  } catch (error) {
    console.error("Social login error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const firebaseLogin = async (req: Request, res: Response) => {
  try {
    const { email, name, firebaseUid, avatar, mobile_number } = req.body;
    if (!email && !mobile_number) {
      return res.status(400).json({ error: "Email or mobile number is required for Firebase login" });
    }

    let user = await db("users").where(function () {
      if (email) this.where({ email });
      if (mobile_number) this.orWhere({ mobile_number });
    }).first();

    if (!user) {
      const randomPassword = Math.random().toString(36).slice(-10) + Math.random().toString(36).slice(-10);
      const hashedPassword = await bcrypt.hash(randomPassword, 10);
      const [newUser] = await db("users")
        .insert({
          email: email || null,
          mobile_number: mobile_number || null,
          name: name || (email ? email.split("@")[0] : "User"),
          password_hash: hashedPassword,
          status: "ACTIVE",
          email_verified: !!email,
          mobile_verified: !!mobile_number,
          avatar: avatar || null,
          role: "USER"
        })
        .returning("*");
      user = newUser;
    } else {
      const updates: any = {
        last_login_at: new Date()
      };
      if (user.status === "PENDING") {
        updates.status = "ACTIVE";
      }
      if (email && !user.email_verified) {
        updates.email_verified = true;
      }
      if (avatar && !user.avatar) {
        updates.avatar = avatar;
      }
      await db("users").where({ id: user.id }).update(updates);
      user = { ...user, ...updates };
    }

    const token = jwt.sign(
      { id: user.id, role: user.role || "USER" },
      process.env.JWT_SECRET || "supersecretjwt",
      { expiresIn: "7d" }
    );

    const entitlement = await EntitlementService.getEntitlement(user.id);

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        mobile_number: user.mobile_number,
        name: user.name,
        role: user.role || "USER",
        avatar: user.avatar,
        is_subscribed: user.is_subscribed || false
      },
      entitlement
    });
  } catch (error) {
    console.error("Firebase login error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

/**
 * Shared Social Authentication Handler
 * Enforces:
 * - Provider identity linking in `user_identities` table
 * - Duplicate email protection (requires account verification before linking)
 * - 7-day trial initiation only on new account creation
 * - Lifetime Premium preservation
 */
async function handleSocialAuthentication(profile: VerifiedSocialProfile, res: Response) {
  try {
    const { provider, providerUserId, email, name, avatar } = profile;

    // 1. Check if provider identity is already linked to an existing account
    const existingIdentity = await db("user_identities")
      .where({ provider, provider_user_id: providerUserId })
      .first();

    if (existingIdentity) {
      const user = await db("users").where({ id: existingIdentity.user_id }).first();
      if (!user) {
        return res.status(404).json({ error: "Linked user account not found" });
      }

      // Update last login timestamp and identity details
      await db("users").where({ id: user.id }).update({ last_login_at: new Date() });
      await db("user_identities")
        .where({ id: existingIdentity.id })
        .update({
          updated_at: new Date(),
          email: email || existingIdentity.email,
          name: name || existingIdentity.name,
          avatar_url: avatar || existingIdentity.avatar_url,
        });

      const token = jwt.sign(
        { id: user.id, role: user.role || "USER" },
        process.env.JWT_SECRET || "supersecretjwt",
        { expiresIn: "7d" }
      );

      const entitlement = await EntitlementService.getEntitlement(user.id);

      return res.json({
        token,
        user: {
          id: user.id,
          email: user.email,
          mobile_number: user.mobile_number,
          name: user.name,
          role: user.role || "USER",
          avatar: user.avatar || avatar,
          is_subscribed: user.is_subscribed || false
        },
        entitlement
      });
    }

    // 2. Identity not found. Check if an account already exists with the same email
    if (email) {
      const existingUserByEmail = await db("users").where({ email }).first();

      if (existingUserByEmail) {
        // SECURITY RULE: Never auto-merge without verification.
        // Issue a signed 15-minute temporary linkToken so user can verify password to link.
        const linkToken = jwt.sign(
          {
            sub: existingUserByEmail.id,
            email,
            provider,
            providerUserId,
            name: name || existingUserByEmail.name,
            avatar: avatar || existingUserByEmail.avatar
          },
          process.env.JWT_SECRET || "supersecretjwt",
          { expiresIn: "15m" }
        );

        return res.status(409).json({
          error: "ACCOUNT_EXISTS_LINK_REQUIRED",
          message: `An account with email ${email} already exists. Please verify your existing password to link your ${provider} account.`,
          email,
          provider,
          linkToken
        });
      }
    }

    // 3. New User: Safely create Financy user and link provider identity inside transaction
    const newUser = await db.transaction(async (trx) => {
      const [createdUser] = await trx("users")
        .insert({
          email: email || null,
          name: name || `${provider.charAt(0).toUpperCase() + provider.slice(1)} User`,
          status: "ACTIVE",
          email_verified: !!email,
          avatar: avatar || null,
          role: "USER"
        })
        .returning("*");

      await trx("user_identities").insert({
        user_id: createdUser.id,
        provider,
        provider_user_id: providerUserId,
        email: email || null,
        name: name || null,
        avatar_url: avatar || null,
        raw_profile: profile.raw ? JSON.stringify(profile.raw) : null
      });

      return createdUser;
    });

    // 4. Initialize 7-day free trial on new account creation
    const entitlement = await EntitlementService.getEntitlement(newUser.id);

    const token = jwt.sign(
      { id: newUser.id, role: newUser.role || "USER" },
      process.env.JWT_SECRET || "supersecretjwt",
      { expiresIn: "7d" }
    );

    return res.status(201).json({
      token,
      user: {
        id: newUser.id,
        email: newUser.email,
        mobile_number: newUser.mobile_number,
        name: newUser.name,
        role: newUser.role || "USER",
        avatar: newUser.avatar,
        is_subscribed: newUser.is_subscribed || false
      },
      entitlement
    });
  } catch (err: any) {
    console.error("[Social Auth Error]:", err);
    return res.status(500).json({ error: err.message || "Failed to authenticate with social provider" });
  }
}

/**
 * POST /api/auth/apple
 */
export const appleAuth = async (req: Request, res: Response) => {
  try {
    const { identityToken, userIdentifier, fullName, email } = req.body;
    if (!identityToken) {
      return res.status(400).json({ error: "Missing required Apple identityToken" });
    }

    const verified = await SocialAuthVerifier.verifyAppleToken({
      identityToken,
      userIdentifier,
      fullName,
      email,
    });

    return await handleSocialAuthentication(verified, res);
  } catch (error: any) {
    console.error("[Apple Auth Error]:", error);
    return res.status(401).json({ error: error.message || "Apple authentication failed" });
  }
};

/**
 * POST /api/auth/google
 */
export const googleAuth = async (req: Request, res: Response) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ error: "Missing required Google idToken" });
    }

    const verified = await SocialAuthVerifier.verifyGoogleToken(idToken);
    return await handleSocialAuthentication(verified, res);
  } catch (error: any) {
    console.error("[Google Auth Error]:", error);
    return res.status(401).json({ error: error.message || "Google authentication failed" });
  }
};

/**
 * POST /api/auth/facebook
 */
export const facebookAuth = async (req: Request, res: Response) => {
  try {
    const { accessToken } = req.body;
    if (!accessToken) {
      return res.status(400).json({ error: "Missing required Facebook accessToken" });
    }

    const verified = await SocialAuthVerifier.verifyFacebookToken(accessToken);
    return await handleSocialAuthentication(verified, res);
  } catch (error: any) {
    console.error("[Facebook Auth Error]:", error);
    return res.status(401).json({ error: error.message || "Facebook authentication failed" });
  }
};

/**
 * POST /api/auth/link-account
 * Verifies credentials for existing account and links the new provider identity
 */
export const linkAccount = async (req: Request, res: Response) => {
  try {
    const { linkToken, password } = req.body;
    if (!linkToken || !password) {
      return res.status(400).json({ error: "linkToken and password are required" });
    }

    let decoded: any;
    try {
      decoded = jwt.verify(linkToken, process.env.JWT_SECRET || "supersecretjwt");
    } catch {
      return res.status(400).json({ error: "Link session expired or invalid. Please try social login again." });
    }

    const user = await db("users").where({ id: decoded.sub }).first();
    if (!user) {
      return res.status(404).json({ error: "User account not found" });
    }

    if (!user.password_hash) {
      return res.status(400).json({ error: "Existing account does not have a password configured." });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: "Invalid password for existing account." });
    }

    // Link identity inside transaction
    await db.transaction(async (trx) => {
      // Check if already linked
      const existing = await trx("user_identities")
        .where({ provider: decoded.provider, provider_user_id: decoded.providerUserId })
        .first();

      if (!existing) {
        await trx("user_identities").insert({
          user_id: user.id,
          provider: decoded.provider,
          provider_user_id: decoded.providerUserId,
          email: decoded.email,
          name: decoded.name,
          avatar_url: decoded.avatar,
        });
      }

      await trx("users").where({ id: user.id }).update({ last_login_at: new Date() });
    });

    const token = jwt.sign(
      { id: user.id, role: user.role || "USER" },
      process.env.JWT_SECRET || "supersecretjwt",
      { expiresIn: "7d" }
    );

    const entitlement = await EntitlementService.getEntitlement(user.id);

    return res.json({
      message: "Account successfully linked!",
      token,
      user: {
        id: user.id,
        email: user.email,
        mobile_number: user.mobile_number,
        name: user.name,
        role: user.role || "USER",
        avatar: user.avatar || decoded.avatar,
        is_subscribed: user.is_subscribed || false
      },
      entitlement
    });
  } catch (error: any) {
    console.error("[Link Account Error]:", error);
    return res.status(500).json({ error: error.message || "Failed to link account" });
  }
};


