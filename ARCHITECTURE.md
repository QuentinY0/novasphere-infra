Décisions d'Architecture - NovaSphere

Choix retenus :
- Multi-environnements par répertoires (envs/dev, envs/prod) : Isolation stricte des states, des variables et des accès IAM.
- Réseau multi-AZ avec module officiel : VPC déployé sur eu-west-3a et eu-west-3b via le registre public.
- Résilence et Haute Disponibilité : Application Load Balancer (ALB) public distribuant le trafic sur un Auto Scaling Group (ASG) avec Launch Template.
- Sécurité des flux : Instances EC2 accessibles uniquement via le Security Group de l'ALB (port 80 restreint).
- Secrets et IAM : Mot de passe stocké sur AWS Systems Manager Parameter Store (SecureString) et lu au runtime par le rôle IAM d'instance (moindre privilège).
- CI/CD : GitHub Actions avec authentification AWS via OIDC (aucun token long terme dans GitHub).

Choix écartés :
- Workspaces Terraform : Rejetés pour l'isolation dev/prod afin d'éviter les erreurs de cible sur les opérations destructives.
- NAT Gateway : Écartée pour optimiser les coûts; les instances sont placées en subnets publics mais protégées par leurs Security Groups.
- Secrets statiques dans le code ou user_data : Proscrits par les règles de sécurité.
