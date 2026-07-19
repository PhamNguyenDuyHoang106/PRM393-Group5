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
var FirebaseService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.FirebaseService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const app_1 = require("firebase-admin/app");
const auth_1 = require("firebase-admin/auth");
let FirebaseService = FirebaseService_1 = class FirebaseService {
    configService;
    logger = new common_1.Logger(FirebaseService_1.name);
    firebaseApp = null;
    constructor(configService) {
        this.configService = configService;
    }
    onModuleInit() {
        const projectId = this.configService.get('FIREBASE_PROJECT_ID');
        const clientEmail = this.configService.get('FIREBASE_CLIENT_EMAIL');
        let privateKey = this.configService.get('FIREBASE_PRIVATE_KEY');
        if (!projectId || !clientEmail || !privateKey || privateKey.includes('PLACEHOLDER')) {
            this.logger.warn('Firebase configuration is missing or using placeholder values. Authentication APIs will run in local mock fallback mode.');
            return;
        }
        try {
            privateKey = privateKey.replace(/\\n/g, '\n');
            this.firebaseApp = (0, app_1.initializeApp)({
                credential: (0, app_1.cert)({
                    projectId,
                    clientEmail,
                    privateKey,
                }),
            });
            this.logger.log('Firebase Admin SDK initialized successfully.');
        }
        catch (error) {
            this.logger.error(`Failed to initialize Firebase Admin SDK: ${error.message}`);
        }
    }
    getAuth() {
        if (!this.firebaseApp) {
            throw new Error('Firebase Admin SDK is not initialized.');
        }
        return (0, auth_1.getAuth)(this.firebaseApp);
    }
    isInitialized() {
        return this.firebaseApp != null;
    }
};
exports.FirebaseService = FirebaseService;
exports.FirebaseService = FirebaseService = FirebaseService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], FirebaseService);
//# sourceMappingURL=firebase.service.js.map