Terraform で AWS ECS Fargate へ backend と frontend をデプロイするためのコードです。

主なリソース:
- VPC, サブネット, IGW, ルート
- セキュリティグループ（ALB 用 / ECS 用 / Frontend 用 ECS SG）
- Backend 用 ALB, Target Group, Listener（ポート: 80 -> backend）
- Frontend 用 ALB, Target Group, Listener（ポート: 80 -> frontend）
- Backend / Frontend それぞれの ECR リポジトリ
- CloudWatch Logs
- ECS Cluster, Task Definition, Service（Fargate）
- GitHub Actions 用 OIDC Provider と ECR Push 権限の IAM ロール（任意/有効化デフォルト）

前提:
- AWS 認証情報が設定済み（例: AWS_PROFILE もしくは環境変数）
- backend と frontend の Docker イメージを ECR に push できる環境（Docker, AWS CLI）

使い方（例）:
1) 初期化と作成
   - terraform init
   - terraform apply -auto-approve -var "env=dev" \
       -var "image_tag=latest" \
       -var "frontend_image_tag=latest"

2) 出力の確認（ECR URLとALBのDNSなど）
   - terraform output ecr_repository_url            # backend 用
   - terraform output frontend_ecr_repository_url   # frontend 用
   - terraform output alb_dns_name                  # backend 用 ALB
   - terraform output frontend_alb_dns_name         # frontend 用 ALB

3) ECR にログインしてイメージを push（backend）
   - aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com
   - BACKEND_IMAGE_URI=$(terraform output -raw ecr_repository_url)
   - docker build -t backend ../backend
   - docker tag backend:latest ${BACKEND_IMAGE_URI}:latest
   - docker push ${BACKEND_IMAGE_URI}:latest

4) ECR にログインしてイメージを push（frontend）
   - FRONTEND_IMAGE_URI=$(terraform output -raw frontend_ecr_repository_url)
   - docker build -t frontend ../frontend
   - docker tag frontend:latest ${FRONTEND_IMAGE_URI}:latest
   - docker push ${FRONTEND_IMAGE_URI}:latest

5) ECS サービスを更新（image_tag / frontend_image_tag を変更する場合）
   - terraform apply -auto-approve -var "image_tag=latest" -var "frontend_image_tag=latest"

備考:
- デフォルトでは 2 つのパブリックサブネットに Fargate タスクを配置し、ALB 経由で 80 番ポートから到達可能です（backend / frontend それぞれに独立した ALB を作成）。
- ターゲットグループのヘルスチェックは 200–499 を成功とみなすため、ルートパス（/）が 404 を返す場合でも Unhealthy になりません。
- frontend は Nginx (port 80) で静的配信する前提です（frontend/Dockerfile に準拠）。

## GitHub Actions からの ECR Push 用 IAM ロール

本モジュールは GitHub OIDC Provider と、GitHub Actions から Assume できる IAM ロールを作成できます（デフォルトで有効）。

設定手順:
1) 対象の GitHub リポジトリ/ブランチなどに合わせて、`github_oidc_subjects` を設定してください。
   - 例（main ブランチのみ許可）:
     -var 'github_oidc_subjects=["repo:OWNER/REPO:ref:refs/heads/main"]'
   - 例（該当リポジトリの全ての ref を許可）:
     -var 'github_oidc_subjects=["repo:OWNER/REPO:*"]'

2) 適用
   - terraform apply -auto-approve -var 'github_oidc_subjects=["repo:OWNER/REPO:*"]'

3) 出力確認（ロール ARN）
   - terraform output github_actions_role_arn

4) GitHub リポジトリの Secrets に `AWS_ROLE_TO_ASSUME` を登録し、上記 ARN を設定してください。

補足:
- enable_github_oidc=false を指定すると、OIDC/IAM ロールの作成を無効化できます。
- 付与権限は ECR の push に必要な最小限（対象 ECR リポジトリに限定）です。

出力例: ecr_repository_url, alb_dns_name, ecs_cluster_name, ecs_service_name

### 追加の出力（frontend）
- frontend_ecr_repository_url, frontend_alb_dns_name, ecs_frontend_service_name