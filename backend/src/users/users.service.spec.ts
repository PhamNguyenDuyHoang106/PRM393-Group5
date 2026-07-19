import { NotFoundException } from '@nestjs/common';
import { User } from '@prisma/client';
import { UserRepository } from './users.repository';
import { UsersService } from './users.service';

describe('UsersService', () => {
  const findByEmail = jest.fn<Promise<User | null>, [string]>();
  const repository = { findByEmail } as unknown as UserRepository;
  const service = new UsersService(repository);

  beforeEach(() => {
    findByEmail.mockReset();
  });

  it('normalizes the email before looking up the account', async () => {
    const user = {
      id: 'member-1',
      name: 'Member One',
      email: 'member@example.com',
      role: 'member',
      avatarUrl: null,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    } satisfies User;
    findByEmail.mockResolvedValue(user);

    await expect(service.findByEmail('  MEMBER@EXAMPLE.COM  ')).resolves.toBe(
      user,
    );
    expect(findByEmail).toHaveBeenCalledWith('member@example.com');
  });

  it('rejects an email that does not belong to an account', async () => {
    findByEmail.mockResolvedValue(null);

    await expect(service.findByEmail('missing@example.com')).rejects.toThrow(
      NotFoundException,
    );
  });
});
