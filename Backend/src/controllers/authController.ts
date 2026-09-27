import { Request, Response } from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import db from "../db/db";
import { EmailService } from "../utils/EmailService";

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
        await EmailService.sendOTP(email || mobile_number, otp);

        return res.status(200).json({
          message: "Account pending verification. New OTP sent.",
          otp: process.env.NODE_ENV !== "production" ? otp : undefined
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
    await EmailService.sendOTP(email || mobile_number, otp);

    res.status(201).json({
      message: "User registered successfully. OTP sent for verification.",
      otp: process.env.NODE_ENV !== "production" ? otp : undefined
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

    if (!otpRecord) return res.status(400).json({ error: "Invalid or expired OTP" });

    const isMatch = await bcrypt.compare(otp, otpRecord.otp_hash);
    if (!isMatch) return res.status(400).json({ error: "Invalid or expired OTP" });

    await db("otps").where({ id: otpRecord.id }).update({ used: true });

    await db("users")
      .where({ id: user.id })
      .update({
        status: "ACTIVE",
        email_verified: !!email,
        mobile_verified: !!mobile_number,
      });

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET || "supersecretjwt",
      { expiresIn: "7d" }
    );

    res.json({
      message: "Verification successful",
      token,
      user: { id: user.id, email: user.email, mobile_number: user.mobile_number, name: user.name, role: user.role }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const { email, mobile_number, password } = req.body;
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
      { id: user.id, role: user.role },
      process.env.JWT_SECRET || "supersecretjwt",
      { expiresIn: "1h" }
    );
    res.json({ token, user: { id: user.id, email: user.email, mobile_number: user.mobile_number, name: user.name, role: user.role } });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
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

    await EmailService.sendOTP(email || mobile_number, otp);

    res.json({ message: "Password reset OTP sent" });
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
