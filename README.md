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
今回ビルドしたファイルは`mybookshelf.jar`というファイルになっていますが、各自ビルドしたファイルに読み替えてください。
ビルドしたファイルはtomcatが同梱されているjarファイルです(```java -jar ビルドファイル```を実行したらWEBアプリが動く状態)。

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
    └── mybookshelf.jar　   ←はgradleでビルドしたjarファイル  … (B)
```
### A. データベースのテーブル生成のSQL  
./forDocker/db/initdbに、テーブル生成用のSQLを置きます。  
**元あったファイル`1_create_account.sql～6_create_memoComment.sql`は削除してください。**   
ファイル名昇順でSQLが実行されるので、テーブルに外部参照キーを設定している場合はファイル名に注意してください。  
それらが面倒くさい場合、一つのファイルにぜんぶのSQLをまとめてもいいです。  
### B. java実行ファイルの配置  
./javaAppに、ビルドしたjarファイルを置きます(私はビルドにgradleを使いました)。  
**元あったファイル`mybookshelf.jar`は削除してください。**

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
COPY mybookshelf.jar app.jar
# ↑  mybookshelf.jarという所を、ビルドしたファイルに差し替えてください。  (E)

# ポートの公開
EXPOSE 8080

# アプリケーションの実行コマンド
ENTRYPOINT ["java", "-jar", "app.jar"]
```
### E. ビルドファイルの設定
Dockerファイル内のmybookshelf.jar をビルドしたファイル名に差し替えます。

以上です。  
  
参考：こっちみたほうがはやいかも…  
[Running Spring Boot with PostgreSQL in Docker Compose | Baeldung](https://www.baeldung.com/spring-boot-postgresql-docker)  
[docker-compose 下で Java + Spring Boot + PostgreSQL (Spring Data JPA編)](https://zenn.dev/junki555/articles/de2c9844a1d101)  
[SpringBoot + Postgresqlでアプリを作成してみた【CRUD API】 #Docker - Qiita](https://qiita.com/kanfutrooper/items/d5b4ff8cf52d1a29102f)  
[Docker で PostgreSQL 上にデータベースを作成しよう](https://zenn.dev/farstep/books/7acd1a7fee7e18/viewer/43e8ed)  
 
### メモ  
**gradleについて**  
私の環境だけかもしれませんが、pleiades環境で```gradle bootJar```を実行したときのビルドに失敗する時、
gradle.buildで指定されているjavaのバージョンと、パスの通っているjava.exeのバージョンがずれていていることが原因かもしれません。  
【エラー内容】  
```
D:\pleiades\2023-09\workspace\hellowork>gradle bootJar
> Task :compileJava FAILED

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileJava'.
> エラー: 21は無効なソース・リリースです

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 2s
1 actionable task: 1 executed
```
【gradle.build】  
gradle.buildには**21**と記載されている。
```
java {
	sourceCompatibility = '21'
}
```
【javaのバージョン確認】  
java --versionの実行は**17**と印字されている。
```
>java --version
openjdk 17.0.8.1 2023-08-24
OpenJDK Runtime Environment Temurin-17.0.8.1+1 (build 17.0.8.1+1)
OpenJDK 64-Bit Server VM Temurin-17.0.8.1+1 (build 17.0.8.1+1, mixed mode, sharing)
```
上記の場合、gradle.buildののjavaのsourceCompatibilityを'17'にするか、
環境変数を変更するなどして、実行するjavaを21のバージョンの実行ファイルにするかしてください。

