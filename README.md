# 自分用メモ
## 概要  
JavaフレームワークSpringBoot(gradle)とデータベースを使ったシンプルなWEBアプリのDockerファイルの構成例です。  
これをテンプレにして、ところどころ差し替え/編集後、docker-compose upすることで、webアプリとして動くと思います。 
簡易的に動くことを目的としているので、アプリとして最適化してないです。

**開発環境**  
- 言語：Java  
- フレームワーク：SpringBoot  
- データベース：postgresql 
- ビルドツール：gradle

### 注意
今回ビルドしたファイルは`mybookshelf.war`というファイルになっていますが、各自ビルドしたファイルに読み替えてください。

## 1.ファイルの配置  
```
├── docker-compose.yml
├── forDocker
│   └── db
│       └── initdb　  ↓はテーブル生成用のsqlです　… (A)
│           ├── 1_create_account.sql
│           ├── 2_create_commonBook.sql
│           ├── 3_create_bookshelf.sql
│           ├── 4_create_readPlan.sql
│           ├── 5_create_readRecord.sql
│           └── 6_create_memoComment.sql
└── javaApp
    ├── Dockerfile
    └── mybookshelf.war　   ←はgradleでビルドしたwarファイル  … (B)
```
### A. データベースのテーブル生成のSQL  
./forDocker/db/initdbに、テーブル生成用のSQLを置きます。  
**元あったファイル`1_create_account.sql～6_create_memoComment.sql`は削除してください。**   
ファイル名昇順でSQLが実行されるので、テーブルに外部参照キーを設定している場合はファイル名に注意してください。  
それらが面倒くさい場合、一つのファイルにぜんぶのSQLをまとめてもいいです。  
### B. java実行ファイルの配置  
./javaAppに、gradleでビルドしたファイルを置きます。  
**元あったファイル`mybookshelf.war`は削除してください。**

## 2.docker-compose.ymlの編集

【docker-compose.yml】  
```
version: "2"

services:
  # データボリュームコンテナ
  dbpg-container:
    image: busybox
    volumes:
      - dbpg-volume:/var/lib/postgresql/data
  # データベース
  postgres-container:
    container_name: postgres-container
    image: postgres
    ports:
      - 5432:5432
    environment:
      # データベースの設定(ユーザ名、パスワード、データベース名) …(C)
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=0912
    volumes_from:
      - dbpg-container
    depends_on:
      - dbpg-container
    # 自動的に表を作成するため
    volumes:
      - ./forDocker/db/initdb:/docker-entrypoint-initdb.d
  # javaアプリ
  javaapp-container:
    build: ./javaApp
    ports:
      - 80:8080
    depends_on:
      - postgres-container
    environment:
      # データベースの設定(application.propertiesの内容を書き換えたもの) …(D)
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-container:5432/0912
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=password
volumes:
  dbpg-volume:
```
  
プロジェクトの中の`application.properties`の内容
```
spring.datasource.url=jdbc:postgresql://localhost:5432/0912
spring.datasource.username=postgres
spring.datasource.password=password
```
にあわせて
### C. データベースの設定  
ユーザ名(`POSTGRES_USER`)、パスワード(`POSTGRES_PASSWORD`)、データベース名(`POSTGRES_DB`)の値を差し替えます。`  
### D. データベースの設定  
`SPRING_DATASOURCE_URL`、`SPRING_DATASOURCE_USERNAME`、`SPRING_DATASOURCE_PASSWORD`の値を差し替えます。

但し、　
`jdbc:postgresql://`の次が`localhost`ではなく`postgres-container`になる事を注意してください。  
前：jdbc:postgresql://**localhost**:5432/0912  
↓  
後：jdbc:postgresql://**postgres-container**:5432/0912

## 3. ./javaApp/Dockerfileの編集
```
# ベースイメージの指定
FROM openjdk:17

# ワーキングディレクトリの設定
WORKDIR /app

# アプリケーションのJARファイルをコンテナにコピー
COPY mybookshelf.war app.jar
# ↑  mybookshelf.warという所を、ビルドしたファイルに差し替えてください。  (E)

# ポートの公開
EXPOSE 8080

# アプリケーションの実行コマンド
ENTRYPOINT ["java", "-jar", "app.jar"]
```
### E. ビルドファイルの設定
Dockerファイル内のmybookshelf.war をビルドしたファイル名に差し替えます。

以上です。  
  
参考：こっちみたほうがはやいかも…  
[Running Spring Boot with PostgreSQL in Docker Compose | Baeldung](https://www.baeldung.com/spring-boot-postgresql-docker)  
[docker-compose 下で Java + Spring Boot + PostgreSQL (Spring Data JPA編)](https://zenn.dev/junki555/articles/de2c9844a1d101)  
[SpringBoot + Postgresqlでアプリを作成してみた【CRUD API】 #Docker - Qiita](https://qiita.com/kanfutrooper/items/d5b4ff8cf52d1a29102f)  
[Docker で PostgreSQL 上にデータベースを作成しよう](https://zenn.dev/farstep/books/7acd1a7fee7e18/viewer/43e8ed)  
[SpringBootことはじめ　2.gradleで実行可能なwarファイルを作る #Java - Qiita](https://qiita.com/suganury/items/6e4f1a7fd4e37608a5cc)  
[Gradleとは何者？インストール方法〜使い方までわかりやすく解説￼ | プログラミングを学ぶならトレノキャンプ（TRAINOCAMP）](https://camp.trainocate.co.jp/magazine/about-gradle/)    
[Spring Boot + Gradleでwarファイルを作成する方法 | 株式会社CONFRAGE ITソリューション事業部](https://confrage.jp/spring-boot-gradle%e3%81%a7war%e3%83%95%e3%82%a1%e3%82%a4%e3%83%ab%e3%82%92%e4%bd%9c%e6%88%90%e3%81%99%e3%82%8b%e6%96%b9%e6%b3%95/)    
[SpringBoot+gradleからwarファイルを作成して、Mac環境のTomcatにデプロイする #Java - Qiita](https://qiita.com/ShinPun/items/2e2e646e60f2dada9ede)  
