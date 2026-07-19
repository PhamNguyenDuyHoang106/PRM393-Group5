import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor(private readonly configService: ConfigService) {
    const user = this.configService.get<string>('EMAIL_USER');
    const pass = this.configService.get<string>('EMAIL_PASS');

    if (!user || !pass || user.includes('demo') || pass.includes('demo')) {
      this.logger.warn(
        'Email credentials not configured. Outgoing emails will be logged directly to the console/debug logs.',
      );
      return;
    }

    try {
      this.transporter = nodemailer.createTransport({
        host: 'smtp-relay.brevo.com', // Brevo SMTP server default
        port: 587,
        secure: false, // true for 465, false for other ports
        auth: {
          user,
          pass,
        },
      });
      this.logger.log('SMTP Mail transporter configured successfully.');
    } catch (error: any) {
      this.logger.error(`SMTP Transporter configuration error: ${error.message}`);
    }
  }

  async sendOtpEmail(to: string, otp: string): Promise<void> {
    const subject = 'Password Recovery Verification Code';
    const text = `Your password reset verification code is: ${otp}. It will expire in 5 minutes.`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 8px;">
        <h2 style="color: #2F80ED; text-align: center;">Reset Your Password</h2>
        <p>Dear User,</p>
        <p>You requested to recover your password. Please use the following 6-digit verification code to complete the verification step:</p>
        <div style="background-color: #F2F2F2; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #333; margin: 20px 0; border-radius: 4px;">
          ${otp}
        </div>
        <p style="color: #828282; font-size: 12px; text-align: center;">This code is valid for 5 minutes. Do not share this code with anyone.</p>
      </div>
    `;

    if (!this.transporter) {
      this.logger.log(`\n========================================\n[CONSOLE MAIL] Outgoing OTP to: ${to}\nOTP Code: ${otp}\n========================================\n`);
      return;
    }

    try {
      await this.transporter.sendMail({
        from: `"Smart Task Management" <${this.configService.get<string>('EMAIL_USER')}>`,
        to,
        subject,
        text,
        html,
      });
      this.logger.log(`OTP Email sent successfully to ${to}`);
    } catch (error: any) {
      this.logger.error(`Failed to send OTP Email to ${to}: ${error.message}`);
      // Fallback: log to console so development isn't blocked by network/SMTP failures!
      this.logger.log(`\n[FALLBACK CONSOLE MAIL] OTP to: ${to} -> OTP Code: ${otp}\n`);
    }
  }
}
