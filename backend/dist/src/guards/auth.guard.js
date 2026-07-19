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
var AuthGuard_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthGuard = void 0;
const common_1 = require("@nestjs/common");
const firebase_service_1 = require("../firebase/firebase.service");
const prisma_service_1 = require("../prisma/prisma.service");
let AuthGuard = AuthGuard_1 = class AuthGuard {
    firebaseService;
    prismaService;
    logger = new common_1.Logger(AuthGuard_1.name);
    constructor(firebaseService, prismaService) {
        this.firebaseService = firebaseService;
        this.prismaService = prismaService;
    }
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new common_1.UnauthorizedException('Authorization header is missing or invalid.');
        }
        const token = authHeader.split(' ')[1];
        try {
            let decodedToken;
            if (!this.firebaseService.isInitialized()) {
                this.logger.warn('Running in Mock Mode. Bypassing Firebase Admin SDK verification.');
                decodedToken = {
                    uid: token.includes('manager') ? 'manager_uid' : 'member_uid',
                    email: token.includes('manager') ? 'manager@gmail.com' : 'member@gmail.com',
                };
            }
            else {
                decodedToken = await this.firebaseService.getAuth().verifyIdToken(token);
            }
            const user = await this.prismaService.user.findUnique({
                where: { id: decodedToken.uid },
            });
            if (!user) {
                throw new common_1.UnauthorizedException('User profile not found in database.');
            }
            request.user = user;
            return true;
        }
        catch (error) {
            throw new common_1.UnauthorizedException(`Invalid credentials: ${error.message}`);
        }
    }
};
exports.AuthGuard = AuthGuard;
exports.AuthGuard = AuthGuard = AuthGuard_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [firebase_service_1.FirebaseService,
        prisma_service_1.PrismaService])
], AuthGuard);
//# sourceMappingURL=auth.guard.js.map