import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { UserRepository } from '../users/users.repository';
import { FirebaseService } from '../firebase/firebase.service';
import { OtpService } from '../otp/otp.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { MailService } from '../mail/mail.service';
import { User } from '@prisma/client';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly userRepository: UserRepository,
    private readonly firebaseService: FirebaseService,
    private readonly otpService: OtpService,
    private readonly mailService: MailService,
  ) {}

  async register(registerDto: RegisterDto): Promise<User> {
    const { name, email, password, role } = registerDto;

    // Check if email already registered in DB
    const existing = await this.userRepository.findByEmail(email);
    if (existing) {
      throw new BadRequestException('Email address is already registered.');
    }

    let uid = `mock_uid_${Math.random().toString(36).substring(7)}`;

    // Create user in Firebase Auth if Admin SDK is initialized
    if (this.firebaseService.isInitialized()) {
      try {
        const firebaseUser = await this.firebaseService.getAuth().createUser({
          email,
          password,
          displayName: name,
        });
        uid = firebaseUser.uid;
        this.logger.log(`Created Firebase user credential: ${email} (${uid})`);
      } catch (error: any) {
        throw new BadRequestException(`Firebase registration error: ${error.message}`);
      }
    } else {
      this.logger.warn(`Running in Mock Mode. Created mock user ID: ${uid}`);
    }

    // Determine role (case-insensitive checks, email manager@gmail.com is manager)
    let finalRole = 'member';
    if (email.toLowerCase() === 'manager@gmail.com') {
      finalRole = 'manager';
    } else if (role) {
      finalRole = role.toLowerCase() === 'manager' ? 'manager' : 'member';
    }

    // Save profile to database
    return this.userRepository.create({
      id: uid,
      name,
      email: email.toLowerCase(),
      role: finalRole,
      avatarUrl: null,
      isActive: true,
    });
  }

  async login(loginDto: LoginDto): Promise<User> {
    const { email } = loginDto;
    const user = await this.userRepository.findByEmail(email.toLowerCase());
    if (!user) {
      throw new NotFoundException('Account not found in database.');
    }
    return user;
  }

  async sendOtp(sendOtpDto: SendOtpDto): Promise<void> {
    const { email } = sendOtpDto;
    const user = await this.userRepository.findByEmail(email.toLowerCase());

    if (!user) {
      throw new BadRequestException('Email address is not registered in the system.');
    }

    // Generate OTP
    const rawOtp = await this.otpService.generateOtp(user.email, user.id);

    // Send email
    await this.mailService.sendOtpEmail(user.email, rawOtp);
  }

  async verifyOtp(verifyOtpDto: VerifyOtpDto): Promise<boolean> {
    const { email, otp } = verifyOtpDto;
    return this.otpService.verifyOtp(email.toLowerCase(), otp);
  }

  async resetPassword(resetPasswordDto: ResetPasswordDto): Promise<void> {
    const { email, otp, newPassword } = resetPasswordDto;

    // Verify OTP first
    const isValid = await this.otpService.verifyOtp(email.toLowerCase(), otp);
    if (!isValid) {
      throw new BadRequestException('Invalid or unverified OTP code.');
    }

    const user = await this.userRepository.findByEmail(email.toLowerCase());
    if (!user) {
      throw new NotFoundException('Account profile not found.');
    }

    // Update password in Firebase Auth if Admin SDK is initialized
    if (this.firebaseService.isInitialized()) {
      try {
        await this.firebaseService.getAuth().updateUser(user.id, {
          password: newPassword,
        });
        this.logger.log(`Password reset successfully in Firebase for: ${email}`);
      } catch (error: any) {
        throw new BadRequestException(`Firebase password update failed: ${error.message}`);
      }
    } else {
      this.logger.warn(`Running in Mock Mode. Simulated password reset in Firebase for: ${email}`);
    }

    // Invalidate/Mark OTP completed
    await this.otpService.markOtpCompleted(email.toLowerCase());
  }
}
