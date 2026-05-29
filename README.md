# Sim-Bora Piauí

MVP de jogo digital 2D educativo sobre patrimônio histórico, cultural e geográfico do Piauí, desenvolvido para a trilha de Tecnologia da Informação da SEDUC-PI. A proposta transforma pontos de memória, paisagens, personagens e saberes locais em uma experiência jogável, com exploração, diálogos, missões e coleção cultural.

O MVP é funcional e validável: pode ser executado no Windows ou aberto pelo projeto-fonte no Godot. O foco desta versão é demonstrar a viabilidade técnica da solução e o valor pedagógico da proposta, sem depender de um produto final completo.

## Links rápidos

- **Repositório:** https://github.com/nt8816/sim-bora-piaui
- **APK Android:** em desenvolvimento
- **Executável Windows:** https://github.com/nt8816/sim-bora-piaui/raw/main/Simbora-Piaui/builds/windows/Sim-Bora-Piaui.exe
- **Projeto Godot:** `Simbora-Piaui/godot/project.godot`

> **Observação:** os arquivos grandes do projeto usam Git LFS. Pelo navegador, os links acima baixam os arquivos diretamente. Ao clonar o repositório, instale o Git LFS e rode `git lfs pull`.

## Equipe

- Érika Tauane
- Joyce Rodrigues
- Tiago Araújo
- Natan Araújo
- Maria Vitória

**Orientador:** Lucas Albuquerque Moura  
**Escola:** CETI Dr. João Carvalho, Dom Expedito Lopes-PI  
**Trilha:** Tecnologia da Informação, SEDUC-PI

---

## Problema

Muitos estudantes conhecem pouco o patrimônio cultural, histórico e geográfico do próprio território. Em geral, esse conteúdo aparece de forma fragmentada, distante da linguagem digital que faz parte do cotidiano dos jovens.

O Sim-Bora Piauí propõe uma forma lúdica de aproximar estudantes da memória local, usando um jogo 2D como ferramenta de aprendizagem, exploração e valorização cultural.

## Solução

O jogador explora uma versão 2D inspirada em Picos-PI, interage com personagens, visita pontos de interesse, registra memórias e cumpre missões educativas. A experiência combina:

- exploração top-down em mapa 2D;
- narrativa com personagens locais;
- missões culturais e educativas;
- quiz e diálogos sobre pontos históricos;
- coleção de memórias desbloqueáveis;
- controles para computador;
- builds exportados para avaliação rápida.

## Conteúdo do MVP

Esta versão demonstra a primeira etapa da jornada:

- tela inicial com identidade visual do projeto;
- introdução narrativa em Picos;
- mapa explorável com praça, ruas, feira, igreja, museu, rio e áreas de memória;
- personagens como Seu Zé, Dona Rita e Ana;
- missões ligadas à cultura, memória, feira, Museu Ozildo Albano, Igreja de Picos e Rio Guaribas;
- sistema de diálogos, respostas e recompensas;
- álbum/coleção cultural;
- suporte a teclado.

> **APK Android:** ainda em desenvolvimento. A exportação para Android está prevista em versões futuras do projeto.

## Tecnologias utilizadas

- Godot Engine 4.6.2
- GDScript
- Git e GitHub
- Git LFS para versionamento dos binários grandes
- Assets 2D próprios e adaptados para o MVP
- Audacity
- LibreSprite
- VS Code
- Prototipagem web (HTML, CSS e JavaScript)

## Como baixar e executar

### Windows

1. Baixe o executável:  
   https://github.com/nt8816/sim-bora-piaui/raw/main/Simbora-Piaui/builds/windows/Sim-Bora-Piaui.exe
2. Abra o arquivo `Sim-Bora-Piaui.exe`.
3. Se o Windows exibir um aviso de segurança por ser um executável baixado da internet, escolha a opção de executar mesmo assim apenas se o arquivo veio deste repositório oficial.

Arquivo no repositório:
```
Simbora-Piaui/builds/windows/Sim-Bora-Piaui.exe
```

### Android

> **Em desenvolvimento.** O APK Android ainda não está disponível para download. Ele será disponibilizado em versão futura do projeto.

### Linux e macOS pelo Godot

Ainda não há build nativo pronto para Linux/macOS neste repositório. Nessas plataformas, a forma recomendada de executar é pelo Godot:

1. Instale o Godot Engine 4.6.2.
2. Clone o repositório:
   ```bash
   git clone https://github.com/nt8816/sim-bora-piaui.git
   cd sim-bora-piaui
   ```
3. Se quiser baixar também os binários grandes versionados no LFS:
   ```bash
   git lfs install
   git lfs pull
   ```
4. Abra o Godot.
5. Clique em **Importar**.
6. Selecione: `Simbora-Piaui/godot/project.godot`
7. Abra a cena principal: `res://scenes/Main.tscn`
8. Pressione **F5** para executar.

### Web / navegador

O repositório também mantém um protótipo web em:

```
Simbora-Piaui/index.html
Simbora-Piaui/game.js
Simbora-Piaui/style.css
```

Esse protótipo serve como referência visual e de experimentação. A versão principal do MVP, para avaliação técnica, é a versão Godot.

## Como jogar

- **Movimentação:** use WASD ou as setas para andar.
- **Interação:** pressione F perto de personagens, locais ou missões.
- **Menu/coleção:** use os botões na interface.
- **Objetivo:** explore Picos, converse com personagens, registre memórias, complete missões e desbloqueie conhecimentos culturais.

## Estrutura do repositório

```
Simbora-Piaui/
  godot/
    project.godot
    scenes/Main.tscn
    scripts/main.gd
    assets/
  builds/
    windows/Sim-Bora-Piaui.exe
    templates/
  index.html
  game.js
  style.css
```

## Arquitetura da solução

```mermaid
flowchart TD
    A[Jogador] --> B[Interface do jogo]
    B --> C[Godot Engine 4.6.2]
    C --> D[Cena principal Main.tscn]
    D --> E[Script principal main.gd]
    E --> F[Sistema de movimento e câmera]
    E --> G[Sistema de missões e diálogos]
    E --> H[Sistema de quiz e recompensas]
    E --> I[Coleção de memórias culturais]
    E --> J[Controles de teclado]
    C --> K[Assets 2D e áudio]
    C --> L[Exportação Windows EXE]
```

## Componentes principais

- **project.godot:** configuração do projeto, mapa de entradas e definições gerais.
- **scenes/Main.tscn:** cena principal carregada pelo Godot.
- **scripts/main.gd:** concentra a lógica do MVP, incluindo mapa, jogador, missões, diálogos, coleção e interface.
- **assets/:** imagens, sprites, texturas e áudio usados no jogo.
- **builds/windows/:** executável Windows pronto para teste.

## Como compilar/exportar

### Rodar pelo editor

```bash
cd Simbora-Piaui/godot
godot --path . --editor
```

No editor, pressione **F5**.

### Exportar Windows

O build entregue para avaliação já está pronto em:
```
Simbora-Piaui/builds/windows/Sim-Bora-Piaui.exe
```

### Exportar Android

> **Em desenvolvimento.** A exportação para Android ainda não está disponível nesta versão do projeto. Quando implementada, serão necessários:
> - Godot Engine 4.6.2
> - Java 17
> - Android SDK instalado
> - Build Tools 35
> - Git LFS, caso o repositório tenha sido clonado sem baixar os binários

## Histórico de commits e contribuições

O repositório foi organizado com commits pequenos para facilitar a avaliação do processo de desenvolvimento. Os commits recentes documentam:

- adição de build Windows;
- adição de arquivos do projeto Godot;
- atualização do README a cada entrega relevante;
- organização dos artefatos de build.

Para avaliação do hackathon, o histórico pode ser consultado com:

```bash
git log --oneline
```

Ou diretamente no GitHub, pela aba **Commits** do repositório.

---

## Observações para avaliadores

Este projeto é um MVP. O objetivo é demonstrar a viabilidade técnica e pedagógica da solução: um jogo 2D capaz de apresentar patrimônio local de forma interativa, executável e validável. A versão atual prioriza Picos-PI como recorte inicial e pode ser expandida para outras cidades, fases, missões e conteúdos culturais do Piauí.

A versão Android está em desenvolvimento e será disponibilizada em etapa futura.
