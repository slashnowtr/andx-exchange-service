import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { Cache } from 'cache-manager';
import { Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { firstValueFrom } from 'rxjs';

export interface CoinGeckoResponse {
  id: string;
  symbol: string;
  name: string;
  market_cap_rank: number | null;
  market_data: {
    market_cap: {
      try: number;
      usd: number;
    };
    total_volume: {
      usd: number;
    };
    circulating_supply: number;
    price_change_percentage_7d: number;
    price_change_percentage_30d: number;
    price_change_percentage_7d_in_currency?: {
      usd: number;
    };
    price_change_percentage_30d_in_currency?: {
      usd: number;
    };
    ath_change_percentage: {
      usd: number;
    };
    atl_change_percentage: {
      usd: number;
    };
  };
  links: {
    whitepaper: string;
    homepage: string[];
    twitter_screen_name: string;
  };
}

export interface MarketChartResponse {
  prices: Array<[number, number]>;
}

@Injectable()
export class CoinGeckoService {
  private readonly logger = new Logger(CoinGeckoService.name);
  private readonly baseUrl = 'https://api.coingecko.com/api/v3';

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
  ) {}

  async getCoin(id: string): Promise<CoinGeckoResponse> {
    const cacheKey = `coingecko:coin:${id}`;

    // Check cache first
    const cached = await this.cacheManager.get<CoinGeckoResponse>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache hit for coin: ${id}`);
      return cached;
    }

    try {
      const apiKey = this.configService.get<string>('COINGECKO_API_KEY');
      const headers = apiKey ? { 'x-cg-pro-api-key': apiKey } : {};

      const url = `${this.baseUrl}/coins/${id}`;
      const params = {
        localization: false,
        tickers: false,
        market_data: true,
        community_data: true,
        developer_data: false,
        sparkline: false,
      };

      this.logger.debug(`Fetching coin data for: ${id}`);

      const response = await firstValueFrom(
        this.httpService.get<CoinGeckoResponse>(url, {
          params,
          headers,
          timeout: 8000,
        }),
      );

      const data = response.data;

      // Cache for 60 seconds
      await this.cacheManager.set(cacheKey, data, 60000);

      this.logger.debug(`Successfully fetched and cached coin data for: ${id}`);
      return data;
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to fetch coin data for ${id}:`, errorMessage);
      throw new Error(`CoinGecko API error: ${errorMessage}`);
    }
  }

  async getRange90d(
    id: string,
    vsCurrency = 'usd',
  ): Promise<MarketChartResponse> {
    const cacheKey = `coingecko:range90d:${id}:${vsCurrency}`;

    // Check cache first
    const cached = await this.cacheManager.get<MarketChartResponse>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache hit for 90d range: ${id}`);
      return cached;
    }

    try {
      const apiKey = this.configService.get<string>('COINGECKO_API_KEY');
      const headers = apiKey ? { 'x-cg-pro-api-key': apiKey } : {};

      const now = Math.floor(Date.now() / 1000);
      const from = now - 90 * 24 * 3600; // 90 days ago

      const url = `${this.baseUrl}/coins/${id}/market_chart/range`;
      const params = {
        vs_currency: vsCurrency,
        from: from.toString(),
        to: now.toString(),
      };

      this.logger.debug(`Fetching 90d range data for: ${id}`);

      const response = await firstValueFrom(
        this.httpService.get<MarketChartResponse>(url, {
          params,
          headers,
          timeout: 8000,
        }),
      );

      const data = response.data;

      // Cache for 5 minutes
      await this.cacheManager.set(cacheKey, data, 300000);

      this.logger.debug(
        `Successfully fetched and cached 90d range data for: ${id}`,
      );
      return data;
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(
        `Failed to fetch 90d range data for ${id}:`,
        errorMessage,
      );
      throw new Error(`CoinGecko API error: ${errorMessage}`);
    }
  }
}
