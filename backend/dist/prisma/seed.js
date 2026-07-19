"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const client_1 = require("@prisma/client");
const adapter_pg_1 = require("@prisma/adapter-pg");
const pg_1 = require("pg");
const connectionString = process.env.DIRECT_URL ||
    process.env.DATABASE_URL ||
    'postgresql://postgres:postgres@localhost:5432/smart_task';
const pool = new pg_1.Pool({ connectionString });
const adapter = new adapter_pg_1.PrismaPg(pool);
const prisma = new client_1.PrismaClient({ adapter });
async function main() {
    console.log('🌱 Starting seed...');
    const manager = await prisma.user.upsert({
        where: { email: 'manager@gmail.com' },
        update: {},
        create: {
            id: 'seed-manager-001',
            name: 'Hoang Team Lead',
            email: 'manager@gmail.com',
            role: 'manager',
            isActive: true,
        },
    });
    const member1 = await prisma.user.upsert({
        where: { email: 'member@gmail.com' },
        update: {},
        create: {
            id: 'seed-member-001',
            name: 'Nguyen Member',
            email: 'member@gmail.com',
            role: 'member',
            isActive: true,
        },
    });
    const member2 = await prisma.user.upsert({
        where: { email: 'duy@gmail.com' },
        update: {},
        create: {
            id: 'seed-member-002',
            name: 'Duy Developer',
            email: 'duy@gmail.com',
            role: 'member',
            isActive: true,
        },
    });
    console.log(`✅ Users seeded: ${manager.email}, ${member1.email}, ${member2.email}`);
    const project1 = await prisma.project.upsert({
        where: { id: 'seed-project-001' },
        update: {},
        create: {
            id: 'seed-project-001',
            name: 'Smart Task PRM393',
            description: 'University project — task management application with Flutter + NestJS.',
            ownerId: manager.id,
        },
    });
    const project2 = await prisma.project.upsert({
        where: { id: 'seed-project-002' },
        update: {},
        create: {
            id: 'seed-project-002',
            name: 'Mobile App Backend',
            description: 'REST API backend service for PRM393 mobile application.',
            ownerId: manager.id,
        },
    });
    console.log(`✅ Projects seeded: "${project1.name}", "${project2.name}"`);
    await prisma.projectMember.upsert({
        where: { projectId_userId: { projectId: project1.id, userId: member1.id } },
        update: {},
        create: { projectId: project1.id, userId: member1.id },
    });
    await prisma.projectMember.upsert({
        where: { projectId_userId: { projectId: project1.id, userId: member2.id } },
        update: {},
        create: { projectId: project1.id, userId: member2.id },
    });
    await prisma.projectMember.upsert({
        where: { projectId_userId: { projectId: project2.id, userId: member2.id } },
        update: {},
        create: { projectId: project2.id, userId: member2.id },
    });
    console.log('✅ Project members seeded');
    const tasks = [
        {
            id: 'seed-task-001',
            projectId: project1.id,
            title: 'Setup Flutter project structure',
            description: 'Initialize Flutter app with Riverpod, GoRouter, SQLite, and Firebase.',
            priority: 'HIGH',
            status: 'DONE',
            assignedTo: member1.id,
            dueDate: new Date('2026-07-10'),
        },
        {
            id: 'seed-task-002',
            projectId: project1.id,
            title: 'Implement Login & Register screens',
            description: 'Build Login and Register UI with Firebase Auth integration.',
            priority: 'HIGH',
            status: 'DONE',
            assignedTo: member1.id,
            dueDate: new Date('2026-07-12'),
        },
        {
            id: 'seed-task-003',
            projectId: project1.id,
            title: 'Implement Forgot Password OTP flow',
            description: '3-step OTP flow: Send Email → Verify OTP → Reset Password.',
            priority: 'HIGH',
            status: 'DONE',
            assignedTo: member2.id,
            dueDate: new Date('2026-07-15'),
        },
        {
            id: 'seed-task-004',
            projectId: project2.id,
            title: 'Setup NestJS backend with Prisma',
            description: 'Initialize NestJS project with Prisma, PostgreSQL, Swagger, and Firebase Admin.',
            priority: 'HIGH',
            status: 'DONE',
            assignedTo: member2.id,
            dueDate: new Date('2026-07-16'),
        },
        {
            id: 'seed-task-005',
            projectId: project2.id,
            title: 'Implement Auth API endpoints',
            description: 'Register, Login, Send OTP, Verify OTP, Reset Password endpoints.',
            priority: 'HIGH',
            status: 'IN_PROGRESS',
            assignedTo: member2.id,
            dueDate: new Date('2026-07-20'),
        },
        {
            id: 'seed-task-006',
            projectId: project1.id,
            title: 'Build Dashboard screens (Manager & Member)',
            description: 'Role-based dashboard with statistics charts for managers and task list for members.',
            priority: 'MEDIUM',
            status: 'IN_PROGRESS',
            assignedTo: member1.id,
            dueDate: new Date('2026-07-22'),
        },
        {
            id: 'seed-task-007',
            projectId: project2.id,
            title: 'Implement Project & Task API',
            description: 'CRUD endpoints for projects and tasks with RBAC guards.',
            priority: 'MEDIUM',
            status: 'TODO',
            assignedTo: null,
            dueDate: new Date('2026-07-25'),
        },
        {
            id: 'seed-task-008',
            projectId: project2.id,
            title: 'Implement Notification system',
            description: 'Auto-create notifications on task assignment, status change, and project events.',
            priority: 'LOW',
            status: 'TODO',
            assignedTo: null,
            dueDate: new Date('2026-07-28'),
        },
    ];
    for (const task of tasks) {
        await prisma.task.upsert({
            where: { id: task.id },
            update: {},
            create: task,
        });
    }
    console.log(`✅ ${tasks.length} Tasks seeded`);
    await prisma.notification.create({
        data: {
            userId: member1.id,
            title: 'Welcome to Smart Task!',
            message: 'You have been added to the project "Smart Task PRM393".',
            type: 'PROJECT_CREATED',
            createdBy: manager.id,
        },
    });
    await prisma.notification.create({
        data: {
            userId: member2.id,
            title: 'Task Assigned',
            message: 'You have been assigned to "Implement Forgot Password OTP flow".',
            type: 'TASK_ASSIGNED',
            createdBy: manager.id,
        },
    });
    console.log('✅ Notifications seeded');
    console.log('\n🎉 Seed completed successfully!');
    console.log('━'.repeat(50));
    console.log(`  Users:         3  (1 manager, 2 members)`);
    console.log(`  Projects:      2`);
    console.log(`  Tasks:         ${tasks.length}  (4 DONE, 2 IN_PROGRESS, 2 TODO)`);
    console.log(`  Notifications: 2`);
    console.log('━'.repeat(50));
    console.log('\nDemo accounts (password set via Firebase Auth, not here):');
    console.log('  Manager → manager@gmail.com');
    console.log('  Member  → member@gmail.com');
}
main()
    .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=seed.js.map