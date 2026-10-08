import nodemailer, { Transporter } from "nodemailer";

export class EmailService {
  private static transporter: Transporter | null = null;

  private static getTransporter(): Transporter | null {
    if (this.transporter) return this.transporter;

    const host = process.env.SMTP_HOST;
    const port = parseInt(process.env.SMTP_PORT || "587", 10);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
      return this.transporter;
    }

    if (process.env.GMAIL_USER && process.env.GMAIL_APP_PASS) {
      this.transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: process.env.GMAIL_USER,
          pass: process.env.GMAIL_APP_PASS,
        },
      });
      return this.transporter;
    }

    return null;
  }

  static async sendOTP(recipient: string, otp: string) {
    const transporter = this.getTransporter();

    console.log(`\n========================================`);
    console.log(`>>> [Financy Auth] OTP for ${recipient}: [ ${otp} ]`);
    console.log(`========================================\n`);

    if (!transporter) {
      console.log(`[EmailService] Notice: SMTP not configured in .env. To send real emails to ${recipient}, set SMTP_HOST/USER/PASS or GMAIL_USER/GMAIL_APP_PASS in Backend/.env.`);
      return Promise.resolve();
    }

    try {
      const from = process.env.SMTP_FROM || process.env.GMAIL_USER || "Financy <no-reply@financy.app>";
      const mailOptions = {
        from,
        to: recipient,
        subject: `${otp} is your Financy Verification Code`,
        text: `Your Financy verification code is ${otp}. This code expires in 10 minutes. Do not share this code with anyone.`,
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 32px 24px; background: #ffffff; border-radius: 16px; border: 1px solid #e5e7eb;">
            <div style="text-align: center; margin-bottom: 24px;">
              <h1 style="color: #065f46; margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px;">Financy</h1>
              <p style="color: #6b7280; margin: 4px 0 0; font-size: 13px;">Your Personal Finance & Wealth Companion</p>
            </div>
            <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
              <p style="color: #374151; margin: 0 0 12px; font-size: 14px; font-weight: 500;">Use the verification code below to complete your registration:</p>
              <div style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #059669; font-family: monospace; padding: 12px 0;">${otp}</div>
              <p style="color: #6b7280; margin: 8px 0 0; font-size: 12px;">Valid for 10 minutes • Do not share with anyone</p>
            </div>
            <p style="color: #9ca3af; font-size: 12px; text-align: center; margin: 0;">If you didn't request this code, you can safely ignore this email.</p>
          </div>
        `
      };

      const info = await transporter.sendMail(mailOptions);
      console.log(`[EmailService] Email dispatched successfully to ${recipient}. MessageId: ${info.messageId}`);
    } catch (error) {
      console.error(`[EmailService] Failed to send email to ${recipient}:`, error);
    }
  }
}
