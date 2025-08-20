import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { Cache } from 'cache-manager';
import { Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { firstValueFrom } from 'rxjs';

export interface FearGreedResponse {
  data: Array<{
    value: string;
    value_classification: string;
    timestamp: string;
    time_until_update: string;
  }>;
}

@Injectable()
export class FngService {
  private readonly logger = new Logger(FngService.name);
  private readonly baseUrl = 'https://api.alternative.me/fng';

  constructor(
    private readonly httpService: HttpService,
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
  ) {}

  async getLatest(): Promise<number | null> {
    const cacheKey = 'fng:latest';

    // Check cache first
    const cached = await this.cacheManager.get<number>(cacheKey);
    if (cached !== undefined && cached !== null) {
      this.logger.debug('Cache hit for Fear & Greed index');
      return cached;
    }

    try {
      this.logger.debug('Fetching Fear & Greed index from alternative.me');

      const response = await firstValueFrom(
        this.httpService.get<FearGreedResponse>(this.baseUrl, {
          params: { limit: 1 },
          timeout: 8000,
        }),
      );

      const data = response.data;
      const value = Number(data?.data?.[0]?.value);

      if (!Number.isFinite(value)) {
        this.logger.warn('Invalid Fear & Greed value received');
        return null;
      }

      // Cache for 5 minutes
      await this.cacheManager.set(cacheKey, value, 300000);

      this.logger.debug(
        `Successfully fetched and cached Fear & Greed index: ${value}`,
      );
      return value;
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error('Failed to fetch Fear & Greed index:', errorMessage);
      // Return null instead of throwing to allow partial responses
      return null;
    }
  }
}
