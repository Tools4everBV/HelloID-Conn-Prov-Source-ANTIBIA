# Contributing

Nous accueillons toutes les contributions à ce connecteur HelloID.

## Comment contribuer

1. **Fork** ce dépôt
2. Créez une branche : `git checkout -b feature/ma-amelioration`
3. Committez vos changements : `git commit -m 'Ajout : description du changement'`
4. Poussez la branche : `git push origin feature/ma-amelioration`
5. Ouvrez une **Pull Request**

## Standards de code

- Respecter la structure PowerShell Tools4ever (fonction `Get-SQLData`, gestion d'erreurs, `Write-Information`)
- Toute nouvelle requête SQL doit utiliser des **CTEs** plutôt que des correlated subqueries
- Les paramètres spécifiques au SDIS (matricules exclus, clés hardcodées) doivent être documentés dans le README
- Tester sur un environnement ANTIBIA avant de soumettre

## Signaler un bug

Ouvrez une **Issue** en décrivant :
- La version d'ANTIBIA utilisée
- Le message d'erreur complet (logs HelloID)
- Les étapes pour reproduire le problème
