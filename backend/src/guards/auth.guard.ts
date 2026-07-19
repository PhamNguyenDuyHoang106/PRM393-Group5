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
        this.logger.warn('Running in Mock Mode. Bypassing Firebase Admin SDK verification.');
        decodedToken = {
          uid: token.includes('manager') ? 'manager_uid' : 'member_uid',
          email: token.includes('manager') ? 'manager@gmail.com' : 'member@gmail.com',
        };
      } else {
        decodedToken = await this.firebaseService.getAuth().verifyIdToken(token);
      }

      // Fetch user profile and role from PostgreSQL database
      const user = await this.prismaService.user.findUnique({
        where: { id: decodedToken.uid },
      });

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
