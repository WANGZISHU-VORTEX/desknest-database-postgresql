# ベースイメージの指定 (amd64アーキテクチャ)
FROM postgres:17

# PostGIS拡張機能のインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-17-postgis-3 \
    postgresql-17-postgis-3-scripts \
    && rm -rf /var/lib/apt/lists/*

# 初期化スクリプト用ディレクトリの作成
RUN mkdir -p /docker-entrypoint-initdb.d && \
    chown -R postgres:postgres /docker-entrypoint-initdb.d

# 初期化SQLファイルのコピーと権限設定
COPY init.sql /docker-entrypoint-initdb.d/
RUN chown postgres:postgres /docker-entrypoint-initdb.d/init.sql && \
    chmod 644 /docker-entrypoint-initdb.d/init.sql

# データベースポートの公開
EXPOSE 5432

# エントリーポイントの設定
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]
