# Art of War 2: Global Confederation — reconstrução 1:1 em Lua

> **OBJETIVO PRINCIPAL: reconstruir o jogo original com fidelidade 1:1**, substituindo o motor Java ME pelo **Lua + LÖVE**, sem transformar a experiência em outro jogo.
>
> **ESTADO ATUAL: protótipo técnico v0.4, NÃO É 1:1.** Os sistemas provisórios são ferramentas de desenvolvimento e serão substituídos à medida que o comportamento original for verificado.

## Princípio do projeto (não negociável)

O resultado desejado é o mesmo **Art of War 2: Global Confederation**, com a mesma apresentação, regras, progressão, unidades, campanhas, mapas e respostas aos comandos. A migração de linguagem e plataforma é uma mudança de implementação, **não um redesenho do jogo**. Números, velocidades, custos, lógica e layouts não serão considerados definitivos antes de comparação contra a versão de referência.

A referência técnica disponível é o descritor **J2ME v1.12.0** (`docs/manifest_original.jad`). A versão Android possui outra distribuição e precisará de seu APK se desejarmos conferir diferenças específicas. O JAD **não contém o código executável**; para aferir os algoritmos e recursos restantes, obter o JAR correspondente é prioritário.

**Leia o [MAPA_DO_PROJETO.md](MAPA_DO_PROJETO.md)** para ver as fases, as metas de fidelidade e os critérios de conclusão.

## Estado real da v0.4

**Existe:** inspeção de atlas originais no próprio LÖVE (F2), inventário verificável dos 67 PNGs originais, profundidade correta entre árvores/rochas e unidades; arte de unidades e edifícios sem deformação da proporção original dos recortes PNG; ordem de desenho por profundidade; prévia de construção e feedback visual temporário de deslocamento, ataque e destruição; pipeline para quadros de animação opcionais (ainda não recuperados do JAR). Motor em tick fixo de 30 Hz, navegação em grade sem atravessar paredes, formação de esquadrão, construção com checagem de colisões, saves legados compatíveis com parser restrito, testes de regressão; menu básico, cenário provisório, bases de dois lados, soldados e tanques, treino/construção, economia automática, navegação A*, inimigo simples, minimapa, mouse/teclado/toque, save/load e sprites extraídos fornecidos pelo usuário.

**Ainda não é fiel ao original:** campanhas/missões, mapas e scripts autênticos, comportamento de IA, parâmetros exatos, evolução tecnológica, todos os tipos de unidades/edifícios, HUD e menus originais, animações e efeitos completos, áudio e sincronização de simulação. Não apresentar essas partes do protótipo como engenharia reversa concluída.

## Testar no Windows

1. Instale o **LÖVE 11.4 ou 11.5** em <https://love2d.org/>.
2. Arraste a pasta do projeto (ou o arquivo `.love`) para `love.exe`.
3. Ou execute `love .` no diretório do projeto, se LÖVE estiver no `PATH`.

Não execute `main.lua` com Lua pura: ele depende do runtime LÖVE.

## Android

O protótipo recebe eventos de toque; ainda não foi empacotado nem validado como APK. A resolução lógica atual é 240 × 320. Para Android, usar LÖVE Android ou empacotamento próprio, após testar controles e escalonamento.

## Controles atuais (provisórios)

| Ação | Windows | Toque |
|---|---|---|
| Selecionar unidade | Clique esquerdo | Toque |
| Seleção múltipla | Arraste com botão esquerdo | Em evolução |
| Mover / atacar | Botão direito ou clique em vazio após seleção | Toque no destino |
| Câmera | WASD / setas / roda / botão do meio | Arrastar o campo ou usar o minimapa |
| Construir | Q: quartel; E: fábrica; T: torre | Botões do painel |
| Treinar | I: soldado; K: tanque | Botão da construção |
| Salvar / carregar | F5 / F9 | Menu |
| Pausar | ESC ou espaço | Botão de pausa |

## Estrutura

- `main.lua`, `conf.lua`: inicialização, loops e eventos do LÖVE;
- `src/world.lua`: simulação provisória (a ser alinhada ao motor original);
- `src/path.lua`: A* provisório;
- `src/art.lua`, `src/animation.lua`: imagens, escala proporcional e pipeline visual não canônico;
- `src/atlas_inspector.lua`: inspetor de PNGs originais exclusivo para engenharia reversa (F2);
- `assets/animations/README.md`: formato para instalar quadros opcionais;
- `src/ui.lua`: menus/HUD provisórios;
- `src/save.lua`: persistência do protótipo;
- `assets/original/`: imagens extraídas do pacote fornecido, preservadas;
- `assets/sprites/`: recortes provisórios para esta versão;
- `docs/ANALISE.md`: evidências, inventário e lacunas da extração;
- `docs/ATLAS_GUIA.md`: como inspecionar os atlas sem fabricar frames;
- `docs/ATLAS_INVENTARIO.csv`: dimensões, bytes e hashes dos 67 PNGs;
- `tools/inventory_atlas.py`: geração e verificação do inventário sem dependências;
- `docs/manifest_original.jad`: manifesto de referência;
- `tools/inventory_jar.py`: inventário de JAR e recursos sem executá-lo;
- `tests/smoke.lua`: verificação de telas/eventos com mock de LÖVE;
- `tests/core_regression.lua`: regressões de navegação, economia, ordens e save;
- `tests/visual_regression.lua`: proporção, temporização visual, efeitos e renderização em mock;
- `tests/depth_regression.lua`: ordem de desenho árvores/unidades/rochas;
- `tests/atlas_regression.lua`: seleção de PNGs originais, navegação, zoom e entrada;
- `src/safe_table.lua`: leitura restrita de saves sem executar conteúdo.

## Regressões (sem LÖVE)

No diretório do jogo com Lua 5.3: `lua tests/core_regression.lua`, `lua tests/visual_regression.lua`, `lua tests/depth_regression.lua`, `lua tests/atlas_regression.lua` e `lua tests/smoke.lua`. Execute `python3 tools/inventory_atlas.py --verify` para validar os PNGs originais. Os testes também rodam por GitHub Actions a cada push. A aprovação desses testes não garante renderização correta, reprodução visual 1:1 nem execução em dispositivo real.

## Inspetor de recursos (v0.4)

Pressione `F2` para inspecionar os atlas originais sem sair do jogo. Setas horizontais navegam por arquivos, PageUp/PageDown pulam dez, Home/End vão aos extremos, roda do mouse ajusta zoom e Esc fecha. A inspeção congela o protótipo enquanto está aberta. Esta é uma **ferramenta de desenvolvimento** e não faz parte da interface J2ME original. Os pixels originais não são modificados.

A ordem visual dos obstáculos agora é calculada junto às entidades, de trás para frente, em vez de desenhar toda a vegetação antes das tropas. Isso melhora a consistência visual do protótipo, mas a ordem definitiva do original ainda depende da análise do JAR.

## Critério de conclusão

A reconstrução 1:1 será considerada concluída **somente** depois que menus, todos os cenários/campanhas, regras, tempo real, movimentação, combate, economia, produção, IA, efeitos e controles tiverem sido comparados e validados contra o jogo original, em Windows e Android, com diferenças registradas e corrigidas. Ter um protótipo jogável **não** equivale a ter concluído a conversão.

Os recursos gráficos e sonoros originais pertencem aos respectivos titulares. Este é um projeto independente de estudo e preservação, sem afiliação com a desenvolvedora original.


## Atualização v0.6 — integração real com os atlas recebidos

Foram encontrados **21 recortes iguais pixel a pixel (RGBA)** aos 21 PNGs usados pelo protótipo, em 12 imagens da pasta `assets/original`. O LÖVE passa a desenhar diretamente essas regiões com `Quad`, mantendo os PNGs separados somente como fallback. Use `F2` e `V` para inspecionar/alternar a sobreposição verde das correspondências verificadas. A ferramenta de seleção manual da v0.5 continua disponível e seu CSV é separado do catálogo verificado.

Para validar novamente sem abrir o jogo:

```bash
python3 tools/verify_sprite_provenance.py
python3 tools/inventory_atlas.py --verify
lua tests/atlas_quads_regression.lua
```

A prova abrange as imagens recebidas, **não** as classes/frames/campanhas do J2ME, ainda inacessíveis sem o JAR. A interface do protótipo não é a original. Para a versão fiel 1:1 continuam prioritários os arquivos originais completos e comparações em dispositivo.
