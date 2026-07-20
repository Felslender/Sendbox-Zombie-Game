# Arquitetura e planejamento

## Fluxo principal

`Main` compõe a cena, inicia o mapa e conecta os sistemas. `NavigationService` mantém uma grade A* compartilhada. `EntityManager` cria e registra agentes no `SpatialIndex`. Cada agente executa percepção e decisão em intervalos com uma pequena defasagem aleatória, enquanto o movimento visual continua no ciclo de física.

As ferramentas do jogador passam pelo `PlacementController`. A infecção é administrada pelo `InfectionSystem`; o combate pertence ao comportamento do policial. O `EvacuationSystem` mantém poucas zonas temporárias e oferece ao civil a zona disponível mais próxima. Barricadas são entidades defensivas registradas no índice espacial e na camada dinâmica do `NavigationService`. Ciclo de vida, remoção e métricas permanecem centralizados no `EntityManager`. A HUD apenas emite intenções e exibe métricas.

## Pastas

- `scenes/`: composição da cena principal.
- `scripts/core/`: configuração, início e eventos da simulação.
- `scripts/world/`: mapa, câmera e navegação.
- `scripts/entities/`: agentes, população e índice espacial.
- `scripts/systems/`: infecção e ferramentas.
- `scripts/ui/`: interface e controles.
- `tests/`: testes de lógica executáveis em modo headless.

## Estados

- Civil: `WANDER`, `IDLE`, `INVESTIGATE`, `FLEE`, `EVACUATING`, `RESCUING`, `INFECTED`, `TRANSFORMING`, `RESCUED`, `REMOVED`.
- Zumbi: `WANDER`, `CHASE`, `ATTACK`, `BREAK_BARRICADE`, `NEUTRALIZED`.
- Policial: `PATROL`, `APPROACH`, `ENGAGE`.

Os estados ficam nos agentes especializados e usam a mesma base de movimento/navegação. O pânico civil é um valor contínuo separado do estado: aumenta com ameaças, propaga-se somente entre vizinhos consultados no índice espacial e decai gradualmente. Civis tranquilos próximos podem seguir um líder estável de menor identificador, evitando ciclos de liderança.

## Desempenho

- O `SpatialIndex` divide o mapa em células de 128 px. Percepção consulta somente células próximas.
- Civis e unidades não percorrem listas globais para escolher alvos.
- Percepção, decisão, atualização do índice e recálculo de rota têm relógios separados.
- Rotas são recalculadas quando o destino muda, ficam obstruídas ou expiram.
- Entidades removidas saem do índice antes de `queue_free`.
- Zonas de evacuação são limitadas a duas; consultá-las tem custo constante e não exige inclusão no índice espacial.
- Obstáculos dinâmicos usam contagem por célula, preservando corretamente paredes estáticas quando uma barricada é removida.
- Agentes invalidam imediatamente o próximo ponto de uma rota quando uma nova barricada ocupa a célula.
- Propagação de pânico e formação de grupos consultam apenas células espaciais vizinhas nos intervalos de decisão.
- O número inicial de civis é configurável em `GameConfig.CIVILIAN_COUNT`.

Gargalos futuros: com várias centenas de unidades, o A* individual e o desenho de cada `Node2D` devem ser medidos. Próximas otimizações naturais são mapas de fluxo para destinos compartilhados, atualização em lotes e renderização via `MultiMesh`.

## Extensão futura

Novos tipos de agente podem herdar de `AgentBase`; novas ferramentas entram no controlador e em um sistema próprio; atributos devem migrar das constantes para recursos `.tres` quando houver conteúdo suficiente. O barramento de sinais desacopla contadores, efeitos e objetivos.

Backlog: tipos de vírus e zumbis, médicos e exército, veículos de extração, edifícios acessíveis, ruído, dia/noite, energia, editor de cenários, salvamento, estatísticas, replay e mods.
