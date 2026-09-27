export class EmailService {
  static async sendOTP(recipient: string, otp: string) {
    console.log(`[EmailService Mock] Sending OTP ${otp} to ${recipient}`);
    return Promise.resolve();
  }
}
