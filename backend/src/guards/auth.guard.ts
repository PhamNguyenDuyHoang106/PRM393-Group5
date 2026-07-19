import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly logger = new Logger(AuthGuard.name);

  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly prismaService: PrismaService,
  ) {}

  private decodeJwtPayload(token: string): any {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      const payload = parts[1];
      const decoded = Buffer.from(payload, 'base64').toString('utf-8');
      return JSON.parse(decoded);
    } catch (_) {
      return null;
    }
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authorization header is missing or invalid.');
    }

    const token = authHeader.split(' ')[1];

    try {
      let decodedToken: { uid: string; email?: string };

      if (!this.firebaseService.isInitialized()) {
        // Fallback for mock environment testing
        this.logger.warn('Running in Mock Mode. Decrypting JWT payload locally without signature verification.');
        const payload = this.decodeJwtPayload(token);
        
        if (payload && payload.email) {
          decodedToken = {
            uid: payload.user_id ?? payload.sub ?? '',
            email: payload.email,
          };
        } else {
          // If token is a simple mock string, default based on mock prefixes
          decodedToken = {
            uid: token.includes('manager') ? 'seed-manager-001' : 'seed-member-001',
            email: token.includes('manager') ? 'manager@gmail.com' : 'member@gmail.com',
          };
        }
      } else {
        decodedToken = await this.firebaseService.getAuth().verifyIdToken(token);
      }

      // Fetch user profile and role from PostgreSQL database
      let user = await this.prismaService.user.findUnique({
        where: { id: decodedToken.uid },
      });

      // Fallback search by email to support seeded profiles with mismatching Firebase UIDs
      if (!user && decodedToken.email) {
        user = await this.prismaService.user.findUnique({
          where: { email: decodedToken.email.toLowerCase() },
        });
      }

      if (!user) {
        throw new UnauthorizedException('User profile not found in database.');
      }

      // Attach user object to request context
      request.user = user;
      return true;
    } catch (error: any) {
      throw new UnauthorizedException(`Invalid credentials: ${error.message}`);
    }
  }
}
