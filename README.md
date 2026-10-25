# Art of War 2: Global Confederation — reconstrução 1:1 em Lua

> **OBJETIVO PRINCIPAL: reconstruir o jogo original com fidelidade 1:1**, substituindo o motor Java ME pelo **Lua + LÖVE**, sem transformar a experiência em outro jogo.
>
> **ESTADO ATUAL: protótipo técnico v0.2, NÃO É 1:1.** Os sistemas provisórios são ferramentas de desenvolvimento e serão substituídos à medida que o comportamento original for verificado.

## Princípio do projeto (não negociável)

O resultado desejado é o mesmo **Art of War 2: Global Confederation**, com a mesma apresentação, regras, progressão, unidades, campanhas, mapas e respostas aos comandos. A migração de linguagem e plataforma é uma mudança de implementação, **não um redesenho do jogo**. Números, velocidades, custos, lógica e layouts não serão considerados definitivos antes de comparação contra a versão de referência.

A referência técnica disponível é o descritor **J2ME v1.12.0** (`docs/manifest_original.jad`). A versão Android possui outra distribuição e precisará de seu APK se desejarmos conferir diferenças específicas. O JAD **não contém o código executável**; para aferir os algoritmos e recursos restantes, obter o JAR correspondente é prioritário.

**Leia o [MAPA_DO_PROJETO.md](MAPA_DO_PROJETO.md)** para ver as fases, as metas de fidelidade e os critérios de conclusão.

## Estado real da v0.2

**Existe:** motor em tick fixo de 30 Hz, navegação em grade sem atravessar paredes, formação de esquadrão, construção com checagem de colisões, saves legados compatíveis com parser restrito, testes de regressão; menu básico, cenário provisório, bases de dois lados, soldados e tanques, treino/construção, economia automática, navegação A*, inimigo simples, minimapa, mouse/teclado/toque, save/load e sprites extraídos fornecidos pelo usuário.

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
- `src/art.lua`: carregamento de sprites;
- `src/ui.lua`: menus/HUD provisórios;
- `src/save.lua`: persistência do protótipo;
- `assets/original/`: imagens extraídas do pacote fornecido, preservadas;
- `assets/sprites/`: recortes provisórios para esta versão;
- `docs/ANALISE.md`: evidências, inventário e lacunas da extração;
- `docs/manifest_original.jad`: manifesto de referência;
- `tools/inventory_jar.py`: inventário de JAR e recursos sem executá-lo;
- `tests/smoke.lua`: verificação de telas/eventos com mock de LÖVE;
- `tests/core_regression.lua`: regressões de navegação, economia, ordens e save;
- `src/safe_table.lua`: leitura restrita de saves sem executar conteúdo.

## Regressões (sem LÖVE)

No diretório do jogo com Lua 5.3: `lua tests/core_regression.lua` e `lua tests/smoke.lua`. Os testes também rodam por GitHub Actions a cada push. A aprovação desses testes não garante renderização correta, reprodução visual 1:1 nem execução em dispositivo real.

## Critério de conclusão

A reconstrução 1:1 será considerada concluída **somente** depois que menus, todos os cenários/campanhas, regras, tempo real, movimentação, combate, economia, produção, IA, efeitos e controles tiverem sido comparados e validados contra o jogo original, em Windows e Android, com diferenças registradas e corrigidas. Ter um protótipo jogável **não** equivale a ter concluído a conversão.

Os recursos gráficos e sonoros originais pertencem aos respectivos titulares. Este é um projeto independente de estudo e preservação, sem afiliação com a desenvolvedora original.
