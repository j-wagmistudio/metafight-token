# Metafight Token ERC20

## Spécifications : 
- Créer un jeton à 100 millions d'unités pour le jeu metafight.
- Une partie des jetons est achetable lors de phases de ventes successives
- Les jetons achetés lors de phases de ventes sont soumis à des périodes de vesting linéaire avec cliff. Ces périodes sont différentes en fonction de la phase de vente/airdrop.
- Les jetons bloqués par une période de vesting doivent apparaitre dans la balance de l'utilisateur
- Le système de vesting doit être générique et paramétrable pour pouvoir se raccorder à d'autres smart contract ou wallets qui géreront les différentes phases de vente/airdrop.

## Installation :
- **npm install** pour récupérer les smarts contracts des dépendances.
- **npx hardhat compile** pour générer les binaires des smart contracts


## Smart contracts :
- **MetafightToken.sol** : smart contract du jeton ERC20
- **IMetafightToken.sol** : interface pour permettre à un autre contrat de transférer des tokens avec ou sans periode de vesting
- **MetafightSeller.sol** : exemple simple de contrat de distribution de tokens
