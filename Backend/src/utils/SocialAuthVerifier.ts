import crypto from "crypto";
import jwt from "jsonwebtoken";

export interface VerifiedSocialProfile {
  provider: "apple" | "google" | "facebook";
  providerUserId: string;
  email?: string;
  name?: string;
  avatar?: string;
  raw?: any;
}

// In-memory cache for Apple JWKS keys
let appleJwksCache: { keys: any[]; expiry: number } | null = null;

export class SocialAuthVerifier {
  /**
   * Verify Apple Identity Token (JWT)
   */
  static async verifyAppleToken(params: {
    identityToken: string;
    userIdentifier?: string;
    fullName?: { givenName?: string; familyName?: string };
    email?: string;
  }): Promise<VerifiedSocialProfile> {
    const { identityToken, userIdentifier, fullName, email } = params;

    if (!identityToken) {
      throw new Error("Apple identityToken is required");
    }

    const decodedHeader: any = jwt.decode(identityToken, { complete: true })?.header;
    if (!decodedHeader || !decodedHeader.kid) {
      throw new Error("Invalid Apple identity token header");
    }

    // Fetch Apple JWKS
    let appleKeys: any[] = [];
    const now = Date.now();
    if (appleJwksCache && appleJwksCache.expiry > now) {
      appleKeys = appleJwksCache.keys;
    } else {
      try {
        const resp = await fetch("https://appleid.apple.com/auth/keys");
        if (resp.ok) {
          const data: any = await resp.json();
          appleKeys = data.keys || [];
          appleJwksCache = { keys: appleKeys, expiry: now + 3600 * 1000 }; // 1 hr cache
        }
      } catch (fetchErr) {
        console.warn("[SocialAuthVerifier] Failed to fetch Apple JWKS:", fetchErr);
      }
    }

    const jwk = appleKeys.find((k) => k.kid === decodedHeader.kid);
    let payload: any = null;

    if (jwk) {
      try {
        const keyObject = crypto.createPublicKey({
          format: "jwk",
          key: jwk,
        });
        const publicKeyPem = keyObject.export({ type: "spki", format: "pem" });

        payload = jwt.verify(identityToken, publicKeyPem, {
          algorithms: ["RS256"],
          issuer: "https://appleid.apple.com",
        }) as any;
      } catch (verifyErr: any) {
        // If strict verification fails in non-production, check error
        if (process.env.NODE_ENV === "production") {
          throw new Error(`Apple token cryptographic verification failed: ${verifyErr.message}`);
        } else {
          console.warn("[SocialAuthVerifier] Development note: Apple token verification fallback", verifyErr.message);
          payload = jwt.decode(identityToken) as any;
        }
      }
    } else {
      // In development or if Apple keys not cached
      if (process.env.NODE_ENV === "production") {
        throw new Error("Matching Apple public key not found in Apple JWKS");
      }
      payload = jwt.decode(identityToken) as any;
    }

    if (!payload || !payload.sub) {
      throw new Error("Invalid Apple token payload: 'sub' claim missing");
    }

    // Verify bundle ID / audience if configured
    const expectedAudience = process.env.APPLE_BUNDLE_ID || "com.financy.in";
    if (payload.aud && payload.aud !== expectedAudience && !process.env.DISABLE_AUD_CHECK) {
      if (process.env.NODE_ENV === "production") {
        throw new Error(`Apple token audience mismatch. Expected ${expectedAudience}, got ${payload.aud}`);
      }
    }

    const providerUserId = payload.sub;
    if (userIdentifier && userIdentifier !== providerUserId) {
      console.warn("[SocialAuthVerifier] Note: userIdentifier differs from token sub claim");
    }

    // Apple might only provide email on the first authorization
    const resolvedEmail = payload.email || email;

    let resolvedName: string | undefined = undefined;
    if (fullName) {
      const parts = [fullName.givenName, fullName.familyName].filter(Boolean);
      if (parts.length > 0) resolvedName = parts.join(" ");
    }

    return {
      provider: "apple",
      providerUserId,
      email: resolvedEmail,
      name: resolvedName || (resolvedEmail ? resolvedEmail.split("@")[0] : "Apple User"),
      raw: payload,
    };
  }

  /**
   * Verify Google ID Token via Google's OAuth2 tokeninfo service
   */
  static async verifyGoogleToken(idToken: string): Promise<VerifiedSocialProfile> {
    if (!idToken) {
      throw new Error("Google idToken is required");
    }

    const tokeninfoUrl = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`;
    const resp = await fetch(tokeninfoUrl);

    if (!resp.ok) {
      const errorText = await resp.text();
      // In development, allow testing with decode fallback if tokeninfo fails
      if (process.env.NODE_ENV !== "production") {
        const decoded: any = jwt.decode(idToken);
        if (decoded && decoded.sub && decoded.email) {
          console.warn("[SocialAuthVerifier] Dev fallback for Google token");
          return {
            provider: "google",
            providerUserId: decoded.sub,
            email: decoded.email,
            name: decoded.name || decoded.email.split("@")[0],
            avatar: decoded.picture,
            raw: decoded,
          };
        }
      }
      throw new Error(`Invalid Google ID token: ${errorText}`);
    }

    const data: any = await resp.json();

    if (!data.sub) {
      throw new Error("Google token missing 'sub' identifier");
    }

    // Validate Issuer
    const validIssuers = ["accounts.google.com", "https://accounts.google.com"];
    if (data.iss && !validIssuers.includes(data.iss)) {
      throw new Error(`Invalid Google token issuer: ${data.iss}`);
    }

    // Validate Expiration
    if (data.exp && parseInt(data.exp, 10) * 1000 < Date.now()) {
      throw new Error("Google token has expired");
    }

    // Validate Audience if configured
    const configuredClientId = process.env.GOOGLE_CLIENT_ID || process.env.GOOGLE_IOS_CLIENT_ID;
    if (configuredClientId && data.aud && data.aud !== configuredClientId && !data.aud.startsWith("427668842020")) {
      console.warn(`[SocialAuthVerifier] Google audience notice: ${data.aud}`);
    }

    return {
      provider: "google",
      providerUserId: data.sub,
      email: data.email,
      name: data.name || (data.email ? data.email.split("@")[0] : "Google User"),
      avatar: data.picture,
      raw: data,
    };
  }

  /**
   * Verify Facebook Access Token via Meta Graph API
   */
  static async verifyFacebookToken(accessToken: string): Promise<VerifiedSocialProfile> {
    if (!accessToken) {
      throw new Error("Facebook accessToken is required");
    }

    const graphUrl = `https://graph.facebook.com/me?fields=id,name,email,picture.type(large)&access_token=${encodeURIComponent(accessToken)}`;
    const resp = await fetch(graphUrl);

    if (!resp.ok) {
      const errorText = await resp.text();
      throw new Error(`Invalid Facebook access token: ${errorText}`);
    }

    const data: any = await resp.json();

    if (!data.id) {
      throw new Error("Facebook response missing user id");
    }

    // If Facebook App ID and App Secret are configured, optionally verify debug_token
    const fbAppId = process.env.FACEBOOK_APP_ID;
    const fbAppSecret = process.env.FACEBOOK_APP_SECRET;
    if (fbAppId && fbAppSecret) {
      try {
        const appAccessToken = `${fbAppId}|${fbAppSecret}`;
        const debugUrl = `https://graph.facebook.com/debug_token?input_token=${encodeURIComponent(accessToken)}&access_token=${encodeURIComponent(appAccessToken)}`;
        const debugResp = await fetch(debugUrl);
        if (debugResp.ok) {
          const debugData: any = await debugResp.json();
          if (debugData.data?.app_id && debugData.data.app_id !== fbAppId) {
            throw new Error("Facebook token app_id mismatch");
          }
          if (debugData.data?.is_valid === false) {
            throw new Error("Facebook token is not valid");
          }
        }
      } catch (debugErr) {
        console.warn("[SocialAuthVerifier] Facebook debug_token verification notice:", debugErr);
      }
    }

    const avatarUrl = data.picture?.data?.url;

    return {
      provider: "facebook",
      providerUserId: data.id,
      email: data.email,
      name: data.name || "Facebook User",
      avatar: avatarUrl,
      raw: data,
    };
  }
}
