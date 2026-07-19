import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { FindUserByEmailDto } from './dto/find-user-by-email.dto';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    getMe(user: any): Promise<any>;
    updateProfile(userId: string, updateProfileDto: UpdateProfileDto): Promise<{
        id: string;
        email: string;
        name: string;
        role: string;
        avatarUrl: string | null;
        isActive: boolean;
        updatedAt: Date;
        createdAt: Date;
    }>;
    getUserByEmail(query: FindUserByEmailDto): Promise<{
        id: string;
        email: string;
        name: string;
        role: string;
        avatarUrl: string | null;
        isActive: boolean;
        updatedAt: Date;
        createdAt: Date;
    }>;
    getUserById(id: string): Promise<{
        id: string;
        email: string;
        name: string;
        role: string;
        avatarUrl: string | null;
        isActive: boolean;
        updatedAt: Date;
        createdAt: Date;
    }>;
}
