# 🚀 AndX Exchange Service API Documentation

## 📋 Genel Bakış

AndX Exchange Service, kripto para piyasa verilerini sağlayan RESTful API servisidir. Gerçek zamanlı market verilerini sunar.

**Base URL:** `http://localhost:3000`

## 🔐 Güvenlik

- **Rate Limiting:** IP başına 60 istek/dakika
- **CORS:** Yapılandırılmış origin'ler için aktif
- **Security Headers:** Helmet middleware ile korunmalı
- **Request ID:** Her istek için benzersiz takip ID'si

## 📊 Endpoint'ler

### 1. Market Verisi

Belirtilen kripto para için detaylı market bilgilerini getirir.

**Endpoint:** `GET /market/{symbol}`

#### Parametreler

| Parametre | Tip    | Zorunlu | Açıklama                                  | Varsayılan |
| --------- | ------ | ------- | ----------------------------------------- | ---------- |
| `symbol`  | string | ✅      | Kripto para sembolü (btc, eth, usdt, vb.) | -          |
| `fiat`    | string | ❌      | Fiat para birimi (try, usd)               | try        |

#### Request Örnekleri

```bash
# USDT verisi (TRY cinsinden)
GET /market/usdt

# Bitcoin verisi (USD cinsinden)
GET /market/btc?fiat=usd

# Ethereum verisi
GET /market/eth
```

#### Response Yapısı

```json
{
  "symbol": "string", // Kripto para sembolü (büyük harf)
  "coin_id": "string", // CoinGecko ID
  "rank": "number|null", // Market cap sıralaması
  "market_cap_try": "number|null", // Piyasa değeri (TRY)
  "market_cap_usd": "number|null", // Piyasa değeri (USD)
  "volume_24h_usd": "number|null", // 24 saatlik hacim (USD)
  "circulating_supply": "number|null", // Dolaşımdaki arz
  "total_supply": "number|null", // Toplam arz
  "max_supply": "number|null", // Maksimum arz
  "change_pct_7d": "number|null", // 7 günlük değişim (%)
  "change_pct_30d": "number|null", // 30 günlük değişim (%)
  "change_pct_90d": "number|null", // 90 günlük değişim (%)
  "ath_change_pct_usd": "number|null", // ATH'den değişim (%)
  "atl_change_pct_usd": "number|null", // ATL'den değişim (%)
  "fear_greed": "number|null", // Korku & Hırs endeksi (0-100)
  "links": {
    "whitepaper": "string|null", // Whitepaper URL
    "website": "string|null", // Resmi website URL
    "twitter": "string|null" // Twitter profil URL
  }
}
```

#### Başarılı Response Örnekleri

**USDT (TRY):**

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

**Bitcoin (USD):**

```json
{
  "symbol": "BTC",
  "coin_id": "bitcoin",
  "rank": 1,
  "market_cap_try": 92562894018804,
  "market_cap_usd": 2262703217539,
  "volume_24h_usd": 45225019762,
  "circulating_supply": 19909075,
  "change_pct_7d": -6.69,
  "change_pct_30d": -3.54,
  "change_pct_90d": 2.14,
  "ath_change_pct_usd": -8.56,
  "atl_change_pct_usd": 167282.97,
  "fear_greed": 44,
  "links": {
    "whitepaper": "https://bitcoin.org/bitcoin.pdf",
    "website": "http://www.bitcoin.org",
    "twitter": "https://twitter.com/bitcoin"
  }
}
```

### 2. Sağlık Kontrolü

API'nin durumunu kontrol eder.

**Endpoint:** `GET /health`

#### Request Örneği

```bash
GET /health
```

#### Response Örneği

```json
{
  "status": "ok",
  "timestamp": "2025-08-20T18:49:31.456Z",
  "uptime": 23.09
}
```

## ❌ Hata Yönetimi

### Hata Response Yapısı

```json
{
  "statusCode": "number", // HTTP status kodu
  "timestamp": "string", // ISO 8601 timestamp
  "path": "string", // İstek path'i
  "method": "string", // HTTP metodu
  "error": "string", // Hata tipi
  "message": "string", // Hata mesajı
  "requestId": "string" // Benzersiz istek ID'si
}
```

### Hata Kodları

| Status Code | Error Type              | Açıklama                   |
| ----------- | ----------------------- | -------------------------- |
| 400         | `bad_request`           | Geçersiz istek parametresi |
| 404         | `not_found`             | Kripto para bulunamadı     |
| 429         | `too_many_requests`     | Rate limit aşıldı          |
| 502         | `upstream_error`        | Upstream API hatası        |
| 500         | `internal_server_error` | Sunucu hatası              |

### Hata Response Örnekleri

**404 - Kripto Para Bulunamadı:**

```json
{
  "statusCode": 404,
  "timestamp": "2025-08-20T18:51:06.466Z",
  "path": "/market/invalidcoin",
  "method": "GET",
  "error": "not_found",
  "message": "Cryptocurrency 'invalidcoin' not found",
  "requestId": "47196144-0250-4b55-a9a8-5dc38df53797"
}
```

**429 - Rate Limit:**

```json
{
  "statusCode": 429,
  "timestamp": "2025-08-20T18:52:15.123Z",
  "path": "/market/btc",
  "method": "GET",
  "error": "too_many_requests",
  "message": "Rate limit exceeded. Try again later.",
  "requestId": "12345678-1234-5678-9abc-123456789012"
}
```

**502 - Upstream Hatası:**

```json
{
  "statusCode": 502,
  "timestamp": "2025-08-20T18:53:20.789Z",
  "path": "/market/eth",
  "method": "GET",
  "error": "upstream_error",
  "message": "CoinGecko API error: Request timeout",
  "requestId": "87654321-4321-8765-cba9-876543210987"
}
```

## 🔧 Desteklenen Kripto Paralar

API aşağıdaki kripto paraları destekler:

### Popüler Kripto Paralar

| Sembol  | Coin ID       | İsim          |
| ------- | ------------- | ------------- |
| `btc`   | bitcoin       | Bitcoin       |
| `eth`   | ethereum      | Ethereum      |
| `usdt`  | tether        | Tether        |
| `bnb`   | binancecoin   | BNB           |
| `sol`   | solana        | Solana        |
| `usdc`  | usd-coin      | USD Coin      |
| `xrp`   | ripple        | XRP           |
| `doge`  | dogecoin      | Dogecoin      |
| `ada`   | cardano       | Cardano       |
| `trx`   | tron          | TRON          |
| `avax`  | avalanche-2   | Avalanche     |
| `shib`  | shiba-inu     | Shiba Inu     |
| `link`  | chainlink     | Chainlink     |
| `dot`   | polkadot      | Polkadot      |
| `bch`   | bitcoin-cash  | Bitcoin Cash  |
| `near`  | near          | NEAR Protocol |
| `matic` | matic-network | Polygon       |
| `ltc`   | litecoin      | Litecoin      |
| `uni`   | uniswap       | Uniswap       |
| `atom`  | cosmos        | Cosmos        |

_Not: Yukarıda listelenmeyen semboller için API otomatik olarak CoinGecko ID çözümlemesi yapar._

## 📈 Veri Kaynakları

### CoinGecko API

- **Market verileri**: Fiyat, hacim, market cap, sıralama
- **Değişim oranları**: 7g, 30g değişim yüzdeleri
- **ATH/ATL verileri**: All-time high/low değişimleri
- **90 günlük veriler**: Tarihsel fiyat verilerinden hesaplanır
- **Sosyal linkler**: Whitepaper, website, Twitter

### Alternative.me API

- **Fear & Greed Index**: 0-100 arası korku ve hırs endeksi
- **Güncellenme**: 5 dakikada bir güncellenir

## ⚡ Performans & Önbellekleme

### Cache Stratejisi

| Veri Tipi         | TTL       | Açıklama                |
| ----------------- | --------- | ----------------------- |
| Market verileri   | 60 saniye | Temel coin bilgileri    |
| 90 günlük veriler | 5 dakika  | Tarihsel fiyat verileri |
| Fear & Greed      | 5 dakika  | Korku & hırs endeksi    |

### Rate Limiting

- **Limit**: 60 istek/dakika/IP
- **Window**: 60 saniye
- **Reset**: Her dakika sıfırlanır

## 🛠️ Geliştirici Notları

### Null Değerler

- API'den gelen bazı alanlar `null` olabilir
- Frontend uygulamaları bu durumu graceful şekilde handle etmelidir
- Eksik veriler için fallback değerler kullanılması önerilir

### Finansal Formatlar

- Tüm para değerleri raw number formatında döner
- Formatlamalar (virgül, para birimi sembolleri) frontend tarafında yapılmalıdır
- Yüzde değerleri decimal formatında döner (örn: 5.25 = %5.25)

### Best Practices

1. **Caching**: Client-side caching kullanarak API çağrılarını minimize edin
2. **Error Handling**: Tüm hata durumlarını handle edin
3. **Rate Limiting**: İstek sıklığınızı kontrol edin
4. **Request ID**: Hata durumlarında `requestId` ile loglama yapın

## 📞 İletişim & Destek

- **Geliştirici**: AndX Tech Team
- **Version**: 1.0.0
- **Last Updated**: 2025-08-20

## 🔄 Changelog

### v1.0.0 (2025-08-20)

- ✅ İlk release
- ✅ Market data endpoint'i
- ✅ Health check endpoint'i
- ✅ Rate limiting
- ✅ Caching sistemi
- ✅ Error handling
- ✅ Multi-currency support (TRY/USD)

```

```
