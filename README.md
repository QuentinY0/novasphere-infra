# NovaSphere Infrastructure (AWS & Terraform)

Projet d automatisation d infrastructure Cloud résiliente, hautement disponible et sécurisée sur AWS, entièrement gérée via Terraform (IaC).

---

## Architecture Globale

- Réseau multi-AZ : VPC avec sous-réseaux publics répartis sur 2 AZs (us-east-1a, us-east-1b) avec Internet Gateway.
- Répartition de charge (ALB) : Application Load Balancer distribuant le trafic HTTP (port 80).
- Auto-Scaling & Résilience (ASG) : ASG gérant une capacité de 2 à 4 instances EC2 Ubuntu via Launch Template.
- Sécurité & Isolation : Filtrage strict par Security Groups (ALB -> EC2 uniquement) et profil IAM LabInstanceProfile.
- Gestion Sécurisée des Secrets : Stockage AWS Systems Manager (SSM) Parameter Store (SecureString) sans fuite dans le tfstate (ephemeral/value_wo).

---

## Structure du Répertoire

novasphere-infra/
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── outputs.tf
│   │   └── bootstrap.sh
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│       └── bootstrap.sh
└── README.md

---

## Guide de Déploiement

### 1. Environnement DEV
cd envs/dev
terraform init && terraform apply -auto-approve

### 2. Environnement PROD
cd ../prod
terraform init && terraform apply -auto-approve

---

## Preuves de Validation & Tests

### 1. Test Load Balancing (ALB)
ALB_PROD_DNS=$(terraform output -raw alb_dns_name)
for i in {1..4}; do curl -s "http://$ALB_PROD_DNS"; echo ""; done

Résultat validé :
NovaSphere - ip-10-0-1-134
NovaSphere - ip-10-0-2-44

### 2. Test Résilience & Self-Healing
Suppression d une instance EC2 en production :
PROD_INSTANCE_TO_KILL=$(aws autoscaling describe-auto-scaling-groups --region us-east-1 --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'novasphere-prod-asg')].Instances[0].InstanceId" --output text)
aws ec2 terminate-instances --instance-ids "$PROD_INSTANCE_TO_KILL" --region us-east-1

Résultat : Le trafic reste disponible et l Auto Scaling recrée immédiatement une nouvelle instance InService / Healthy.

### 3. Audit de Sécurité du State
terraform state pull | grep -c "SecretInitProd"
# Résultat validé : 0 (aucune fuite du mot de passe SSM)

---

## Nettoyage (FinOps)
cd envs/dev && terraform destroy -auto-approve
cd ../prod && terraform destroy -auto-approve
