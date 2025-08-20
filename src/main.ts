import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security
  app.use(helmet());

  // CORS
  app.enableCors({
    origin: process.env.ALLOW_ORIGINS?.split(',') || ['http://localhost:3000'],
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Global exception filter
  app.useGlobalFilters(new HttpExceptionFilter());

  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('AndX Exchange Service API')
    .setDescription(
      `
      AndX Exchange Service, kripto para piyasa verilerini sağlayan RESTful API servisidir.
      CoinGecko ve Alternative.me API'lerini kullanarak gerçek zamanlı market verilerini sunar.

      ## Özellikler
      - Gerçek zamanlı kripto para market verileri
      - 90+ kripto para desteği
      - TRY ve USD para birimi desteği
      - Korku & Hırs endeksi
      - Rate limiting ve caching
      - Comprehensive error handling
    `,
    )
    .setVersion('1.0.0')
    .setContact(
      'AndX Tech Team',
      'https://andxtech.com',
      'support@andxtech.com',
    )
    .setLicense('MIT', 'https://opensource.org/licenses/MIT')
    .addTag('Market Data', 'Kripto para market verileri')
    .addTag('Health Check', 'API sağlık kontrolü')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document, {
    customSiteTitle: 'AndX Exchange API',
    customfavIcon: '/favicon.ico',
    customCss: '.swagger-ui .topbar { display: none }',
    swaggerOptions: {
      persistAuthorization: true,
      displayRequestDuration: true,
    },
  });

  await app.listen(process.env.PORT ?? 3000);
}

void bootstrap();
