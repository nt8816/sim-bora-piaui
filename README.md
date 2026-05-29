# Sim-Bora Piauí

MVP de jogo digital 2D educativo sobre patrimônio histórico, cultural e geográfico do Piauí, desenvolvido para a trilha de Tecnologia da Informação da SEDUC-PI.

A proposta transforma pontos de memória, paisagens, personagens e saberes locais em uma experiência jogável, com exploração, diálogos, missões e coleção cultural.

O MVP é funcional e validável. Atualmente pode ser executado no Windows, através do projeto-fonte no Godot e por meio das versões Android em desenvolvimento disponibilizadas para testes. O foco desta versão é demonstrar a viabilidade técnica da solução e o valor pedagógico da proposta.

---

## Links rápidos

* Repositório: https://github.com/nt8816/sim-bora-piaui
* APK Android Godot: versão de testes em desenvolvimento
* Executável Windows: https://github.com/nt8816/sim-bora-piaui/raw/main/Simbora-Piaui/builds/windows/Sim-Bora-Piaui.exe
* Projeto Godot: `Simbora-Piaui/godot/project.godot`

> Observação: os arquivos grandes do projeto utilizam Git LFS. Ao clonar o repositório, instale o Git LFS e execute `git lfs pull`.

---

## Equipe

* Érika Tauane
* Joyce Rodrigues
* Tiago Araújo
* Natan Araújo
* Maria Vitória

**Orientador:** Lucas Albuquerque Moura

**Escola:** CETI Dr. João Carvalho – Dom Expedito Lopes-PI

**Trilha:** Tecnologia da Informação – SEDUC-PI

---

## Problema

Muitos estudantes conhecem pouco o patrimônio cultural, histórico e geográfico do próprio território. Em geral, esse conteúdo aparece de forma fragmentada e distante da linguagem digital presente no cotidiano dos jovens.

O Sim-Bora Piauí propõe uma forma lúdica e interativa de aproximar estudantes da memória local por meio de um jogo digital 2D.

---

## Solução

O jogador explora uma versão inspirada em Picos-PI, interage com personagens, visita pontos de interesse, registra memórias e cumpre missões educativas.

A experiência combina:

* exploração top-down em mapa 2D;
* narrativa com personagens locais;
* missões culturais e educativas;
* quizzes e diálogos sobre pontos históricos;
* coleção de memórias desbloqueáveis;
* controles para computador e Android;
* builds exportados para avaliação rápida.

---

## Conteúdo do MVP

Esta versão demonstra a primeira etapa da jornada:

* tela inicial com identidade visual do projeto;
* introdução narrativa em Picos;
* mapa explorável com praça, ruas, feira, igreja, museu, rio e áreas de memória;
* personagens como Seu Zé, Dona Rita e Ana;
* missões ligadas à cultura, memória, feira, Museu Ozildo Albano, Igreja de Picos e Rio Guaribas;
* sistema de diálogos, respostas e recompensas;
* álbum e coleção cultural;
* suporte a teclado e controle virtual;
* versão Android em fase de desenvolvimento e validação.

---

## Tecnologias Utilizadas

* Godot Engine 4.6.2
* GDScript
* Kotlin
* Android Canvas Nativo
* Gradle / Android Gradle Plugin
* Android SDK
* Java 17
* Git
* GitHub
* Git LFS
* HTML5
* CSS3
* JavaScript
* Audacity
* LibreSprite
* Visual Studio Code

---

## Como Baixar e Executar

### Android

A versão Android do Sim-Bora Piauí encontra-se em desenvolvimento contínuo. Os APKs disponibilizados no repositório correspondem a versões de teste utilizadas durante o processo de implementação, validação e refinamento do MVP.

1. Baixe o APK disponível no repositório.
2. Transfira o arquivo para o dispositivo Android.
3. Autorize a instalação de aplicativos de fontes externas quando solicitado.
4. Instale o APK.
5. Abra o aplicativo Sim-Bora Piauí.

Os APKs disponíveis destinam-se à demonstração técnica do projeto e podem receber atualizações, correções e melhorias ao longo do desenvolvimento.

### Windows

1. Baixe o executável disponível no repositório.
2. Execute o arquivo.
3. Caso o Windows exiba um aviso de segurança, confirme a execução apenas se o arquivo foi obtido do repositório oficial.

### Linux e macOS pelo Godot

1. Instale o Godot Engine 4.6.2.
2. Clone o repositório:

```bash
git clone https://github.com/nt8816/sim-bora-piaui.git
cd sim-bora-piaui
