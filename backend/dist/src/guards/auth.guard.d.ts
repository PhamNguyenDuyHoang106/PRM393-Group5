import { CanActivate, ExecutionContext } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { PrismaService } from '../prisma/prisma.service';
export declare class AuthGuard implements CanActivate {
    private readonly firebaseService;
    private readonly prismaService;
    private readonly logger;
    constructor(firebaseService: FirebaseService, prismaService: PrismaService);
    canActivate(context: ExecutionContext): Promise<boolean>;
}
