# 🚀 AndX Exchange Service

<p align="center">
  <img src="https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" alt="NestJS" />
  <img src="https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js" />
</p>

## 📋 Açıklama

AndX Exchange Service, kripto para piyasa verilerini sağlayan modern ve güvenli RESTful API servisidir. CoinGecko ve Alternative.me API'lerini kullanarak gerçek zamanlı market verilerini sunar.

### ✨ Özellikler

- 🔄 **Gerçek Zamanlı Veriler**: CoinGecko API entegrasyonu
- 📊 **Kapsamlı Market Verileri**: Fiyat, hacim, market cap, değişim oranları
- 😨 **Korku & Hırs Endeksi**: Alternative.me API entegrasyonu
- 💱 **Multi-Currency**: TRY ve USD desteği
- ⚡ **Yüksek Performans**: Akıllı önbellekleme sistemi
- 🛡️ **Güvenlik**: Rate limiting, CORS, security headers
- 📝 **Comprehensive Logging**: Request tracking ve error handling
- 🔍 **90+ Kripto Para**: Bitcoin, Ethereum, USDT ve daha fazlası

### 🎯 Desteklenen Metrikler

- Piyasa değeri (TRY/USD)
- 24 saatlik işlem hacmi
- Dolaşımdaki arz, toplam arz, maksimum arz
- 7/30/90 günlük değişim oranları
- ATH/ATL değişim yüzdeleri
- Market cap sıralaması
- Sosyal linkler (Website, Twitter, Whitepaper)

## 🚀 Hızlı Başlangıç

### Kurulum

```bash
# Bağımlılıkları yükle
npm install

# Environment dosyasını oluştur
cp .env.example .env
```

### Çalıştırma

```bash
# Development mode
npm run start:dev

# Production build
npm run build
npm run start:prod

# Debug mode
npm run start:debug
```

### 🔧 Environment Yapılandırması

`.env` dosyasında aşağıdaki değişkenleri ayarlayın:

```env
PORT=3000
COINGECKO_API_KEY=your_api_key_here
ALLOW_ORIGINS=http://localhost:3000,http://localhost:3001
RATE_LIMIT_TTL=60
RATE_LIMIT_LIMIT=60
DEFAULT_CACHE_TTL_MS=60000
```

## 📊 API Kullanımı

### Temel Endpoint'ler

```bash
# USDT market verisi (TRY)
GET http://localhost:3000/market/usdt

# Bitcoin market verisi (USD)
GET http://localhost:3000/market/btc?fiat=usd

# Çoklu market verisi
POST http://localhost:3000/market/bulk
Content-Type: application/json
{
  "symbols": ["btc", "eth", "usdt"],
  "fiat": "try"
}

# Sağlık kontrolü
GET http://localhost:3000/health
```

### Response Örneği

```json
{
  "symbol": "USDT",
  "coin_id": "tether",
  "rank": 4,
  "market_cap_try": 6834785722634,
  "market_cap_usd": 167017182969,
  "volume_24h_usd": 100722116342,
  "circulating_supply": 167010130246.28,
  "total_supply": 167010130246.28,
  "max_supply": null,
  "change_pct_7d": -0.004,
  "change_pct_30d": -0.035,
  "change_pct_90d": -0.016,
  "ath_change_pct_usd": -24.42,
  "atl_change_pct_usd": 74.67,
  "fear_greed": 44,
  "links": {
    "whitepaper": "https://tether.to/wp-content/uploads/2016/06/TetherWhitePaper.pdf",
    "website": "https://tether.to/",
    "twitter": "https://twitter.com/Tether_to"
  }
}
```

## 🧪 Test

```bash
# Unit testler
npm run test

# E2E testler
npm run test:e2e

# Test coverage
npm run test:cov
```

## 📚 Dokümantasyon

### API Dokümantasyonu

- **[API Documentation](./API-DOCUMENTATION.md)** - Detaylı API dokümantasyonu
- **[OpenAPI Spec](./openapi.yaml)** - Swagger/OpenAPI 3.0 spesifikasyonu
- **[Postman Collection](./AndX-Exchange-API.postman_collection.json)** - Test için Postman koleksiyonu

### Desteklenen Kripto Paralar

- Bitcoin (BTC), Ethereum (ETH), Tether (USDT)
- BNB, Solana (SOL), XRP, Dogecoin (DOGE)
- Cardano (ADA), TRON (TRX), Avalanche (AVAX)
- Ve 90+ kripto para daha...

## 🏗️ Mimari

```
src/
├── app.module.ts           # Ana modül
├── main.ts                 # Uygulama giriş noktası
├── common/
│   └── filters/            # Global exception filter
└── market/
    ├── market.module.ts    # Market modülü
    ├── market.controller.ts # REST controller
    ├── market.service.ts   # İş mantığı
    ├── coingecko.service.ts # CoinGecko API client
    ├── fng.service.ts      # Fear & Greed API client
    ├── ids.ts              # Symbol-ID mapping
    ├── dto/                # Data transfer objects
    └── utils/              # Utility fonksiyonlar
```

## 🔒 Güvenlik

- **Rate Limiting**: IP başına 60 istek/dakika
- **CORS**: Yapılandırılabilir origin kontrolü
- **Security Headers**: Helmet middleware
- **Input Validation**: Class-validator ile DTO validation
- **Error Handling**: Güvenli hata mesajları

## 🚀 Deployment

### Docker ile Deployment

```bash
# Docker image oluştur
docker build -t andx-exchange-service .

# Container çalıştır
docker run -p 3000:3000 --env-file .env andx-exchange-service
```

### Production Checklist

- [ ] Environment variables ayarlandı
- [ ] CoinGecko API key alındı
- [ ] Rate limiting yapılandırıldı
- [ ] CORS origins belirlendi
- [ ] Monitoring ve logging aktif
- [ ] Health check endpoint test edildi

## 📞 İletişim

- **Geliştirici**: AndX Tech Team
- **Email**: support@andxtech.com
- **Version**: 1.0.0

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.
