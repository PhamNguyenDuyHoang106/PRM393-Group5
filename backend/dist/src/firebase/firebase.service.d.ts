import { OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Auth } from 'firebase-admin/auth';
export declare class FirebaseService implements OnModuleInit {
    private configService;
    private readonly logger;
    private firebaseApp;
    constructor(configService: ConfigService);
    onModuleInit(): void;
    getAuth(): Auth;
    isInitialized(): boolean;
}
