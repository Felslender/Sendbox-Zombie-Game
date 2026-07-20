# Histórico de versões

## 0.3 — Contenção e Pânico

- ferramenta Barricada no painel de Defesa, com rotação pela tecla `Q`;
- até oito barricadas simultâneas, cada uma com vida configurável;
- células A* bloqueadas e liberadas dinamicamente sem afetar obstáculos estáticos;
- zumbis detectam, atacam e destroem barricadas próximas;
- pânico aumenta diante do perigo, modifica movimento e tempo de espera;
- pânico se espalha somente entre civis próximos por meio do índice espacial;
- civis tranquilos próximos formam pequenos grupos sem ciclos de liderança;
- medidores de pânico global, recarga e quantidade de barricadas;
- testes de bloqueio dinâmico, destruição, propagação social e agrupamento.

## 0.2 — Operação Resgate

- ferramenta Zona de Evacuação no painel de Defesa;
- no máximo duas zonas simultâneas, com duração e capacidade configuráveis;
- civis saudáveis procuram a zona disponível mais próxima;
- estados separados de deslocamento e embarque;
- infecção durante o embarque cancela o resgate;
- perigo continua tendo prioridade sobre a evacuação durante o deslocamento;
- contador de resgatados conectado ao ciclo real da simulação;
- cobertura integrada de evacuação, infecção, transformação e combate.

## 0.1 — MVP

- mapa e câmera;
- civis autônomos, fuga e navegação;
- gás infeccioso, incubação e zumbis;
- policiais e combate;
- HUD, métricas, velocidades e reinício.
