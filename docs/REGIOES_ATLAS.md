# Recortes de atlas — ferramenta técnica v0.5

O objetivo deste fluxo é documentar regiões dos **67 PNGs extraídos** sem atribuir a elas, sem provas, nomes de unidades, quadros ou funções que possam não corresponder ao jogo original.

## Marcando uma região

1. Execute o projeto no LÖVE e pressione `F2` (mesmo a partir do menu).
2. Setas esquerda/direita trocam PNG; `PageUp`/`PageDown` pulam dez. Roda do mouse e `+`/`-` mudam zoom.
3. Clique e arraste **dentro da imagem** para selecionar um retângulo. Borda ciano indica a seleção. `C` limpa.
4. Pressione `S` para acrescentar o registro em `atlas_regions.csv` dentro do **diretório de save do LÖVE**. O arquivo fica separado do projeto e não altera o atlas. Cada linha guarda: `atlas,x,y,width,height,verification`.
5. Cada entrada permanece com `verification=unverified` até ser comparada ao executável/captura de referência. `S` pode acrescentar a mesma região mais de uma vez; remova duplicatas do CSV manualmente quando necessário.

As coordenadas são inteiras com origem no canto superior esquerdo do **PNG original (0,0)**. `width` e `height` são dimensões positivas; o último pixel está em `(x+width-1, y+height-1)`. Zoom e resolução do monitor **não alteram** os valores exportados.

No Windows, o CSV fica normalmente em `%APPDATA%\\LOVE\\artofwar2_lua_rebuild\\atlas_regions.csv`; em outros sistemas consulte o diretório retornado por `love.filesystem.getSaveDirectory()`.

## Extração opcional sem redimensionar

Instale Pillow (`python -m pip install pillow`) e, na raiz do projeto, execute:

```sh
python tools/export_atlas_regions.py "CAMINHO/atlas_regions.csv"
```

Os arquivos derivados são gravados em `assets/derived/manual/`, com nomes contendo PNG e coordenadas. O script valida o nome do arquivo, as dimensões e os limites do recorte; não sobrescreve imagens já exportadas. Use `--dry-run` para validar sem gravar. Nenhum recorte é considerado original/verificado só por ter sido extraído. Compare cuidadosamente com o JAR/execução J2ME quando estiver disponível.

## Segurança e rastreabilidade

- PNGs de `assets/original/` **não são editados**.
- O CSV é um **registro de observações técnicas**, não um inventário de sprites comprovadamente originais.
- Imagens derivadas nunca substituem automaticamente `assets/sprites/` ou a composição atual do protótipo.
- Anote, em documentação separada, a evidência que justificar cada identificação definitiva e a versão do executável utilizada.
