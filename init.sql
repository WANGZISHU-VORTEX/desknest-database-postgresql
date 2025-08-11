-- PostGIS拡張機能の有効化
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. 区域テーブルの作成
CREATE TABLE areas (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- 区域名
    address VARCHAR(255) NOT NULL, -- 詳細住所
    location GEOGRAPHY (POINT) NOT NULL, -- 地理座標
    opening_hours JSONB NOT NULL, -- 営業時間
    price_per_hour DECIMAL(10, 2) NOT NULL, -- 時間単価
    capacity INT NOT NULL, -- 収容可能数
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 地理検索用インデックス
CREATE INDEX idx_areas_location ON areas USING GIST (location);

-- 2. 工位テーブルの作成
CREATE TABLE desks (
    id SERIAL PRIMARY KEY,
    area_id INT NOT NULL REFERENCES areas (id) ON DELETE CASCADE, -- 区域ID
    number VARCHAR(20) NOT NULL, -- デスク番号
    type VARCHAR(50) NOT NULL, -- デスク種別
    status VARCHAR(20) DEFAULT 'available', -- ステータス
    location GEOGRAPHY (POINT), -- 詳細位置
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (area_id, number) -- ユニーク制約
);

-- 3. ユーザーテーブルの作成
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL, -- メールアドレス
    phone VARCHAR(20) UNIQUE, -- 電話番号
    password_hash VARCHAR(255) NOT NULL, -- パスワードハッシュ
    role VARCHAR(20) DEFAULT 'user', -- ユーザーロール
    profile JSONB, -- プロファイル情報
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP -- 最終ログイン
);

-- 4. 予約テーブルの作成
CREATE TABLE reservations (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id) ON DELETE RESTRICT, -- ユーザーID
    desk_id INT NOT NULL REFERENCES desks (id) ON DELETE RESTRICT, -- デスクID
    start_time TIMESTAMP NOT NULL, -- 開始時間
    end_time TIMESTAMP NOT NULL, -- 終了時間
    status VARCHAR(20) NOT NULL, -- 予約状態
    total_price DECIMAL(10, 2) NOT NULL, -- 合計金額
    payment_id INT, -- 支払いID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- 時間重複チェック
    CONSTRAINT check_time_range CHECK (end_time > start_time),
    -- 重複予約防止
    CONSTRAINT unique_desk_time UNIQUE (desk_id, start_time, end_time)
);
-- 検索用インデックス
CREATE INDEX idx_reservations_user ON reservations (user_id);

CREATE INDEX idx_reservations_desk ON reservations (desk_id);

CREATE INDEX idx_reservations_time ON reservations (start_time, end_time);

-- 5. 設備テーブルの作成
CREATE TABLE equipments (
    id SERIAL PRIMARY KEY,
    desk_id INT NOT NULL REFERENCES desks (id) ON DELETE CASCADE, -- デスクID
    type VARCHAR(50) NOT NULL, -- 設備種別
    status VARCHAR(20) DEFAULT 'working', -- 設備状態
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);