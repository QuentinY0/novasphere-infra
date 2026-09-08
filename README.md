NovaSphere Infrastructure

Projet d'automatisation de l'infrastructure NovaSphere sur AWS via Terraform et GitHub Actions.

Déploiement de zéro :
1. Cloner le dépôt :
   git clone <repo-url> && cd novasphere-infra
2. Configurer les variables d'environnement dans envs/dev/terraform.tfvars :
   owner         = "hyi"
   environment   = "dev"
   instance_type = "t3.micro"
3. Initialiser et déployer via Terraform :
   cd envs/dev
   terraform init
   terraform plan
   terraform apply
4. Valider l'accès web :
   curl http://$(terraform output -raw alb_dns_name)
5. Destruction des ressources :
   terraform destroy
