# Zona Zero

Sandbox 2D de apocalipse zumbi para PC. O jogador observa uma cidade autônoma, espalha uma infecção e posiciona forças de defesa. O MVP usa arte vetorial gerada em tempo real, portanto não exige assets externos.

## Tecnologia

O projeto usa **Godot 4.6+ com GDScript**. Godot foi escolhido por oferecer um fluxo maduro para jogos 2D, cenas e recursos reutilizáveis, interface integrada, navegação extensível e exportação direta para Windows. GDScript mantém a iteração simples para um projeto solo e evita uma cadeia adicional de compilação.

## Escopo do MVP

- mapa manual de 1600 × 960 com ruas, calçadas, parques e edifícios;
- câmera com teclado, arrasto e zoom;
- 40 civis autônomos com estados de passeio, espera, reação, fuga, incubação e transformação;
- gás infeccioso com prévia, duração, chance, incubação e recarga;
- zumbis que vagam, percebem, perseguem e infectam civis;
- policiais posicionáveis que patrulham, mantêm distância e neutralizam zumbis;
- zonas de evacuação que atraem civis saudáveis e contabilizam resgates;
- barricadas giráveis que bloqueiam rotas e podem ser destruídas por zumbis;
- pânico que se espalha localmente e formação leve de grupos civis;
- contadores, relógio, pausa, velocidades 1×/2×/4× e reinício;
- índice espacial e decisões em intervalos para evitar buscas globais a cada quadro.

## Executar

1. Instale o [Godot 4.6 ou superior](https://godotengine.org/download/windows/).
2. Importe `project.godot` no Project Manager.
3. Abra o projeto e pressione **F6/F5**, ou execute:

   ```powershell
   godot --path .
   ```

Selecione uma ferramenta nos painéis laterais e clique no mapa: **Gás infeccioso** espalha a infecção, **Policial** posiciona uma unidade autônoma, **Zona de evacuação** cria uma área temporária com capacidade para dez civis e **Barricada** bloqueia fisicamente uma rota.

Controles:

- `WASD` ou setas: mover a câmera;
- botão do meio + arrasto: mover a câmera;
- roda do mouse: zoom;
- clique esquerdo: usar a ferramenta selecionada;
- `Esc`: cancelar a ferramenta;
- `Q`: girar a prévia da barricada;
- `Espaço`: pausar/continuar;
- `1`, `2`, `4`: velocidade da simulação;
- `R`: reiniciar.

## Testes

Os testes de lógica não dependem de interface:

```powershell
godot --headless --path . --script res://tests/test_runner.gd
```

O teste integrado executa a cena real e verifica barricadas, pânico, grupos, evacuação, transformação e combate:

```powershell
godot --headless --path . --script res://tests/integration_runner.gd
```

Para validar que todas as cenas e scripts carregam:

```powershell
godot --headless --path . --editor --quit
```

Uma captura de fumaça visual também pode ser produzida (requer driver gráfico, portanto sem `--headless`):

```powershell
godot --path . --script res://tests/visual_capture.gd
```

Ela será salva na pasta de dados do usuário do projeto, informada no terminal.

## Versão atual

**0.3 — Contenção e Pânico:** adiciona barricadas com navegação dinâmica e destruição por zumbis, propagação local de pânico, agrupamento civil e indicadores na interface.

## Arquitetura

Consulte [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para a separação dos sistemas, decisões de desempenho e pontos de extensão.

## Licença e assets

Código sob a licença MIT. O MVP não usa arquivos visuais ou sonoros externos; mapa, unidades e efeitos são desenhados pelo próprio jogo.
