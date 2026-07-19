import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { OtpRepository } from './otp.repository';
import * as bcrypt from 'bcrypt';

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);

  constructor(private readonly otpRepository: OtpRepository) {}

  async generateOtp(email: string, userId?: string): Promise<string> {
    const latest = await this.otpRepository.findLatestByEmail(email);
    const now = new Date();

    // Check if locked out
    if (latest && latest.lockedUntil && latest.lockedUntil > now) {
      const minutesLeft = Math.ceil((latest.lockedUntil.getTime() - now.getTime()) / 60000);
      throw new BadRequestException(
        `Verification is temporarily locked due to too many failed attempts. Try again in ${minutesLeft} minutes.`,
      );
    }

    // Generate random 6-digit OTP code
    const rawOtp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpHash = await bcrypt.hash(rawOtp, 10);
    const expiresAt = new Date(now.getTime() + 5 * 60000); // 5 minutes TTL

    await this.otpRepository.create({
      email,
      userId,
      otpHash,
      expiresAt,
      attemptCount: 0,
      verified: false,
      resetCompleted: false,
    });

    return rawOtp;
  }

  async verifyOtp(email: string, otp: string): Promise<boolean> {
    const latest = await this.otpRepository.findLatestByEmail(email);
    const now = new Date();

    if (!latest) {
      throw new BadRequestException('No verification OTP request found for this email.');
    }

    // Check lock status
    if (latest.lockedUntil && latest.lockedUntil > now) {
      const minutesLeft = Math.ceil((latest.lockedUntil.getTime() - now.getTime()) / 60000);
      throw new BadRequestException(
        `Verification is locked. Try again in ${minutesLeft} minutes.`,
      );
    }

    if (latest.resetCompleted || latest.verified) {
      throw new BadRequestException('This OTP code has already been verified or completed.');
    }

    if (latest.expiresAt < now) {
      throw new BadRequestException('Verification OTP code has expired.');
    }

    // Check attempts limit before verification
    if (latest.attemptCount >= 5) {
      const lockedUntil = new Date(now.getTime() + 10 * 60000); // 10 minutes lock
      await this.otpRepository.update(latest.id, { lockedUntil });
      throw new BadRequestException(
        'Maximum verification attempts exceeded. Account verification locked for 10 minutes.',
      );
    }

    const isMatch = await bcrypt.compare(otp, latest.otpHash);

    if (isMatch) {
      // Success: Reset attempt counters and mark as verified
      await this.otpRepository.update(latest.id, {
        verified: true,
        attemptCount: 0,
        lastAttempt: now,
      });
      return true;
    } else {
      // Failure: Increment attempts counter
      const newAttempts = latest.attemptCount + 1;
      const updateData: any = {
        attemptCount: newAttempts,
        lastAttempt: now,
      };

      if (newAttempts >= 5) {
        updateData.lockedUntil = new Date(now.getTime() + 10 * 60000); // 10 minutes lock
      }

      await this.otpRepository.update(latest.id, updateData);

      if (newAttempts >= 5) {
        throw new BadRequestException(
          'Invalid OTP code. Maximum attempts reached. Account verification locked for 10 minutes.',
        );
      } else {
        throw new BadRequestException(
          `Invalid OTP code. Attempts remaining: ${5 - newAttempts}.`,
        );
      }
    }
  }

  async markOtpCompleted(email: string): Promise<void> {
    const latest = await this.otpRepository.findLatestByEmail(email);
    if (latest) {
      await this.otpRepository.update(latest.id, {
        resetCompleted: true,
      });
    }
  }
}
