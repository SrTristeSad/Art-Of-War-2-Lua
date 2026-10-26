# Comparacao de regioes candidatas — v0.11

**Objetivo: reconstruir Art of War 2: Global Confederation 1:1.**

As imagens fornecidas sao parciais e nao incluem o JAR executavel completo. **Nenhuma pose de movimento ou ataque foi certificada.** O comparador nao altera os dados do jogo.

## F2 — comparar duas regioes
1. Pressione `F2`, `B` para exibir candidatos, e `N`/`M` para navegar. `J` alterna prioridade.
2. Pressione `H` para fixar uma regiao como referencia.
3. Percorra outra regiao, inclusive outro PNG. O comparador mostra referencia a esquerda e selecao a direita.
4. Pressione `L` para limpar. As duas imagens preservam proporcoes, transparencias e nearest-neighbor.

## Galeria offline
Execute `python3 tools/build_review_gallery.py` para gerar seis pranchas `docs/review_gallery/page_01.png` ate `page_06.png`. Cada prancha tem 12 recortes prioritarios, numerados e com coordenadas. O `INDEX.csv` associa atlas, coordenadas e posicao de cada quadro. Use `python3 tools/build_review_gallery.py --verify` para verificar as imagens regeneradas pixel a pixel.

Os 106 candidatos de baixa prioridade permanecem no indice original e no inspetor. Nenhuma regiao e elevada a `verified` com base em similaridade visual.

**Limitacao:** ilhas de pixels opacos podem dividir uma unidade em multiplas regioes ou mesclar varios elementos. Obter o JAR completo e comparar a execucao original para validar sequencia, direcao, tempo e regras.
