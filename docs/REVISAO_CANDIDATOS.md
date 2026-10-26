# Triagem de regiões candidatas — v0.10

Este documento descreve apenas uma **heurística de investigação visual**; não
classifica nenhuma região como sprite ou animação original comprovada.

A detecção base continua sendo componentes 8-conectados dos pixels com alfa
diferente de zero, usando coordenadas exatas dos 67 PNGs recebidos. Componentes
com pelo menos 12 pixels e largura e altura mínimas de 2 pixels geram um
registro `unverified`, até o limite de 256 por atlas.

Para cada caixa `(x, y, w, h, opaque_pixels)`, a prioridade é `low` quando:

- a área da caixa ocupa 82% ou mais da área total do atlas (`atlas_spanning`);
- largura ou altura é inferior a 8 pixels, ou há menos de 24 pixels opacos
  (`tiny_fragment`);
- a relação entre o maior e o menor lado excede 7 (`thin_strip`).

As demais caixas recebem `review` / `local_region`. Não há descarte e a ordem
original de exportação é mantida. Essa triagem pode produzir **falsos negativos**
e **falsos positivos**: um sprite real pode ocupar quase todo o atlas, e um
fragmento pequeno pode ser um ícone ou componente legítimo.

Inventário nesta versão: **178 regiões não verificadas**, distribuídas em:

| Categoria | Regiões |
|---|---:|
| Revisão prioritária | 72 |
| Atlas quase inteiro | 58 |
| Fragmento pequeno | 44 |
| Faixa estreita | 4 |

## Conferência no LÖVE

Abra o inspetor (`F2`), habilite as caixas com `B`, percorra com `N/M` e use
`J` para alternar entre apenas regiões prioritárias e todas. Quando todas
estão visíveis, caixas de baixa prioridade são cinza, as prioritárias são
laranja. O comando `G` ainda adiciona uma região à **prévia não verificada**;
`E` exporta a proposta, sem autorizar sua utilização como animação original.

## Regeneração e verificação

```sh
python3 tools/detect_sprite_candidates.py
python3 tools/detect_sprite_candidates.py --verify
PYTHONPATH=. python3 -m unittest discover -s tests -p '*regression.py'
```

Os 67 arquivos originais continuam imutáveis. Uma publicação só pode chamar
uma animação de `verified` após comparação independente com a execução/JAR
original, não por pontuação heurística.
