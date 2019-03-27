# ibetインフラ構成
## 1. 【全体構成】  

- プロダクション、ステージング用２種類のAWSアカウントが存在する。  
- プロダクション用のAWSアカウント上には、プロダクション環境のみ存在する。  
- ステージング用のAWSアカウントには、ステージング環境、開発環境が存在する。  
- 本来は各社ごとにAWSアカウントを分ける方式(現在RelicはNVC用のAWSアカウント配下に存在)  
- セキュリティ確保のため、各社ごとにVPCを分離。  
- 今回は各環境毎に、NVC用VPCと、コミュニティ用VPCの２種類を用意している。
- 開発環境はアプリケーションの開発環境。1EC2上でDocker Composeを使って起動している。  
- ステージング環境はお客様受け入れ＋NVCの営業用の環境。お客様が自由に試用が可能。  
- プロダクション環境はステージングで受け入れが完了したアプリケーションを可動させる環境。

![](./docs/system_overview_v2.png)


### 1.1. node-api クラスタ
![](./docs/apinode_overview_v2.png)


- iOSアプリ(Wallet)から接続を受け付けるためのクラスタ    
- WAF/Shield、外部ALB、Nginx Proxy、内部ALB、APコンテナ、RDS、SQS、SNS、S3、FireBaseを組み合わせて構成される    


#### 1.1.1 WAF/Shield
- 外部からの不正侵入を抑止するために設置    
- 日本国外からのIPアドレスからのアクセス抑止、単位時間あたりの同一IPからの連続アクセス抑止、SQLインジェクション抑止フィルタを実装    
- 外部ALBにアドインしている    


#### 1.1.2 外部ALB
- nginxを冗長構成するため、かつ、HTTPS→HTTPへ復号化を実施するためにPlublicネットワーク上に設置    
- ドメインはRoute53に格納したNVCのドメイン(api.ibet.jp)を利用  
- 証明書はACMにて作成したAmazon作成の証明書を適用    
- Port443でListenしたものを後ろのnginx Proxyの80番ポートにフォワーディング 
- 背後のnginx proxyが全滅して処理を返せない場合、503エラーとステータスコード999を返却(要確認) 
- アクセスログはS3上に格納している  


#### 1.1.3 nginx Proxy
- DMZに配置し、basic認証機能を搭載することでアクセス制御を実装    
- ECSクラスタ上で可動する  
- AWSのALBが定期的にIPアドレスが変わるため、定期的にキャッシュしたDNSを再読込する機能を実装している  
- ログはCloudwatch logsに出力。    


#### 1.1.4 内部ALB
- APコンテナ、Quorumコンテナを冗長化するために、Privateネットワーク上に設置    
- Port80でListenしたものを後ろのAPコンテナの5000番ポートにフォワーディング 
- Port80でListenしたものを後ろのQuorumコンテナの8443番ポートにフォワーディング 
- ログはCloudwatch logsに出力。    


#### 1.1.5 APコンテナ
- iOSアプリから受け付けるWebAPIと、RDB/Quorumをポーリングして通知を投げるNotificationと、もう一つの３つのコンテナから成り立つ  
- Privateネットワーク上に設置している    
- 基本的にサーバチームが実装、テストしたものをECR経由でコンテナごとリリースする 
- コンテナ部分はUbuntuを利用しており、必要最小限度のライブラリのみ搭載されている。 
- アプリが必要とする定義はタスク定義の環境変数に設定されており、タスク定義を切り替えるだけで各環境で可動する。 
- iOS用のPush通知にApple notification serviceを、Android用のPush通知にFirebaseとSNSを経由して接続をしている。 
- Bankとの連携にSQSを利用している。 
- キャシュ情報やリスティング情報、実行許可コントラクト情報などをRDSに格納。
- アクセス可能な会社のリスト情報などをS3上のWhitelistに格納  
- ログはCloudwatch logsに出力。    


#### 1.1.6 Quorumコンテナ
- 議決権を持たないGeneralノードを配置している  
- 冗長構成をとっており、２つのQuorumコンテナから成り立つ。Act-Act構成だが、切り替えはALBのTargetを明示的に切り替える必要がある。  
- HA構成とせず、手動での切り替えとした理由はQuorumの同期タイミングを考慮したため。１秒以内に切り替えが発生した場合、同期が取られていない情報が見える可能性があるため、自動での切り替えではなく、手動での切り替えとするように設計している。
- Privateネットワーク上に設置している    
- メモリリークが発生していたため、メモリリーク対策を行ったQuorumを格納 
- コンテナ部分はUbuntuを利用しており、必要最小限度のライブラリのみ搭載されている。 
- Quorumが必要とするアドレス情報はタスク定義の環境変数に設定されており、タスク定義を切り替えるだけで各環境で可動する。 
- ログはCloudwatch logsに出力。    


#### 1.1.7 Postgres RDS
- walletからのアクセス要件(24時間365日アクセス)を考慮し、高い可用性を確保するため、RDSを採用。  
- APEC2 上から psqlにてアクセスを行う。  
- ログはCloudwatch logsに出力。    


#### 1.1.8 S3
- アクセス許可を与えられた会社情報及び、エージェントアドレス情報が格納されているリストがある。  


#### 1.1.9 運用
- コンテナ上のCronを使って、定期的にリブートを実施している。  
- バックアップはRDSはマネージドのため不要、アプリケーションはECR上に格納、タスク定義はGithubに格納、Quorumは自動同期のため不要。  
- 監視はディスク、メモリ、CPU等必要最小限の監視のみ実施。  
- リリースはJenkinsにて実装  


### 1.2. satoshi
![](./docs/satoshi_overview_v2.png)


- コミュニティが利用するValicatorを可動させるためのクラスタ    
- ECS上でValidatorとして設定されたQuorumコンテナが4つ稼働している    
  
  
#### 1.2.1 Quorumコンテナ
- Privateネットワーク上に配置    
- ECSクラスタ上で可動する  
- ValidatorとしてBuildされたQuorumコンテナに、Istanbul toolsで発行したキーを付与している  
- ホストEC2上の/home/ubuntu/quorum_data/v[1-4]配下をECSのコンテナからマウントして利用している  
- static-nodes.json,genesis.jsonを配置  
- ログはCloudwatch logsに出力。    


#### 1.2.2 運用
- バックアップはタスク定義はGithubに格納、Quorumは自動同期のため不要。  
- 監視はディスク、メモリ、CPU等必要最小限の監視のみ実施。  
- リリースはJenkinsにて実装  
  
  
  
### 1.3. Issuer クラスタ
![](./docs/Issuer_overview_v2.png)


- PCブラウザ(発行体の端末)から接続を受け付けるためのクラスタ    
- 外部ALB、Nginx Proxy、内部ALB、APコンテナ、RDS、SQS、SNS、S3、FireBaseを組み合わせて構成される    


#### 1.3.1 WAF/Shield
- 発行体クラスタではWAF/Shiledは利用していない。WANから許可されたユーザのみアクセスを行うため、不要  


#### 1.3.2 外部ALB
- nginxを冗長構成するためにPlublicネットワーク上に設置    
- ドメインはAWSがデフォルトで割り当てる名前を利用  
- Port80でListenしたものを後ろのnginx Proxyの80番ポートにフォワーディング 
- アクセスログはS3上に格納している  


#### 1.3.3 nginx Proxy
- Publicネットワークに配置し、basic認証機能を搭載することでアクセス制御を実装    
- ECSクラスタ上で可動する  
- ログはCloudwatch logsに出力。    


#### 1.3.4 内部ALB
- APコンテナ、Quorumコンテナを冗長化するために、Privateネットワーク上に設置    
- Port80でListenしたものを後ろのAPコンテナの5000番ポートにフォワーディング 
- Port80でListenしたものを後ろのQuorumコンテナの8443番ポートにフォワーディング 
- ログはCloudwatch logsに出力。    


#### 1.3.5 APコンテナ
- PCから受け付けるWebAPIをコンテナにて提供している  
- Privateネットワーク上に設置している    
- 基本的にサーバチームが実装、テストしたものをECR経由でコンテナごとリリースする 
- コンテナ部分はUbuntuを利用しており、必要最小限度のライブラリのみ搭載されている。 
- アプリが必要とする定義はタスク定義の環境変数に設定されており、タスク定義を切り替えるだけで各環境で可動する。 
- キャシュ情報やリスティング情報、実行許可コントラクト情報などをRDSに格納。
- 秘密鍵を格納しており、ノード構築時に秘密鍵の作成を行う必要がある    
- ログはCloudwatch logsに出力。    


#### 1.3.6 Quorumコンテナ
- 議決権を持たないGeneralノードを配置している  
- 冗長構成の要件はないため、冗長構成になっていない。ただし、ALBを間に挟んでいるため、要件発生時に冗長構成に変更することは可能  
- Privateネットワーク上に設置している    
- メモリリークが発生していたため、メモリリーク対策を行ったQuorumを格納 
- コンテナ部分はUbuntuを利用しており、必要最小限度のライブラリのみ搭載されている。 
- Quorumが必要とするアドレス情報はタスク定義の環境変数に設定されており、タスク定義を切り替えるだけで各環境で可動する。 
- ログはCloudwatch logsに出力。    


#### 1.3.7 Postgres コンテナ
- 高可用性は不要、かつ、OSSで将来的に提供することを考え、DBはコンテナにて実装  
- APEC2 上から psqlにてアクセスを行う。  
- ログはCloudwatch logsに出力。    


#### 1.3.8 S3
- アクセス許可を与えられた会社情報及び、エージェントアドレス情報が格納されているリストがある。  


#### 1.3.9 運用
- バックアップは必要だが未実装、アプリケーションはECR上に格納、タスク定義はGithubに格納、Quorumは自動同期のため不要。  
- 監視はディスク、メモリ、CPU等必要最小限の監視のみ実施。  
- リリースはJenkinsにて実装  


### 1.4. bank クラスタ
![](./docs/bank_overview_v2.png)


- PCから接続を受け付ける決済代行業者向けのためのクラスタ    
- 外部ALB、Nginx Proxy、内部ALB、APコンテナ、RDS、SQS、SNS、S3、FireBaseを組み合わせて構成される    


#### 1.4.1 WAF/Shield
- BANKクラスタではWAFは利用していない。WAN経由のみのアクセスのため

#### 1.4.2 外部ALB
- nginxを冗長構成するためlublicネットワーク上に設置    
- ドメインはAWSがデフォルトで提供しているものを利用  
- Port80でListenしたものを後ろのnginx Proxyの80番ポートにフォワーディング 
- アクセスログはS3上に格納している  


#### 1.4.3 nginx Proxy
- Publicネットワークに配置し、basic認証機能を搭載することでアクセス制御を実装    
- ECSは利用せず、EC2上でDockerを起動している。
- ログはCloudwatch logsに出力。    


#### 1.4.4 内部ALB
- APコンテナ、Quorumコンテナを冗長化するために、Privateネットワーク上に設置    
- Port80でListenしたものを後ろのAPコンテナの5000番ポートにフォワーディング 
- Port80でListenしたものを後ろのQuorumコンテナの8443番ポートにフォワーディング 
- ログはCloudwatch logsに出力。    


#### 1.4.5 APコンテナ
- PCから処理を受け付けるBANK用アプリコンテナから成り立つ  
- Privateネットワーク上に設置している    
- 基本的にサーバチームが実装、テストしたものをECR経由でコンテナごとリリースする 
- コンテナ部分はUbuntuを利用しており、必要最小限度のライブラリのみ搭載されている。 
- アプリが必要とする定義はタスク定義の環境変数に設定されており、タスク定義を切り替えるだけで各環境で可動する。 
- Nodeとのメッセージ連携にSQSを利用している。 
- キャシュ情報やリスティング情報、実行許可コントラクト情報などをDBに格納。
- アクセス可能な会社のリスト情報などをS3上のWhitelistに格納  
- ログはCloudwatch logsに出力。    


#### 1.4.6 Quorumコンテナ
- 議決権を持たないGeneralノードを配置している  
- 冗長構成無し  
- Privateネットワーク上に設置している    
- メモリリークが発生していたため、メモリリーク対策を行ったQuorumを格納 
- コンテナ部分はUbuntuを利用しており、必要最小限度のライブラリのみ搭載されている。 
- Quorumが必要とするアドレス情報はタスク定義の環境変数に設定されており、タスク定義を切り替えるだけで各環境で可動する。 
- ログはCloudwatch logsに出力。    


#### 1.4.7 Postgres コンテナ
- 高い可用性は不要なため、DBはコンテナにて提供している  
- APEC2 上から psqlにてアクセスを行う。  
- ログはCloudwatch logsに出力。    


#### 1.4.8 S3
- アクセス許可を与えられた会社情報及び、エージェントアドレス情報が格納されているリストがある。  


#### 1.4.9 運用
- バックアップは必要だが未実装、アプリケーションはECR上に格納、タスク定義はGithubに格納、Quorumは自動同期のため不要。  
- 監視はディスク、メモリ、CPU等必要最小限の監視のみ実施。  
- リリースはJenkinsにて実装  



## 2. 【運用】  
運用に必要な情報を記載
### 2.1. アクセス方式  
システムへのアクセス方式を記載する  
  
  
### 2.1.1. HTTP(s)アクセス  
API Node、Bank、Issuerには、HTTP(s)リクエスト経由でアクセス可能。
### 2.1.1.1. API Nodeへのアクセス  
インターネット経由にてアクセス可能  
所定のURLにブラウザにてアクセス後、Basic認証にて認証を行うことでアクセス可能となる  
URLはコンフルエンス上の環境情報を参照   
  
### 2.1.1.2. SATOSHIへのアクセス  
SATOSHIへはHTTP経由でのアクセスは不可  


### 2.1.1.3. Issuerへのアクセス  
NRI Proxy及び、NVCからのみアクセス可能  
所定のURLにブラウザにてアクセス後、Basic認証にて認証を行うことでアクセス可能となる  
URLはコンフルエンス上の環境情報を参照   

### 2.1.1.4. BANKへのアクセス  
NRI Proxy及び、NVCからのみアクセス可能  
所定のURLにブラウザにてアクセス後、Basic認証にて認証を行うことでアクセス可能となる  
URLはコンフルエンス上の環境情報を参照   


### 2.1.2. SSHアクセス  
API Node、SATOSHI、Bank、Issuerには、SSH経由でアクセス可能。
### 2.1.2.1. API Nodeへのアクセス  
NRI ProxyからのみSSHにてアクセス可能 
NRI Proxy→各クラスタのProxyに秘密鍵を用いてSSHログイン後  
更にProxyからPrivate用EC2に秘密鍵を用いてアクセス可能となる  
IPアドレス、秘密鍵はコンフルエンス上の環境情報を参照   
  

### 2.1.2.2. SATOSHIへのアクセス  
NRI ProxyからのみSSHにてアクセス可能 
NRI Proxy→各クラスタのProxyに秘密鍵を用いてSSHログイン後  
更にProxyからPrivate用EC2に秘密鍵を用いてアクセス可能となる  
IPアドレス、秘密鍵はコンフルエンス上の環境情報を参照   
  


### 2.1.2.3. Issuerへのアクセス  
NRI ProxyからのみSSHにてアクセス可能 
NRI Proxy→各クラスタのProxyに秘密鍵を用いてSSHログイン後  
更にProxyからPrivate用EC2に秘密鍵を用いてアクセス可能となる  
IPアドレス、秘密鍵はコンフルエンス上の環境情報を参照   
  
### 2.1.2.4. BANKへのアクセス  
NRI ProxyからのみSSHにてアクセス可能 
NRI Proxy→各クラスタのProxyに秘密鍵を用いてSSHログイン後  
更にProxyからPrivate用EC2に秘密鍵を用いてアクセス可能となる  
IPアドレス、秘密鍵はコンフルエンス上の環境情報を参照   
  

### 2.1.3. psqlアクセス  
API Node、Bank、IssuerクラスタのRDS/DBコンテナにはpsqlを利用してアクセスを行う。


### 2.1.3.1. API Nodeクラスタ上のRDSへのアクセス  
Private上のAPI Noode EC2にアクセス後、下記コマンドにてアクセス  
プロダクションとステージングでDB名が異なるため注意
プロダクション:postgres ステージング:apldb

- プロダクションアクセス例
```
[ec2-user@ip-20-0-10-49 ~]$ ssh -i .ssh/ibet_stg_private.pem ec2-user@20.0.11.29
Last login: Thu Mar  7 06:28:11 2019 from ip-20-0-10-49.ap-northeast-1.compute.internal

   __|  __|  __|
   _|  (   \__ \   Amazon ECS-Optimized Amazon Linux AMI 2018.03.m
 ____|\___|____/

For documentation, visit http://aws.amazon.com/documentation/ecs
[ec2-user@ip-20-0-11-29 ~]$ psql -h apluser.crfopur0vgmv.ap-northeast-1.rds.amazonaws.com -U apluser -d postgres
Password for user apluser:
psql (9.2.24, server 10.4)
WARNING: psql version 9.2, server version 10.0.
         Some psql features might not work.
SSL connection (cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256)
Type "help" for help.

postgres=>
```


### 2.1.3.2. SATOSHIへのアクセス  
SATOSHIはDBが存在しないためアクセス不可



### 2.1.3.3. Issuerへのアクセス  
Private上のIssuer EC2にアクセス後、下記コマンドにてアクセス  
```
docker exec -ti (docker process の ID) psql -h postgres -U postgres  
```


### 2.1.3.4. BANKへのアクセス  
Private上のBank EC2にアクセス後、下記コマンドにてアクセス  
  docker exec -ti (docker process の ID) psql -h postgres -U postgres  

  
### 2.1.4. Quroumアクセス  
API Node、Issuer、BANK、SATOSHI上のQuorumには、Geth経由でアクセス可能。
### 2.1.4.1. API Nodeへのアクセス  
Private上のIssuer EC2にアクセス後、下記コマンドにてアクセス  
```
docker exec -ti (quorumのdocker process id) geth attach /eth/geth.ipc 
```
### 2.1.4.2. SATOSHIへのアクセス  
Private上のSATOSHI EC2にアクセス後、下記コマンドにてアクセス  
```
docker exec -ti (quorumのdocker process id) geth attach /eth/geth.ipc 
```


### 2.1.4.3. Issuerへのアクセス  
Private上のIssuer EC2にアクセス後、下記コマンドにてアクセス  
```
docker exec -ti (quorumのdocker process id) geth attach /eth/geth.ipc 
```

### 2.1.4.4. BANKへのアクセス  
Private上のBANK EC2にアクセス後、下記コマンドにてアクセス  
```
docker exec -ti (quorumのdocker process id) geth attach /eth/geth.ipc 
```



### 2.2. リリース方式  
### 2.3. 監視・通知方式  
### 2.4. リブート方式  
### 2.5. 拡張方式  
### 2.6. Push通知方式  
### 2.7. メッセージ非同期連携方式  
### 2.8. キャッシュ方式  
### 2.9. バックアップ/リストア方式  
### 2.3. 秘密鍵作成方式
```
手順、コマンドを書く
```

## 3. 【その他メモ】  
リスティング方式など、基盤処理ではないが把握しておく必要のある内容、メモを記載しておく
### 3.1. リスティング、実行許可コントラクト指定方式  
### 3.2. 鍵管理方式  
