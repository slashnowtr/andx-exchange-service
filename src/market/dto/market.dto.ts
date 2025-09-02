import {
  IsOptional,
  IsIn,
  IsArray,
  ArrayMinSize,
  IsString,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class MarketQueryDto {
  @ApiProperty({
    description: 'Fiat para birimi',
    enum: ['try', 'usd'],
    default: 'try',
    example: 'try',
    required: false,
  })
  @IsOptional()
  @IsIn(['try', 'usd'])
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase() : value,
  )
  fiat?: 'try' | 'usd' = 'try';
}

export class MarketLinksDto {
  @ApiProperty({
    description: 'Whitepaper URL',
    example:
      'https://tether.to/wp-content/uploads/2016/06/TetherWhitePaper.pdf',
    nullable: true,
  })
  whitepaper: string | null;

  @ApiProperty({
    description: 'Resmi website URL',
    example: 'https://tether.to/',
    nullable: true,
  })
  website: string | null;

  @ApiProperty({
    description: 'Twitter profil URL',
    example: 'https://twitter.com/Tether_to',
    nullable: true,
  })
  twitter: string | null;
}

export class MarketResponseDto {
  @ApiProperty({
    description: 'Kripto para sembolü (büyük harf)',
    example: 'USDT',
  })
  symbol: string;

  @ApiProperty({
    description: 'CoinGecko ID',
    example: 'tether',
  })
  coin_id: string;

  @ApiProperty({
    description: 'Market cap sıralaması',
    example: 4,
    nullable: true,
  })
  rank: number | null;

  @ApiProperty({
    description: 'Piyasa değeri (TRY)',
    example: 6834785722634,
    nullable: true,
  })
  market_cap_try: number | null;

  @ApiProperty({
    description: 'Piyasa değeri (USD)',
    example: 167017182969,
    nullable: true,
  })
  market_cap_usd: number | null;

  @ApiProperty({
    description: '24 saatlik hacim (USD)',
    example: 100722116342,
    nullable: true,
  })
  volume_24h_usd: number | null;

  @ApiProperty({
    description: 'Dolaşımdaki arz',
    example: 167010130246.28,
    nullable: true,
  })
  circulating_supply: number | null;

  @ApiProperty({
    description: 'Toplam arz',
    example: 167010130246.28,
    nullable: true,
  })
  total_supply: number | null;

  @ApiProperty({
    description: 'Maksimum arz',
    example: 21000000,
    nullable: true,
  })
  max_supply: number | null;

  @ApiProperty({
    description: '7 günlük değişim (%)',
    example: -0.004,
    nullable: true,
  })
  change_pct_7d: number | null;

  @ApiProperty({
    description: '30 günlük değişim (%)',
    example: -0.035,
    nullable: true,
  })
  change_pct_30d: number | null;

  @ApiProperty({
    description: '90 günlük değişim (%)',
    example: -0.016,
    nullable: true,
  })
  change_pct_90d: number | null;

  @ApiProperty({
    description: "ATH'den değişim (%)",
    example: -24.42,
    nullable: true,
  })
  ath_change_pct_usd: number | null;

  @ApiProperty({
    description: "ATL'den değişim (%)",
    example: 74.67,
    nullable: true,
  })
  atl_change_pct_usd: number | null;

  @ApiProperty({
    description: 'Korku & Hırs endeksi (0-100)',
    example: 44,
    nullable: true,
  })
  fear_greed: number | null;

  @ApiProperty({
    description: 'Sosyal linkler',
    type: MarketLinksDto,
  })
  links: MarketLinksDto;
}

export class BulkMarketQueryDto {
  @ApiProperty({
    description: 'Kripto para sembolleri listesi',
    example: ['btc', 'eth', 'usdt'],
    type: [String],
    minItems: 1,
  })
  @IsArray()
  @ArrayMinSize(1, { message: 'Liste boş olamaz, en azından 1 coin olmalı' })
  @IsString({ each: true })
  @Transform(({ value }) =>
    Array.isArray(value)
      ? value.map((v) => (typeof v === 'string' ? v.toLowerCase() : v))
      : value,
  )
  symbols: string[];

  @ApiProperty({
    description: 'Fiat para birimi',
    enum: ['try', 'usd'],
    default: 'try',
    example: 'try',
    required: false,
  })
  @IsOptional()
  @IsIn(['try', 'usd'])
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase() : value,
  )
  fiat?: 'try' | 'usd' = 'try';
}

export class BulkMarketResponseDto {
  @ApiProperty({
    description: 'Market verileri listesi',
    type: [MarketResponseDto],
  })
  data: MarketResponseDto[];

  @ApiProperty({
    description: 'Toplam coin sayısı',
    example: 3,
  })
  count: number;

  @ApiProperty({
    description: 'Başarısız olan coinler',
    example: ['invalidcoin'],
    type: [String],
  })
  failed: string[];
}
