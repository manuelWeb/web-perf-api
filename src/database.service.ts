import { Injectable, OnApplicationShutdown } from '@nestjs/common';
import { Pool } from 'pg';

@Injectable()
export class DatabaseService extends Pool implements OnApplicationShutdown {
  constructor() {
    super({ connectionTimeoutMillis: 5_000 });
    this.on('error', () => console.error('Idle PostgreSQL connection failed'));
  }

  async onApplicationShutdown(): Promise<void> {
    await this.end();
  }
}
