Conventions d'équipe

- Une branche par fonctionnalité / correctif.
- Plan Terraform systématiquement relu sur la pull request avant tout merge.
- Tags Git posés à chaque jalon (ex: v5.1.0, v5.7.0, v5.9.0).
- .gitignore strict interdisant le commit de fichiers .tfstate, .tfvars, .pem, et clés AWS.
- Déploiement dev automatique au merge sur main; déploiement prod manuel sous validation.
- Destruction des ressources après chaque session de travail.
