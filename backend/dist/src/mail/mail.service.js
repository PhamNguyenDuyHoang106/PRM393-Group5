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
var MailService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.MailService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const nodemailer = __importStar(require("nodemailer"));
let MailService = MailService_1 = class MailService {
    configService;
    logger = new common_1.Logger(MailService_1.name);
    transporter = null;
    constructor(configService) {
        this.configService = configService;
        const user = this.configService.get('EMAIL_USER');
        const pass = this.configService.get('EMAIL_PASS');
        if (!user || !pass || user.includes('demo') || pass.includes('demo')) {
            this.logger.warn('Email credentials not configured. Outgoing emails will be logged directly to the console/debug logs.');
            return;
        }
        try {
            this.transporter = nodemailer.createTransport({
                host: 'smtp-relay.brevo.com',
                port: 587,
                secure: false,
                auth: {
                    user,
                    pass,
                },
            });
            this.logger.log('SMTP Mail transporter configured successfully.');
        }
        catch (error) {
            this.logger.error(`SMTP Transporter configuration error: ${error.message}`);
        }
    }
    async sendOtpEmail(to, otp) {
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
                from: `"Smart Task Management" <${this.configService.get('EMAIL_USER')}>`,
                to,
                subject,
                text,
                html,
            });
            this.logger.log(`OTP Email sent successfully to ${to}`);
        }
        catch (error) {
            this.logger.error(`Failed to send OTP Email to ${to}: ${error.message}`);
            this.logger.log(`\n[FALLBACK CONSOLE MAIL] OTP to: ${to} -> OTP Code: ${otp}\n`);
        }
    }
};
exports.MailService = MailService;
exports.MailService = MailService = MailService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], MailService);
//# sourceMappingURL=mail.service.js.map