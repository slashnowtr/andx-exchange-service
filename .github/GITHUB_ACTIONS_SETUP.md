# 🚀 GitHub Actions CI/CD Setup Guide

Bu dokümantasyon AndX Exchange Service için GitHub Actions CI/CD pipeline'ının kurulumunu açıklar.

## 📋 Gerekli GitHub Secrets

GitHub repository'nizde aşağıdaki secrets'ları tanımlamanız gerekiyor:

### AWS Credentials
```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=eu-west-1
AWS_ACCOUNT_ID=123456789012
```

### Service URLs
```
SERVICE_URL=https://your-production-domain.com
STAGING_SERVICE_URL=https://staging.your-domain.com
PRODUCTION_SERVICE_URL=https://your-production-domain.com
```

### API Keys (Optional - for CodeCov)
```
CODECOV_TOKEN=your-codecov-token
```

## 🏗️ AWS Infrastructure Kurulumu

### 1. ECR Repository Oluşturma
```bash
aws ecr create-repository \
  --repository-name andx-exchange-service \
  --image-scanning-configuration scanOnPush=true
```

### 2. ECS Cluster Oluşturma
```bash
# Production cluster
aws ecs create-cluster \
  --cluster-name andx-cluster \
  --capacity-providers FARGATE

# Staging cluster
aws ecs create-cluster \
  --cluster-name andx-cluster-staging \
  --capacity-providers FARGATE
```

### 3. IAM Roles Oluşturma

**ECS Task Execution Role:**
```bash
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### 4. Secrets Manager Setup
```bash
# Production API key
aws secretsmanager create-secret \
  --name andx-exchange/coingecko-api-key \
  --secret-string "YOUR_COINGECKO_API_KEY"

# Staging API key
aws secretsmanager create-secret \
  --name andx-exchange/staging/coingecko-api-key \
  --secret-string "YOUR_STAGING_API_KEY"
```

## 🔄 Workflow'lar

### 1. CI Pipeline (`ci.yml`)
- **Trigger:** Push/PR to main/develop
- **İşlemler:**
  - Code quality checks (ESLint, Prettier)
  - Unit ve E2E testler
  - Security scanning (npm audit, CodeQL)
  - Docker image build ve ECR push

### 2. CD Pipeline (`cd.yml`)
- **Trigger:** CI başarılı olduktan sonra (main branch)
- **İşlemler:**
  - Production'a deployment
  - Health check
  - Deployment notification

### 3. Staging Deployment (`staging.yml`)
- **Trigger:** Push to develop branch
- **İşlemler:**
  - Staging environment'a deployment
  - Smoke tests
  - Staging notification

### 4. Release Management (`release.yml`)
- **Trigger:** Git tag push (v*)
- **İşlemler:**
  - GitHub release oluşturma
  - Changelog generation
  - Production deployment
  - Release notification

### 5. Infrastructure Management (`infrastructure.yml`)
- **Trigger:** Manual (workflow_dispatch)
- **İşlemler:**
  - AWS infrastructure setup
  - ECR, ECS, IAM resources
  - Secrets Manager setup

## 🔧 Task Definition Dosyaları

### Production (`task-definition.json`)
- CPU: 256, Memory: 512MB
- Fargate deployment
- Production environment variables
- CloudWatch logging

### Staging (`task-definition-staging.json`)
- CPU: 256, Memory: 512MB
- Staging-specific configuration
- Separate log groups

## 📝 Kullanım Adımları

### 1. İlk Kurulum
```bash
# 1. GitHub secrets'ları ekleyin
# 2. AWS infrastructure'ı oluşturun
gh workflow run infrastructure.yml -f action=apply -f environment=staging

# 3. Task definition dosyalarını güncelleyin (ACCOUNT_ID, REGION)
```

### 2. Development Workflow
```bash
# Feature branch'te çalışın
git checkout -b feature/new-feature

# Değişikliklerinizi yapın
git add .
git commit -m "feat: new feature"

# PR oluşturun - CI otomatik çalışacak
git push origin feature/new-feature
```

### 3. Staging Deployment
```bash
# Develop branch'e merge edin
git checkout develop
git merge feature/new-feature
git push origin develop
# Staging deployment otomatik başlayacak
```

### 4. Production Release
```bash
# Main branch'e merge edin
git checkout main
git merge develop

# Tag oluşturun
git tag v1.0.0
git push origin v1.0.0
# Release workflow otomatik başlayacak
```

## 🔍 Monitoring ve Debugging

### CloudWatch Logs
```bash
# Production logs
aws logs tail /ecs/andx-exchange-service --follow

# Staging logs
aws logs tail /ecs/andx-exchange-service-staging --follow
```

### ECS Service Status
```bash
# Production service
aws ecs describe-services \
  --cluster andx-cluster \
  --services andx-exchange-service

# Staging service
aws ecs describe-services \
  --cluster andx-cluster-staging \
  --services andx-exchange-service-staging
```

## 🛡️ Güvenlik Best Practices

1. **Secrets Management:** Tüm sensitive data AWS Secrets Manager'da
2. **IAM Permissions:** Minimum required permissions
3. **Image Scanning:** ECR ve Trivy ile vulnerability scanning
4. **Environment Separation:** Production ve staging ayrı cluster'lar
5. **Access Control:** GitHub environments ile deployment approval

## 🚨 Troubleshooting

### Common Issues

1. **ECR Login Failed:**
   - AWS credentials'ları kontrol edin
   - ECR repository'nin var olduğundan emin olun

2. **ECS Deployment Failed:**
   - Task definition'ı kontrol edin
   - CloudWatch logs'ları inceleyin
   - Health check endpoint'ini test edin

3. **Health Check Failed:**
   - Service'in başlatılma süresini kontrol edin
   - Port mapping'leri doğrulayın
   - Environment variables'ları kontrol edin

Bu setup ile tam otomatik CI/CD pipeline'ınız hazır! 🎉
