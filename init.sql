-- PostGIS拡張機能の有効化（地理情報処理のため）
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. エリアテーブル（施設全体の情報を管理）
CREATE TABLE areas (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- エリア名（事務所名・施設名）
    address VARCHAR(255) NOT NULL, -- 所在地の詳細住所
    location GEOGRAPHY (POINT) NOT NULL, -- 緯度経度による位置情報
    opening_hours JSONB NOT NULL, -- 営業時間（曜日別の時間帯をJSON形式で保存）
    price_per_hour DECIMAL(10, 2) NOT NULL, -- 1時間あたりの基本利用料金
    capacity INT NOT NULL, -- 総収容可能人数
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- レコード作成日時
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- レコード更新日時
);
-- 地理情報による検索効率化のためのインデックス
CREATE INDEX idx_areas_location ON areas USING GIST (location);

-- 2. デスクテーブル（個々のワークスペースを管理）
CREATE TABLE desks (
    id SERIAL PRIMARY KEY,
    area_id INT NOT NULL REFERENCES areas (id) ON DELETE CASCADE, -- 所属するエリアID
    number VARCHAR(20) NOT NULL, -- デスク番号（識別用）
    type VARCHAR(50) NOT NULL, -- デスク種別（通常席・会議用・個室等）
    status VARCHAR(20) DEFAULT 'available', -- 利用可能状態（available:利用可、reserved:予約中、maintenance:メンテナンス中）
    location GEOGRAPHY (POINT), -- エリア内での詳細位置（任意）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- レコード作成日時
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- レコード更新日時
    UNIQUE (area_id, number) -- 同一エリア内でのデスク番号重複防止
);

-- 3. ユーザーテーブル（利用者情報を管理）
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL, -- ログイン用メールアドレス（ユニーク制約）
    phone VARCHAR(20) UNIQUE, -- 連絡先電話番号（任意）
    password_hash VARCHAR(255) NOT NULL, -- パスワードのハッシュ値（平文保存禁止）
    role VARCHAR(20) DEFAULT 'user', -- ユーザー権限（user:一般利用者、admin:管理者）
    profile JSONB, -- プロフィール情報（氏名・会社名等、可変項目をJSONで保存）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 会員登録日時
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 情報更新日時
    last_login_at TIMESTAMP -- 最終ログイン日時（セキュリティ監視用）
);

-- 4. 予約テーブル（デスクの予約情報を管理）
CREATE TABLE reservations (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id) ON DELETE RESTRICT, -- 予約者ID（削除制限）
    desk_id INT NOT NULL REFERENCES desks (id) ON DELETE RESTRICT, -- 予約デスクID（削除制限）
    start_time TIMESTAMP NOT NULL, -- 利用開始日時
    end_time TIMESTAMP NOT NULL, -- 利用終了日時
    status VARCHAR(20) NOT NULL, -- 予約状態（pending:未確定、confirmed:確定、cancelled:キャンセル）
    total_price DECIMAL(10, 2) NOT NULL, -- 合計料金（利用時間×単価）
    payment_id INT, -- 支払いID（決済システムとの連携用）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 予約作成日時
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 予約情報更新日時
    -- 終了時間が開始時間より後であることを確認
    CONSTRAINT check_time_range CHECK (end_time > start_time),
    -- 同一デスクの時間帯重複予約を防止
    CONSTRAINT unique_desk_time UNIQUE (desk_id, start_time, end_time)
);
-- ユーザー別の予約検索用インデックス
CREATE INDEX idx_reservations_user ON reservations (user_id);

-- デスク別の予約検索用インデックス
CREATE INDEX idx_reservations_desk ON reservations (desk_id);

-- 時間帯による空き状況検索用インデックス
CREATE INDEX idx_reservations_time ON reservations (start_time, end_time);

-- 5. 設備テーブル（各デスクに配置された設備を管理）
CREATE TABLE equipments (
    id SERIAL PRIMARY KEY,
    desk_id INT NOT NULL REFERENCES desks (id) ON DELETE CASCADE, -- 設置されたデスクID
    type VARCHAR(50) NOT NULL, -- 設備種別（モニター・プリンター・充電スタンド等）
    status VARCHAR(20) DEFAULT 'working', -- 設備状態（working:正常、broken:故障、maintenance:修理中）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 設置日時
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- 状態更新日時
);