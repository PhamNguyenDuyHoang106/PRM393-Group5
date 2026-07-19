import { ProjectsService } from './projects.service';
import { CreateProjectDto, UpdateProjectDto, AddMemberDto } from './dto/project.dto';
export declare class ProjectsController {
    private readonly projectsService;
    constructor(projectsService: ProjectsService);
    create(dto: CreateProjectDto, user: any): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    }>;
    findAll(user: any): Promise<({
        owner: {
            id: string;
            email: string;
            name: string;
            role: string;
        };
        members: ({
            user: {
                id: string;
                email: string;
                name: string;
                role: string;
            };
        } & {
            projectId: string;
            userId: string;
        })[];
        _count: {
            tasks: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    })[]>;
    findOne(id: string, user: any): Promise<{
        owner: {
            id: string;
            email: string;
            name: string;
            role: string;
        };
        members: ({
            user: {
                id: string;
                email: string;
                name: string;
                role: string;
            };
        } & {
            projectId: string;
            userId: string;
        })[];
        tasks: {
            id: string;
            updatedAt: Date;
            createdAt: Date;
            description: string | null;
            projectId: string;
            title: string;
            priority: string;
            status: string;
            assignedTo: string | null;
            dueDate: Date | null;
        }[];
        _count: {
            members: number;
            tasks: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    }>;
    update(id: string, dto: UpdateProjectDto, user: any): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    }>;
    delete(id: string, user: any): Promise<void>;
    listMembers(id: string, user: any): Promise<({
        user: {
            id: string;
            email: string;
            name: string;
            role: string;
        };
    } & {
        projectId: string;
        userId: string;
    })[]>;
    addMember(id: string, dto: AddMemberDto, user: any): Promise<{
        projectId: string;
        userId: string;
    }>;
    removeMember(id: string, userId: string, user: any): Promise<void>;
}
