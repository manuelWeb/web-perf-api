import { setTimeout } from 'node:timers/promises';
import { Controller, Get, InternalServerErrorException } from '@nestjs/common';

@Controller('apm-demo')
export class ApmDemoController {
  @Get('slow')
  async slow(): Promise<{ delayMs: number }> {
    const delayMs = 300;
    await setTimeout(delayMs);
    return { delayMs };
  }

  @Get('error')
  error(): never {
    throw new InternalServerErrorException('Controlled APM demonstration');
  }
}
