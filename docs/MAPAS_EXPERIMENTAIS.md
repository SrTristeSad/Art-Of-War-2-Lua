# Formato experimental de mapas e missões — v0.19

> **Não é o formato do Art of War 2 original.** O pacote parcial fornecido não contém um JAR completo com as missões. Este formato é uma infraestrutura **provisória**, destinada a permitir importação e comparação futuros, sem declarar qualquer mapa como canônico.

## Fluxo disponível

No menu inicial, selecione **MAPA EXPERIMENTAL** para jogar o cenário demonstrativo `training_crossroads` (36 × 26). A batalha usa as mesmas regras provisórias de combate e economia da opção **BATALHA LIVRE**. O objetivo do mapa agora é **sobreviver por 90 segundos**, mantendo o QG do jogador intacto; a batalha livre mantém a regra anterior de destruir o QG inimigo. A opção **CAMPANHA** ainda não corresponde às missões originais.

`src/mission.lua` lê `missions/training_crossroads.tbl` com `src/safe_table.lua`: o texto **não é executado como código Lua**. Somente identificadores previamente autorizados em `Mission.load` podem ser abertos. Conteúdo arbitrário, dimensões excessivas, terreno incompatível, listas malformadas, unidades inválidas, edifícios sobre rochas e falta de QG são rejeitados antes de alterar o mundo.

A extensão `.tbl` significa dados de tabela, **não um script**. Sua sintaxe segue o subconjunto `return { ["chave"] = valor, ... }` de que o parser seguro precisa. A configuração de referência contém:

- `format=1`, `id`, `provenance="experimental"`, `width`, `height`;
- `rows` numeradas de 1 a `height`, cada string com `width` símbolos `g`, `G`, `d`, `D` (grama e terra);
- `obstacles` com entradas `{x, y, typeName}` em células, admitindo `rocks` ou `forest`;
- `entities` com `{kind, team, x, y}` em células, admitindo unidades `infantry`, `tank` e edifícios `hq`, `barracks`, `factory`, `turret`;
- `money` e `income` indexados pelos times `1` e `2`.
- `objective` (opcional): `{kind="destroy_hq"}` (padrão), `{kind="survive",seconds=90}` ou `{kind="eliminate_units"}`. O QG do jogador é obrigatório para todos os objetivos. Duração de sobrevivência: 1–3.600 segundos.
- `events` (opcional, máximo 16): gatilhos temporais de execução única com `{at=12,action="credits",team=1,amount=175}` ou `{at=22,action="reinforce",team=2,kind="infantry",x=24,y=17}`. Tempos em segundos inteiros (1–3.600). Reforços só admitem infantaria e tanques, respeitam a área ocupada e não entram se a posição estiver bloqueada. Um evento bloqueado fica registrado como executado, evitando repetição infinita.

**Demonstração v0.18:** sobreviva 90 segundos. A equipe 1 recebe 175 créditos aos 12 segundos, a equipe 2 recebe uma unidade aos 22 segundos e a equipe 1 recebe um tanque aos 45 segundos, se houver espaço. Eventos e condições de vitória usam apenas configurações declarativas; nenhum trecho arbitrário é executado. O HUD exibe a meta e o tempo restante.

O estado dos eventos concluídos e o objetivo passam a ser incluídos nos saves; saves antigos sem campos de missão permanecem compatíveis.

**Limitações:** só existem gatilhos **temporais** de eventos, três categorias de objetivo e duas ações declarativas; não há scripts de missão, gatilhos de área ou de destruição configuráveis, campanhas, fog-of-war comprovado ou IA extraída do original. A topologia do exemplo é feita à mão. Somente mapear formatos do JAR/APK recuperado poderá estabelecer paridade.

## Compatibilidade e segurança

Os saves mantêm `w`, `h`, `tile` e `mapId`, além do estado da partida. Saves legados sem esses campos continuam utilizando as dimensões anteriores. Saves com geometria inválida são rejeitados. O carregamento de mapas não oferece acesso irrestrito ao sistema de arquivos.

Execute `lua5.3 tests/mission_objectives_regression.lua`, `lua5.3 tests/mission_loader_regression.lua`, `texlua tests/squad_bay_reservation_regression.lua` e toda a suíte antes de adicionar qualquer novo mapa.

## Próximos passos para 1:1

1. Obter e inventariar o JAR da versão do JAD (ou o APK da edição Android alvo).
2. Localizar no executável os dados originais de mapas, terrenos, posicionamento de unidades, condições de vitória e gatilhos.
3. Implementar decodificadores de conteúdo **separados** dos mapas experimentais.
4. Comparar cada fase carregada pixel a pixel e comportamento a comportamento em emulador antes de marcá-la como verificada.


## Extensão v0.19: etapas e acontecimentos

O segundo botão de mapa (**MAPA: OPERACAO**) carrega `training_operations`. Reutiliza um terreno experimental de 36 × 26 células, mas possui três etapas distintas:

1. Proteger o **quartel aliado**, time 1, célula `(5,13)`, durante 20 segundos.
2. Destruir o **quartel inimigo**, time 2, célula `(31,13)`.
3. Sobreviver por mais 25 segundos **a partir da abertura da terceira etapa**.

O formato admite `objective={kind="sequence",steps={...}}`, com no máximo oito etapas. Tipos de etapa: `{kind="survive",seconds=25}`, `{kind="protect_structure",team=1,structure="barracks",x=5,y=13,seconds=20}` e `{kind="destroy_structure",team=2,structure="barracks",x=31,y=13}`. Estruturas protegidas/destruídas devem estar presentes **na lista inicial de edifícios**; o verificador não aceita referências inventadas. `protect_structure` falha se seu alvo morrer durante a etapa; a última etapa concluída vence. O QG aliado destruído causa derrota em qualquer momento.

Eventos podem continuar usando `at=<tempo-global>` ou usar **um único** `trigger`, escolhido dentre:

- `{kind="stage_start",step=2}` — dispara quando a segunda etapa abre;
- `{kind="structure_destroyed",team=2,structure="barracks",x=31,y=13}` — dispara quando aquele edifício específico é destruído.

As únicas ações são `credits` e `reinforce`, com as restrições anteriores. Eventos são executados uma única vez, mesmo após salvar/carregar. Se um reforço não couber fisicamente no local, o evento é consumido, não repetido. Só IDs permitidos pela tabela do carregador são lidos; não há scripts customizados.

**Não canônico:** a identificação de etapas, os tempos, coordenadas e gatilhos são decisões técnicas do protótipo, não conhecimento recuperado do JAR original. Nenhum objetivo de captura foi implementado nesta versão.

Teste: `lua5.3 tests/mission_stages_regression.lua` (ou `luatex --luaonly tests/mission_stages_regression.lua`).
