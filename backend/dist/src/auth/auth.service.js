"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var AuthService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const users_repository_1 = require("../users/users.repository");
const firebase_service_1 = require("../firebase/firebase.service");
const otp_service_1 = require("../otp/otp.service");
const mail_service_1 = require("../mail/mail.service");
let AuthService = AuthService_1 = class AuthService {
    userRepository;
    firebaseService;
    otpService;
    mailService;
    logger = new common_1.Logger(AuthService_1.name);
    constructor(userRepository, firebaseService, otpService, mailService) {
        this.userRepository = userRepository;
        this.firebaseService = firebaseService;
        this.otpService = otpService;
        this.mailService = mailService;
    }
    async register(registerDto) {
        const { name, email, password, role } = registerDto;
        const existing = await this.userRepository.findByEmail(email);
        if (existing) {
            throw new common_1.BadRequestException('Email address is already registered.');
        }
        let uid = `mock_uid_${Math.random().toString(36).substring(7)}`;
        if (this.firebaseService.isInitialized()) {
            try {
                const firebaseUser = await this.firebaseService.getAuth().createUser({
                    email,
                    password,
                    displayName: name,
                });
                uid = firebaseUser.uid;
                this.logger.log(`Created Firebase user credential: ${email} (${uid})`);
            }
            catch (error) {
                throw new common_1.BadRequestException(`Firebase registration error: ${error.message}`);
            }
        }
        else {
            this.logger.warn(`Running in Mock Mode. Created mock user ID: ${uid}`);
        }
        let finalRole = 'member';
        if (email.toLowerCase() === 'manager@gmail.com') {
            finalRole = 'manager';
        }
        else if (role) {
            finalRole = role.toLowerCase() === 'manager' ? 'manager' : 'member';
        }
        return this.userRepository.create({
            id: uid,
            name,
            email: email.toLowerCase(),
            role: finalRole,
            avatarUrl: null,
            isActive: true,
        });
    }
    async login(loginDto) {
        const { email } = loginDto;
        const user = await this.userRepository.findByEmail(email.toLowerCase());
        if (!user) {
            throw new common_1.NotFoundException('Account not found in database.');
        }
        return user;
    }
    async sendOtp(sendOtpDto) {
        const { email } = sendOtpDto;
        const user = await this.userRepository.findByEmail(email.toLowerCase());
        if (!user) {
            throw new common_1.BadRequestException('Email address is not registered in the system.');
        }
        const rawOtp = await this.otpService.generateOtp(user.email, user.id);
        await this.mailService.sendOtpEmail(user.email, rawOtp);
    }
    async verifyOtp(verifyOtpDto) {
        const { email, otp } = verifyOtpDto;
        return this.otpService.verifyOtp(email.toLowerCase(), otp);
    }
    async resetPassword(resetPasswordDto) {
        const { email, newPassword } = resetPasswordDto;
        const user = await this.userRepository.findByEmail(email.toLowerCase());
        if (!user) {
            throw new common_1.NotFoundException('Account profile not found.');
        }
        if (this.firebaseService.isInitialized()) {
            try {
                await this.firebaseService.getAuth().updateUser(user.id, {
                    password: newPassword,
                });
                this.logger.log(`Password reset successfully in Firebase for: ${email}`);
            }
            catch (error) {
                throw new common_1.BadRequestException(`Firebase password update failed: ${error.message}`);
            }
        }
        else {
            this.logger.warn(`Running in Mock Mode. Simulated password reset in Firebase for: ${email}`);
        }
        if (resetPasswordDto.otp) {
            await this.otpService.markOtpCompleted(email.toLowerCase());
        }
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = AuthService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [users_repository_1.UserRepository,
        firebase_service_1.FirebaseService,
        otp_service_1.OtpService,
        mail_service_1.MailService])
], AuthService);
//# sourceMappingURL=auth.service.js.map