import { OtpRepository } from './otp.repository';
export declare class OtpService {
    private readonly otpRepository;
    private readonly logger;
    constructor(otpRepository: OtpRepository);
    generateOtp(email: string, userId?: string): Promise<string>;
    verifyOtp(email: string, otp: string): Promise<boolean>;
    markOtpCompleted(email: string): Promise<void>;
}
