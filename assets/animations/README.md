# Quadros de animacao adicionais (opcionais)

A implementacao v0.3 permite animações de PNGs individuais sem alterar o motor de jogo.

Pasta esperada: `assets/animations/<nome-do-sprite>/`

Exemplo:

```
assets/animations/blue_infantry/idle_01.png
assets/animations/blue_infantry/idle_02.png
assets/animations/blue_infantry/walk_01.png
assets/animations/blue_infantry/walk_02.png
assets/animations/blue_infantry/attack_01.png
assets/animations/blue_infantry/attack_02.png
```

Estados opcionais: `idle`, `walk`, `attack`, `death`. Nomes de sprites: `blue_infantry`, `red_infantry`, `blue_tank`, `red_tank`, `blue_turret`, `red_turret`, `explosion`.

Os frames devem ser numerados com 2 digitos (01, 02...) e sem lacunas.
Cada estado percorre ate 64 quadros a 8 FPS. Ausencia de frames usa
imagem estatica existente; o deslocamento minimo e um **placeholder**.

**Importante:** o projeto ainda nao possui os quadros originais nem as suas
tabelas de duracao. Adicionar imagens nao prova fidelidade 1:1.
