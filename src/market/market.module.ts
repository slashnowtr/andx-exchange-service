import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { MarketController } from './market.controller';
import { MarketService } from './market.service';
import { CoinGeckoService } from './coingecko.service';
import { FngService } from './fng.service';

@Module({
  imports: [HttpModule],
  controllers: [MarketController],
  providers: [MarketService, CoinGeckoService, FngService],
  exports: [MarketService],
})
export class MarketModule {}
