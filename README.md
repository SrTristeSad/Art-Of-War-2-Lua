# Art of War 2: Global Confederation — reconstrução 1:1 em Lua

> **OBJETIVO PRINCIPAL: reconstruir o jogo original com fidelidade 1:1**, substituindo o motor Java ME pelo **Lua + LÖVE**, sem transformar a experiência em outro jogo.
>
> **ESTADO ATUAL: protótipo técnico v0.15, NÃO É 1:1.** Os sistemas provisórios são ferramentas de desenvolvimento e serão substituídos à medida que o comportamento original for verificado.

## Princípio do projeto (não negociável)

O resultado desejado é o mesmo **Art of War 2: Global Confederation**, com a mesma apresentação, regras, progressão, unidades, campanhas, mapas e respostas aos comandos. A migração de linguagem e plataforma é uma mudança de implementação, **não um redesenho do jogo**. Números, velocidades, custos, lógica e layouts não serão considerados definitivos antes de comparação contra a versão de referência.

A referência técnica disponível é o descritor **J2ME v1.12.0** (`docs/manifest_original.jad`). A versão Android possui outra distribuição e precisará de seu APK se desejarmos conferir diferenças específicas. O JAD **não contém o código executável**; para aferir os algoritmos e recursos restantes, obter o JAR correspondente é prioritário.

**Leia o [MAPA_DO_PROJETO.md](MAPA_DO_PROJETO.md)** para ver as fases, as metas de fidelidade e os critérios de conclusão.

## Estado real (base v0.4, com melhorias até v0.7)

**Existe:** inspeção de atlas originais no próprio LÖVE (F2), inventário verificável dos 67 PNGs originais, profundidade correta entre árvores/rochas e unidades; arte de unidades e edifícios sem deformação da proporção original dos recortes PNG; ordem de desenho por profundidade; prévia de construção e feedback visual temporário de deslocamento, ataque e destruição; pipeline para quadros de animação opcionais (ainda não recuperados do JAR). Motor em tick fixo de 30 Hz, navegação em grade sem atravessar paredes, formação de esquadrão, construção com checagem de colisões, saves legados compatíveis com parser restrito, testes de regressão; menu básico, cenário provisório, bases de dois lados, soldados e tanques, treino/construção, economia automática, navegação A*, inimigo simples, minimapa, mouse/teclado/toque, save/load e sprites extraídos fornecidos pelo usuário.

**Ainda não é fiel ao original:** campanhas/missões, mapas e scripts autênticos, comportamento de IA, parâmetros exatos, evolução tecnológica, todos os tipos de unidades/edifícios, HUD e menus originais, animações e efeitos completos, áudio e sincronização de simulação. Não apresentar essas partes do protótipo como engenharia reversa concluída.

## v0.10 — triagem reversível dos candidatos gráficos

O extrator preserva todas as **178 regiões não verificadas** dos 67 atlas,
mas agora rotula geometricamente cada região para reduzir os falsos positivos
na pesquisa: **72 para revisão prioritária** e **106 em baixa prioridade**
(composição que ocupa quase todo o atlas, fragmento muito pequeno ou faixa estreita).
Essas categorias **não validam nem rejeitam** nenhuma animação do J2ME.

No inspetor `F2`, use `B` para ver regiões, `N/M` para percorrê-las e `J`
para alternar entre **revisão prioritária** (padrão, laranja) e **todas as
regiões** (baixa prioridade em cinza). As coordenadas e o índice original se
mantêm estáveis. O CSV de pesquisa ganhou `review_priority` e `reason`;
`verification` permanece sempre `unverified`. Consulte
[`docs/REVISAO_CANDIDATOS.md`](docs/REVISAO_CANDIDATOS.md).

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

## Atualização v0.7 — laboratório de animações (não-canônico)

O inspetor `F2` agora permite selecionar recortes e pressionar `G` para guardá-los em uma sequência de estudo. `P` reproduz a prévia, `F` ajusta FPS (1–16), `E` exporta as coordenadas candidatas para CSV e `X` limpa a sequência. O jogo **não** passa a usar automaticamente essas sequências experimentais.

O arquivo `src/animation_sequences.lua` é um manifesto de quadros por atlas (atualmente vazio): somente sequências com evidência externa, marcadas `verified`, podem ser animadas diretamente pelo runtime. A arquitetura suporta `idle`, `walk`, `attack`, `death`, bounds exatos, quad compartilhado por atlas, FPS próprio e fallback para imagens estáticas se um atlas faltar. Os saves e o estado de combate não são alterados.

[Procedimento de captura e conferência](docs/ANIMACOES_CONFERENCIA.md) descreve os atalhos, exportação, geração das tiras de quadros e critérios para adicionar animações reais. Para uma prévia exportada, use `python tools/preview_atlas_sequences.py CAMINHO/atlas_sequences_candidates.csv` (Pillow).

A v0.7 **não representa reconstrução 1:1 concluída**, e os frames de caminhada e ataque originais ainda não foram verificados. Em Windows e Android, a aparência precisa ser conferida no runtime LÖVE real.


## Atualização v0.8 — relógios visuais por estado e temporização por quadro

- Caminhada somente quando a unidade **realmente mudou de posição**;
  uma ordem bloqueada não dispara a animação de movimento.
- A sequência inicia no **primeiro quadro** ao entrar em `walk` ou `attack`;
  um disparo novo também reinicia a fase, sem depender do tempo total da missão.
- Manifestos `verified` admitem `durations_ms` opcionais para reproduzir os
  tempos de cada frame obtidos de fontes originais, além de FPS uniforme.
- `idle`, `walk` e `attack` visuais **não** alteram velocidades de movimento,
  cadência, dano, IA, sorteios ou resultados do motor de combate.
- Campos visuais são descartados nos saves e reiniciados ao carregar;
  partidas de versões anteriores continuam compatíveis.
- Verificação: `lua tests/animation_timing_regression.lua`; todos os demais
  testes de regressão também permanecem obrigatórios.

**Não foram certificados novos quadros do jogo Java nesta versão.** A tabela
`src/animation_sequences.lua` permanece vazia até evidência do executável.
Testes em um LÖVE gráfico real e no Android continuam pendentes.

## Atualização v0.9 — assistência à pesquisa de quadros (não-canônica)

`F2` abre o inspetor; `B` alterna **caixas laranja de componentes opacos sugeridos**, `N/M` percorrem essas regiões, `G` adiciona à sequência de prévia, e `E` exporta uma sequência `unverified`. `V` continua a alternar o catálogo verde de 21 recortes pixel-exact.

Foram localizadas 178 regiões candidatas por transparência, catalogadas em `docs/ATLAS_CANDIDATOS.csv` com origem em `src/atlas_candidates.lua`. A detecção **não comprova quadros de animação** e não integra automaticamente nada às unidades. Para reconstruir/revalidar: `python tools/detect_sprite_candidates.py --verify` (requer Pillow).

Corrigida a duração do estado visual de ataque: uma animação `verified` não é interrompida pelo término do flash de 0,15 s; isso não muda a cadência de ataques. Nenhuma animação original foi certificada nesta etapa. A validação no runtime LÖVE real continua pendente.


## Atualizacao v0.11 — comparacao de poses e pranchas de estudo

No inspetor `F2`, pressione `H` sobre uma selecao ou candidato para fixar uma referencia visual; mude de regiao com `N/M` ou de atlas com as setas. A referencia permanece a esquerda e a selecao atual aparece a direita, ambas com as proporcoes corretas e nearest-neighbor. `L` remove a referencia. **Isso nao habilita nenhuma animacao como verificada.**

As 72 regioes prioritarias foram organizadas em **seis pranchas de inspeccao** no diretorio `docs/review_gallery/`, com `INDEX.csv` vinculando cada miniatura ao atlas e as coordenadas originais. Use `python3 tools/build_review_gallery.py --verify` para conferir a fidelidade pixel a pixel das pranchas regeneradas. As 106 regioes de baixa prioridade seguem preservadas. Consulte [COMPARACAO_DE_POSES.md](docs/COMPARACAO_DE_POSES.md) para o procedimento completo.

Nesta etapa nao foram comprovados frames de movimento, ataque ou direcoes do original, e a execucao real no LÖVE/Android segue pendente. O objetivo 1:1 permanece inalterado.


## Etapa v0.12 — ordens de combate e estabilidade do núcleo

- Edifícios destruídos, objetos antigos e referências não registradas na partida não podem enfileirar unidades nem gastar créditos.
- Uma ordem de ataque manual contra uma unidade específica tem prioridade sobre a escolha automática de inimigos próximos. Enquanto a unidade estiver viva, o comando permanece associado ao seu identificador. Ao morrer, a ordem é descartada para evitar perseguição indefinida às coordenadas antigas. Ordens atribuídas automaticamente pela IA continuam utilizando a seleção automática de alvos.
- A primeira destruição de um QG que define vitória/derrota encerra o processamento da simulação no mesmo passo; os próximos atacantes não podem sobrescrever o resultado.
- O menu exibe o identificador atualizado `PROTOTIPO v0.12`. Testes específicos de combate foram acrescentados à suíte e ao GitHub Actions.
- Esses comportamentos melhoram a **consistência do protótipo Lua**, mas ainda não foram certificados contra o executável Java original. Não implicam equivalência 1:1 de IA ou combate.

Teste adicional: `lua5.3 tests/combat_orders_regression.lua` (ou `texlua` onde não houver Lua 5.3).


## Etapa v0.13 — colisão física e tráfego de unidades

- Criado `src/movement.lua`, separado do motor de combate, para colisão
  entre soldados e tanques durante a navegação; unidades não podem ocupar
  a mesma posição física em deslocamento.
- A colisão contra rochas, vegetação e edifícios considera a área ocupada
  pelo corpo da unidade, não apenas seu pixel central. Os raios adotados
  (4,5 para infantaria e 7,3 para tanques) são **provisórios**.
- Desvio lateral determinístico quando tropas se encontram; quando esse
  desvio persiste, a unidade solicita novo caminho contornando células
  ocupadas por outras tropas. O mapa permanente de obstáculos não muda.
- Comandos de grupo procuram não reservar destinos ocupados por tropas
  não selecionadas. A reserva de destinos continua determinística.
- Temporizadores e sinais temporários de congestionamento ficam fora dos
  saves. Ao carregar uma partida, seus valores são reiniciados.
- `tests/traffic_regression.lua` cobre encontro frontal entre tropas,
  desvio de unidade estacionária, colisão de rocha por raio, slots de
  formação e segurança do save.

**Fidelidade:** essa correção reduz sobreposição e travamentos no protótipo,
mas o comportamento do jogo J2ME permanece **não verificado**. Não foi
extraída nenhuma regra nova do executável original.

Teste: `lua5.3 tests/traffic_regression.lua` (ou `texlua`).


## Etapa v0.14 — movimentação contínua e saída segura de unidades

- `src/movement.lua` verifica **todo o segmento percorrido**, em incrementos de até
  3 pixels ou metade do raio físico da tropa. Mesmo quando um mod fornecer
  um passo de movimentação maior, ela não poderá atravessar outra unidade
  ou rocha simplesmente porque o destino está livre.
- A navegação cria um mapa de **espaço livre por unidade** a partir do mapa
  estático, sem modificar os obstáculos permanentes nem os arquivos de save.
  O mapa de congestionamento considera as células alcançadas pelo raio físico
  de cada soldado/tanque, inclusive quando ele está entre dois tiles.
- Ao concluir uma produção, `World:spawn` verifica a área ocupada pelo novo
  soldado/tanque contra **todas** as tropas, prédios, rochas e bordas. Se não
  houver local seguro, a produção permanece aguardando sem perder a unidade.
- Novo teste `tests/traffic_clearance_regression.lua` cobre travessia em passo
  grande, barreiras, ocupação entre células, saída de fábrica e separação
  entre mapa permanente e tráfego. Também roda no GitHub Actions.

**Limites desta etapa:** essas colisões e raios são regras provisórias do
protótipo, ainda **não certificadas** contra Art of War 2 para Java ME.
Cenários com muitas tropas tentando cruzar o mesmo corredor estreito
ainda podem apresentar espera prolongada: não foi implementado um sistema
de reserva de faixas ou negociação de prioridade entre esquadrões.
A execução gráfica no LÖVE Windows/Android continua pendente.

Execute `lua5.3 tests/traffic_clearance_regression.lua` (ou `texlua`)
para repetir os testes específicos desta etapa.


## Etapa v0.15 — slots de formação por tamanho físico

- `Movement.formationSlots` reserva posições de destino por **raio real do tipo de tropa**: o tanque não recebe um espaço que só serve a infantaria. Para evitar filas artificialmente irregulares, atribui destinos às unidades maiores primeiro e usa desempate determinístico por ID e posição.
- São respeitados o contorno das rochas/edifícios, a borda do mapa, outras unidades **não selecionadas** e os slots já reservados. Unidades selecionadas podem reorganizar suas posições; se a área estiver totalmente ocupada, nenhuma posição impossível é emitida.
- Desvio local que efetivamente aproxima uma unidade do próximo waypoint **não dispara mais replanejamento desnecessário**. Deslocamento lateral sem progresso continua sendo monitorado.
- `tests/squad_formation_regression.lua` confirma espaçamento de tropas de tamanhos diferentes, determinismo, bordas e detecção de progresso, e foi incluído no GitHub Actions.

**Limites:** a política de formação permanece provisória, não foi extraída do JAR e não resolve todos os impasses físicos em corredores de mão única. A execução real no LÖVE/Android continua sem validação.


## Atualização v0.16 — preferência em gargalos (provisória)

- Unidades com **ordens em sentidos opostos** e proximidade real identificam um encontro frontal.
- Desempate determinístico: a unidade de menor ID mantém a preferência; a outra **só** tenta estacionar em uma baia lateral se um trajeto livre de colisões existir. A ordem do usuário não é substituída por essa manobra.
- A unidade que cede espera fisicamente na baia até a prioritária ultrapassar a posição do encontro. Se não houver espaço para ceder, continua bloqueada pelo sistema de colisão existente; **não existe teleporte nem passagem fantasma**.
- Uma baia que ficar bloqueada por nova movimentação é abandonada após curto intervalo, com pausa antes de nova tentativa, evitando espera infinita.
- As reservas e os temporizadores são transitórios e **não entram no save**. Uma nova ordem cancela a manobra de cessão.
- `tests/chokepoint_yield_regression.lua` cobre corredor com baia, corredor sem baia, colisões, limites do terreno, mudança de ordem e persistência. A suíte também roda na automação do GitHub.

**Limitação importante:** em corredor estreito sem nenhuma posição de ultrapassagem, duas unidades podem ficar paradas; isso é um bloqueio físico legítimo, não algo corrigível atravessando paredes. A estratégia continua provisória até comparação com o executável Java original e não demonstra fidelidade 1:1. Execução visual em LÖVE e Android segue pendente.
