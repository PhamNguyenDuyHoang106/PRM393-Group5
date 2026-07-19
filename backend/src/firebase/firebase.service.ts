import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, initializeApp, cert } from 'firebase-admin/app';
import { Auth, getAuth } from 'firebase-admin/auth';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private firebaseApp: App | null = null;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
    let privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKey || privateKey.includes('PLACEHOLDER')) {
      this.logger.warn(
        'Firebase configuration is missing or using placeholder values. Authentication APIs will run in local mock fallback mode.',
      );
      return;
    }

    try {
      // Fix private key formatting if it has escaped newlines
      privateKey = privateKey.replace(/\\n/g, '\n');

      this.firebaseApp = initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
      this.logger.log('Firebase Admin SDK initialized successfully.');
    } catch (error: any) {
      this.logger.error(`Failed to initialize Firebase Admin SDK: ${error.message}`);
    }
  }

  getAuth(): Auth {
    if (!this.firebaseApp) {
      throw new Error('Firebase Admin SDK is not initialized.');
    }
    return getAuth(this.firebaseApp);
  }

  isInitialized(): boolean {
    return this.firebaseApp != null;
  }
}
