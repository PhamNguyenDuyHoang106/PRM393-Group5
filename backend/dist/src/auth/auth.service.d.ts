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
export declare class AuthService {
    private readonly userRepository;
    private readonly firebaseService;
    private readonly otpService;
    private readonly mailService;
    private readonly logger;
    constructor(userRepository: UserRepository, firebaseService: FirebaseService, otpService: OtpService, mailService: MailService);
    register(registerDto: RegisterDto): Promise<User>;
    login(loginDto: LoginDto): Promise<User>;
    sendOtp(sendOtpDto: SendOtpDto): Promise<void>;
    verifyOtp(verifyOtpDto: VerifyOtpDto): Promise<boolean>;
    resetPassword(resetPasswordDto: ResetPasswordDto): Promise<void>;
}
