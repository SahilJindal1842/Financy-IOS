import { createClient, SupabaseClient } from "@supabase/supabase-js";

export class SupabaseService {
  private static client: SupabaseClient | null = null;

  static getClient(): SupabaseClient | null {
    if (this.client) return this.client;
    const url = process.env.SUPABASE_URL || "https://ktwlxmhavcvihlwvnnmg.supabase.co";
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;
    if (url && key) {
      this.client = createClient(url, key, {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      });
      return this.client;
    }
    return null;
  }

  static isConfigured(): boolean {
    return !!(process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY);
  }

  /**
   * Request Supabase GoTrue Auth to send an email OTP to the recipient.
   */
  static async sendOtpEmail(email: string): Promise<boolean> {
    const client = this.getClient();
    if (!client) return false;
    try {
      const { error } = await client.auth.signInWithOtp({
        email,
        options: {
          shouldCreateUser: true,
        },
      });
      if (error) {
        console.warn("[SupabaseService] signInWithOtp notice:", error.message);
        return false;
      }
      console.log(`[SupabaseService] OTP email dispatched to ${email} via Supabase Auth.`);
      return true;
    } catch (err) {
      console.error("[SupabaseService] Error sending OTP:", err);
      return false;
    }
  }

  /**
   * Verify an email OTP token with Supabase GoTrue Auth.
   */
  static async verifyOtp(email: string, token: string): Promise<boolean> {
    const client = this.getClient();
    if (!client) return false;
    try {
      const { data, error } = await client.auth.verifyOtp({
        email,
        token,
        type: "email",
      });
      if (error || !data.user) {
        // Try 'signup' verification type as well
        const { data: signupData, error: signupError } = await client.auth.verifyOtp({
          email,
          token,
          type: "signup",
        });
        if (signupError || !signupData.user) {
          return false;
        }
      }
      return true;
    } catch (err) {
      console.error("[SupabaseService] Error verifying OTP:", err);
      return false;
    }
  }
}
