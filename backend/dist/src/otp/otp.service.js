"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var OtpService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OtpService = void 0;
const common_1 = require("@nestjs/common");
const otp_repository_1 = require("./otp.repository");
const bcrypt = __importStar(require("bcrypt"));
let OtpService = OtpService_1 = class OtpService {
    otpRepository;
    logger = new common_1.Logger(OtpService_1.name);
    constructor(otpRepository) {
        this.otpRepository = otpRepository;
    }
    async generateOtp(email, userId) {
        const latest = await this.otpRepository.findLatestByEmail(email);
        const now = new Date();
        if (latest && latest.lockedUntil && latest.lockedUntil > now) {
            const minutesLeft = Math.ceil((latest.lockedUntil.getTime() - now.getTime()) / 60000);
            throw new common_1.BadRequestException(`Verification is temporarily locked due to too many failed attempts. Try again in ${minutesLeft} minutes.`);
        }
        const rawOtp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpHash = await bcrypt.hash(rawOtp, 10);
        const expiresAt = new Date(now.getTime() + 5 * 60000);
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
    async verifyOtp(email, otp) {
        const latest = await this.otpRepository.findLatestByEmail(email);
        const now = new Date();
        if (!latest) {
            throw new common_1.BadRequestException('No verification OTP request found for this email.');
        }
        if (latest.lockedUntil && latest.lockedUntil > now) {
            const minutesLeft = Math.ceil((latest.lockedUntil.getTime() - now.getTime()) / 60000);
            throw new common_1.BadRequestException(`Verification is locked. Try again in ${minutesLeft} minutes.`);
        }
        if (latest.resetCompleted || latest.verified) {
            throw new common_1.BadRequestException('This OTP code has already been verified or completed.');
        }
        if (latest.expiresAt < now) {
            throw new common_1.BadRequestException('Verification OTP code has expired.');
        }
        if (latest.attemptCount >= 5) {
            const lockedUntil = new Date(now.getTime() + 10 * 60000);
            await this.otpRepository.update(latest.id, { lockedUntil });
            throw new common_1.BadRequestException('Maximum verification attempts exceeded. Account verification locked for 10 minutes.');
        }
        const isMatch = await bcrypt.compare(otp, latest.otpHash);
        if (isMatch) {
            await this.otpRepository.update(latest.id, {
                verified: true,
                attemptCount: 0,
                lastAttempt: now,
            });
            return true;
        }
        else {
            const newAttempts = latest.attemptCount + 1;
            const updateData = {
                attemptCount: newAttempts,
                lastAttempt: now,
            };
            if (newAttempts >= 5) {
                updateData.lockedUntil = new Date(now.getTime() + 10 * 60000);
            }
            await this.otpRepository.update(latest.id, updateData);
            if (newAttempts >= 5) {
                throw new common_1.BadRequestException('Invalid OTP code. Maximum attempts reached. Account verification locked for 10 minutes.');
            }
            else {
                throw new common_1.BadRequestException(`Invalid OTP code. Attempts remaining: ${5 - newAttempts}.`);
            }
        }
    }
    async markOtpCompleted(email) {
        const latest = await this.otpRepository.findLatestByEmail(email);
        if (latest) {
            await this.otpRepository.update(latest.id, {
                resetCompleted: true,
            });
        }
    }
};
exports.OtpService = OtpService;
exports.OtpService = OtpService = OtpService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [otp_repository_1.OtpRepository])
], OtpService);
//# sourceMappingURL=otp.service.js.map