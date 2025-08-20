import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import {
  ApiTags,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiExtraModels,
} from '@nestjs/swagger';
import { MarketService } from './market.service';
import { MarketQueryDto, MarketResponseDto } from './dto/market.dto';

@ApiTags('Market Data')
@ApiExtraModels(MarketResponseDto, MarketQueryDto)
@Controller('market')
@UseGuards(ThrottlerGuard)
export class MarketController {
  constructor(private readonly marketService: MarketService) {}

  @Get(':symbol')
  @ApiOperation({
    summary: 'Kripto para market verilerini getirir',
    description: `
      Belirtilen kripto para için detaylı market bilgilerini getirir.
      Veriler CoinGecko ve Alternative.me API'lerinden alınır.

      **Desteklenen semboller:** btc, eth, usdt, bnb, sol, xrp, doge, ada, trx, avax, shib, link, dot, bch, near, matic, ltc, uni, atom ve 90+ kripto para daha...
    `,
  })
  @ApiParam({
    name: 'symbol',
    description: 'Kripto para sembolü (btc, eth, usdt, vb.)',
    example: 'usdt',
    type: String,
  })
  @ApiQuery({
    name: 'fiat',
    description: 'Fiat para birimi',
    required: false,
    enum: ['try', 'usd'],
    example: 'try',
  })
  @ApiResponse({
    status: 200,
    description: 'Başarılı response',
    type: MarketResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Kripto para bulunamadı',
    schema: {
      type: 'object',
      properties: {
        statusCode: { type: 'number', example: 404 },
        timestamp: { type: 'string', example: '2025-08-20T18:51:06.466Z' },
        path: { type: 'string', example: '/market/invalidcoin' },
        method: { type: 'string', example: 'GET' },
        error: { type: 'string', example: 'not_found' },
        message: {
          type: 'string',
          example: "Cryptocurrency 'invalidcoin' not found",
        },
        requestId: {
          type: 'string',
          example: '47196144-0250-4b55-a9a8-5dc38df53797',
        },
      },
    },
  })
  @ApiResponse({
    status: 429,
    description: 'Rate limit aşıldı',
    schema: {
      type: 'object',
      properties: {
        statusCode: { type: 'number', example: 429 },
        message: {
          type: 'string',
          example: 'Rate limit exceeded. Try again later.',
        },
      },
    },
  })
  @ApiResponse({
    status: 502,
    description: 'Upstream API hatası',
    schema: {
      type: 'object',
      properties: {
        statusCode: { type: 'number', example: 502 },
        error: { type: 'string', example: 'upstream_error' },
        message: {
          type: 'string',
          example: 'CoinGecko API error: Request timeout',
        },
      },
    },
  })
  async getMarketCard(
    @Param('symbol') symbol: string,
    @Query() query: MarketQueryDto,
  ): Promise<MarketResponseDto> {
    return this.marketService.getMarketCard(symbol, query.fiat);
  }
}
