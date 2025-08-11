# desknest-database-postgresql セットアップ

## 環境構築手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-repository/desk-booking-system.git
cd desk-booking-system
```

### 2. Gitユーザー設定（初回のみ）

```bash
git config user.name "あなたの名前"
git config user.email "あなたのメールアドレス"
```

### 3. Dockerイメージのビルド

```bash
docker build --no-cache --pull --platform linux/amd64 -t desknest-database-postgresql .
```

### 4. コンテナの実行

```bash
docker run -d \
  --name desknest-database-postgresql \
  -p 5432:5432 \
  -e POSTGRES_DB=desknest_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=DeskNest@2025! \
  desknest-database-postgresql:latest
```

```bash
docker compose -f ddp.yaml up -d
```

### 5. データベース接続情報

- **ホスト**: `localhost`
- **ポート**: `5432`
- **ユーザー**: `postgres`
- **パスワード**: 設定したパスワード
- **データベース**: `postgres`

## データベース構造

- 区域(areas) → 工位(desks) → 設備(equipments)
- ユーザー(users) → 予約(reservations) → 工位(desks)

## 地理空間クエリの例

```sql
-- 指定地点から5km圏内の区域検索
SELECT * FROM areas 
WHERE ST_DWithin(
  location, 
  ST_GeogFromText('POINT(139.6917 35.6895)'), 
  5000
);
```