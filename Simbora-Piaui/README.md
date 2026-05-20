# Sim-Bora Piauí

MVP jogável inspirado no documento do projeto "SIM-BORA PIAUÍ: Uma jornada lúdica pelo patrimônio histórico, cultural e geográfico do Piauí por meio de um jogo digital 2D".

## Versão principal em Godot

A versão que deve seguir como base do projeto está em `godot/`.

1. Abra o Godot Engine 4.x.
2. Clique em `Importar`.
3. Selecione `godot/project.godot`.
4. Abra a cena `res://scenes/Main.tscn`.
5. Aperte `F5` para jogar.

O projeto já inclui uma base exportável para computador e Android em `godot/export_presets.cfg`. Para Android, ainda será necessário configurar no Godot o SDK/JDK e as credenciais de assinatura.

## Como jogar

- No computador: use `WASD` ou setas para andar.
- Ao chegar perto de uma missão, aparecerá `Pressione F`; aperte `F` para iniciar e ver o objetivo.
- No Android: use o controle virtual na tela e o botão `F`.
- Converse com personagens, leia o objetivo, responda quizzes e colete saberes culturais.

## Conteudo do MVP

- Movimento 2D com câmera semelhante a jogos de aventura top-down.
- Mapa exploravel focado apenas em Picos neste momento, com praca, ruas, feira, rio, igreja, museu e pontos de interesse locais.
- Missoes educativas sobre o Museu Ozildo Albano, Igreja de Picos, Praca Ozildo Albano, Feira de Picos e Rio Guaribas.
- Coleção cultural desbloqueável.
- Interface responsiva para computador e celular.

## Protótipo web

Os arquivos `index.html`, `game.js` e `style.css` permanecem como protótipo rápido em navegador, mas o desenvolvimento oficial deve continuar dentro da pasta `godot/`.
