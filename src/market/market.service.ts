import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { CoinGeckoService } from './coingecko.service';
import { FngService } from './fng.service';
import { resolveId } from './ids';
import { pctChange, firstLastValid } from './utils/math';
import { MarketResponseDto } from './dto/market.dto';

@Injectable()
export class MarketService {
  private readonly logger = new Logger(MarketService.name);

  constructor(
    private readonly coinGeckoService: CoinGeckoService,
    private readonly fngService: FngService,
  ) {}

  async getMarketCard(
    symbol: string,
    fiat: 'try' | 'usd' = 'try',
  ): Promise<MarketResponseDto> {
    const id = resolveId(symbol.toLowerCase());

    this.logger.debug(
      `Processing market card request for symbol: ${symbol}, id: ${id}, fiat: ${fiat}`,
    );

    try {
      // Fetch data in parallel
      const [coin, fearGreedIndex] = await Promise.all([
        this.coinGeckoService.getCoin(id),
        this.fngService.getLatest(),
      ]);

      const market = coin.market_data;
      const links = coin.links;

      // Calculate 90-day change
      let change90d: number | null = null;
      try {
        const rangeData = await this.coinGeckoService.getRange90d(id, 'usd');
        const validPrices = firstLastValid(rangeData?.prices ?? []);
        if (validPrices) {
          change90d = pctChange(validPrices.first, validPrices.last);
        }
      } catch (error) {
        this.logger.warn(`Failed to fetch 90d range for ${id}:`, error);
        // Continue without 90d data
      }

      // Build response
      const response: MarketResponseDto = {
        symbol: symbol.toUpperCase(),
        coin_id: coin.id ?? id,
        rank: coin.market_cap_rank ?? null,
        market_cap_try: market?.market_cap?.try ?? null,
        market_cap_usd: market?.market_cap?.usd ?? null,
        volume_24h_usd: market?.total_volume?.usd ?? null,
        circulating_supply: market?.circulating_supply ?? null,
        change_pct_7d: this.getChangePercentage(market, '7d'),
        change_pct_30d: this.getChangePercentage(market, '30d'),
        change_pct_90d: change90d,
        ath_change_pct_usd: market?.ath_change_percentage?.usd ?? null,
        atl_change_pct_usd: market?.atl_change_percentage?.usd ?? null,
        fear_greed: typeof fearGreedIndex === 'number' ? fearGreedIndex : null,
        links: {
          whitepaper: links?.whitepaper ?? null,
          website: this.getWebsiteUrl(links?.homepage),
          twitter: this.getTwitterUrl(links?.twitter_screen_name),
        },
      };

      this.logger.debug(`Successfully processed market card for ${symbol}`);
      return response;
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(
        `Failed to process market card for ${symbol}:`,
        errorMessage,
      );

      if (errorMessage.includes('404') || errorMessage.includes('not found')) {
        throw new HttpException(
          {
            error: 'not_found',
            message: `Cryptocurrency '${symbol}' not found`,
            symbol,
          },
          HttpStatus.NOT_FOUND,
        );
      }

      throw new HttpException(
        {
          error: 'upstream_error',
          message: errorMessage || 'Failed to fetch market data',
          symbol,
        },
        HttpStatus.BAD_GATEWAY,
      );
    }
  }

  private getChangePercentage(
    marketData: Record<string, unknown>,
    period: '7d' | '30d',
  ): number | null {
    if (!marketData) return null;

    // Try direct field first
    const directField = `price_change_percentage_${period}`;
    const directValue = marketData[directField];
    if (typeof directValue === 'number') {
      return directValue;
    }

    // Try currency-specific field
    const currencyField = `price_change_percentage_${period}_in_currency`;
    const currencyData = marketData[currencyField] as
      | Record<string, unknown>
      | undefined;
    if (currencyData?.usd && typeof currencyData.usd === 'number') {
      return currencyData.usd;
    }

    return null;
  }

  private getWebsiteUrl(homepage: string[] | undefined): string | null {
    if (!Array.isArray(homepage) || homepage.length === 0) {
      return null;
    }

    const validUrl = homepage.find(
      (url) => url && typeof url === 'string' && url.trim().length > 0,
    );
    return validUrl?.trim() ?? null;
  }

  private getTwitterUrl(twitterScreenName: string | undefined): string | null {
    if (!twitterScreenName || typeof twitterScreenName !== 'string') {
      return null;
    }

    const cleanName = twitterScreenName.trim();
    return cleanName ? `https://twitter.com/${cleanName}` : null;
  }
}
