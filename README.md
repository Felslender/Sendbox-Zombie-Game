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
- contadores, relógio, pausa, velocidades 1×/2×/4× e reinício;
- índice espacial e decisões em intervalos para evitar buscas globais a cada quadro.

## Executar

1. Instale o [Godot 4.6 ou superior](https://godotengine.org/download/windows/).
2. Importe `project.godot` no Project Manager.
3. Abra o projeto e pressione **F6/F5**, ou execute:

   ```powershell
   godot --path .
   ```

Controles:

- `WASD` ou setas: mover a câmera;
- botão do meio + arrasto: mover a câmera;
- roda do mouse: zoom;
- clique esquerdo: usar a ferramenta selecionada;
- `Esc`: cancelar a ferramenta;
- `Espaço`: pausar/continuar;
- `1`, `2`, `4`: velocidade da simulação;
- `R`: reiniciar.

## Testes

Os testes de lógica não dependem de interface:

```powershell
godot --headless --path . --script res://tests/test_runner.gd
```

Para validar que todas as cenas e scripts carregam:

```powershell
godot --headless --path . --editor --quit
```

## Arquitetura

Consulte [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para a separação dos sistemas, decisões de desempenho e pontos de extensão.

## Licença e assets

Código sob a licença MIT. O MVP não usa arquivos visuais ou sonoros externos; mapa, unidades e efeitos são desenhados pelo próprio jogo.
