import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    register(registerDto: RegisterDto): Promise<{
        id: string;
        email: string;
        name: string;
        role: string;
        avatarUrl: string | null;
        isActive: boolean;
        updatedAt: Date;
        createdAt: Date;
    }>;
    login(loginDto: LoginDto): Promise<{
        id: string;
        email: string;
        name: string;
        role: string;
        avatarUrl: string | null;
        isActive: boolean;
        updatedAt: Date;
        createdAt: Date;
    }>;
    sendOtp(sendOtpDto: SendOtpDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyOtp(verifyOtpDto: VerifyOtpDto): Promise<{
        success: boolean;
        message: string;
        valid: boolean;
    }>;
    resetPassword(resetPasswordDto: ResetPasswordDto): Promise<{
        success: boolean;
        message: string;
    }>;
}
