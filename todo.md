# Lista de Tarefas - Refatoração Projeto Godot

- [x] Analisar estrutura do projeto (concluído ao descompactar)- [x] Confirmar requisitos com o usuário (concluído- [x] Identificar scripts e recursos não utilizados ou duplicados (conservadoramente)- [x] Refatorar código para melhor manutenção (foco em clareza e futuras implementações)
- [x] Analisar e implementar autoloads se necessário
- [x] Verificar integridade do projeto (análise estática, pois não há execução visual)- [x] Criar relatório detalhado das modificações
- [x] Compactar projeto refatorado e entregar ao usuário

## Autoload Singletons (Load Order)

The following scripts are configured as autoload singletons in `Project -> Project Settings -> Autoload`. Their order of loading is important.

1.  **Globals** (`res://scripts/globals.gd`) - Provides global variables and enums.
2.  **Data** (`res://scripts/Data.gd`) - Contains static game data like wave definitions, enemy types, artifact details.
3.  **CardManager** (`res://scripts/CardManager.gd`) - Manages card instances and interactions during gameplay.
4.  **DataManager** (`res://scripts/DataManager.gd`) - Handles saving and loading of game progress, including global player data (Khaos Coins, unlocks) and per-run data.
5.  **ShopManager** (`res://scripts/ShopManager.gd`) - Manages the definitions of items available in the KhaosShop, their costs, and the logic for purchasing unlocks.
