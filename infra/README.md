Terraform で AWS ECS Fargate へ backend をデプロイするためのコードです。

主なリソース:
- VPC, サブネット, IGW, ルート
- セキュリティグループ（ALB 用 / ECS 用）
- ALB, Target Group, Listener
- ECR リポジトリ
- CloudWatch Logs
- ECS Cluster, Task Definition, Service（Fargate）

前提:
- AWS 認証情報が設定済み（例: AWS_PROFILE もしくは環境変数）
- backend の Docker イメージを ECR に push できる環境（Docker, AWS CLI）

使い方（例）:
1) 初期化と作成
   - terraform init
   - terraform apply -auto-approve -var "env=dev" -var "image_tag=latest"

2) 出力の確認（ECR URLとALBのDNSなど）
   - terraform output ecr_repository_url
   - terraform output alb_dns_name

3) ECR にログインしてイメージを push
   - aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com
   - IMAGE_URI=$(terraform output -raw ecr_repository_url)
   - docker build -t backend ../backend
   - docker tag backend:latest ${IMAGE_URI}:latest
   - docker push ${IMAGE_URI}:latest

4) ECS サービスを更新（image_tag を変更する場合）
   - terraform apply -auto-approve -var "image_tag=latest"

備考:
- デフォルトでは 2 つのパブリックサブネットに Fargate タスクを配置し、ALB 経由で 80 番ポートから到達可能です。
- ターゲットグループのヘルスチェックは 200–499 を成功とみなすため、ルートパス（/）が 404 を返す場合でも Unhealthy になりません。

出力例: ecr_repository_url, alb_dns_name, ecs_cluster_name, ecs_service_name