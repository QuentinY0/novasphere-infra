Rapport et Hygiène de Sécurité - NovaSphere

Analyse des vecteurs de fuite traités :
1. Code source : Variables sensibles marquées ephemeral = true, mot de passe injecté via Parameter Store.
2. Terraform State : Utilisation d'arguments en écriture seule (value_wo) pour empêcher la persistance du secret dans le state.
3. User Data : Le mot de passe n'est pas passé dans bootstrap.sh; l'instance le récupère dynamiquement via SSM Parameter Store.
4. Logs et CI : Authentification OIDC sans clés d'API AWS permanentes dans les secrets du dépôt.

Politiques IAM et moindre privilège :
- Le rôle IAM d'instance autorise strictement l'action ssm:GetParameter sur le chemin /novasphere/dev/*.
- Toute tentative de lecture d'un secret hors de son environnement (ex: /novasphere/prod/*) est refusée avec AccessDeniedException.

Scan statique Checkov :
- Scan exécuté via checkov -d envs/dev --framework terraform.
- Validations passées sur les règles critiques IAM et Security Groups.
