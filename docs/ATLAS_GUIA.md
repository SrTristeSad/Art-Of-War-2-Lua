# Atlas originais — referência de engenharia reversa v0.4

## Proveniência e limite do material

O pacote parcial recebido contém 67 PNGs. As cópias em `assets/original/` devem permanecer intactas; `assets/sprites/` contém recortes de protótipo e não substitui o atlas. Não há, no material fornecido, arquivos completos de animação por unidade, tabelas de coordenadas de sprites, os mapas de campanha ou o JAR executável referente ao JAD. Sem a codificação do JAR, as dimensões e composições observadas não determinam qual frame representa qual ação ou sua duração.

`docs/ATLAS_INVENTARIO.csv` registra nome, largura/altura real, bytes e SHA-256 de cada PNG. Para conferir integridade:

```shell
python3 tools/inventory_atlas.py --verify
```

Se adicionar novos PNGs originais, só regenere o catálogo após confirmar sua origem:

```shell
python3 tools/inventory_atlas.py --write
```

## Inspetor dentro do jogo (ambiente de desenvolvimento)

- `F2`: abrir/fechar o inspetor em qualquer tela.
- `←`/`→` ou `A`/`D`: atlas anterior/próximo em ordenação numérica.
- `PageUp`/`PageDown`: recuar/avançar dez atlas. `Home`/`End`: extremos.
- Roda do mouse, `+`/`-`: zoom até 8x sobre o ajuste automático de tela.
- Ponteiro sobre a imagem: coordenadas de pixel baseadas em zero (x,y), para documentar recortes posteriormente.
- Botões inferiores: anterior, restaurar zoom e próximo.
- `Esc`: fecha o inspetor sem acionar pausa/menu do jogo.

O inspetor **pausa a simulação** enquanto está aberto. Sua interface é uma ferramenta técnica e **não é atribuída ao jogo original**. A ampliação usa filtro `nearest`, sem modificar cores e sem gerar animações.

## Próxima coleta de evidências para paridade 1:1

1. Recuperar o `artofwea_S8000.jar` citado no JAD e verificar hash/tamanho.
2. Catalogar o formato real das tabelas de recortes e sequências de frames.
3. Relacionar cada recorte a classe/unidade, estado, direção, posição, duração e condição de transição, citando o trecho de bytecode de origem.
4. Validar cada menu/HUD/cenário em capturas do original e preencher uma matriz de paridade por tela.
5. Substituir os recortes e parâmetros provisórios somente após verificar a equivalência.


## Catálogo de recortes verificados v0.6

Os 21 sprites já utilizados no protótipo foram comparados aos atlas em nível de pixels RGBA. Cada correspondência está em `ATLAS_SPRITES_VERIFICADOS.csv` e `../src/atlas_catalog.lua`, e pode ser revalidada com:

```bash
python3 tools/verify_sprite_provenance.py
```

O renderizador usa Quads LÖVE com esses recortes no jogo, preservando as imagens originais. `F2` mostra os recortes verificados em verde; `V` alterna a visualização. Os CSVs exportados manualmente continuam marcados como `unverified`, e não são carregados automaticamente como imagens do jogo.
