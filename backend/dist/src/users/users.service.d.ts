import { UserRepository } from './users.repository';
import { User } from '@prisma/client';
export declare class UsersService {
    private readonly userRepository;
    constructor(userRepository: UserRepository);
    findById(id: string): Promise<User>;
    findByEmail(email: string): Promise<User>;
    updateProfile(id: string, data: {
        name?: string;
        avatarUrl?: string;
    }): Promise<User>;
}
