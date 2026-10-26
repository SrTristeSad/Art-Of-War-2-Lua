# Formato experimental de mapas e missões — v0.17

> **Não é o formato do Art of War 2 original.** O pacote parcial fornecido não contém um JAR completo com as missões. Este formato é uma infraestrutura **provisória**, destinada a permitir importação e comparação futuros, sem declarar qualquer mapa como canônico.

## Fluxo disponível

No menu inicial, selecione **MAPA EXPERIMENTAL** para jogar o cenário demonstrativo `training_crossroads` (36 × 26). A batalha usa as mesmas regras provisórias de combate e economia da opção **BATALHA LIVRE**. O objetivo atual continua sendo destruir o QG adversário. A opção **CAMPANHA** ainda não corresponde às missões originais.

`src/mission.lua` lê `missions/training_crossroads.tbl` com `src/safe_table.lua`: o texto **não é executado como código Lua**. Somente identificadores previamente autorizados em `Mission.load` podem ser abertos. Conteúdo arbitrário, dimensões excessivas, terreno incompatível, listas malformadas, unidades inválidas, edifícios sobre rochas e falta de QG são rejeitados antes de alterar o mundo.

A extensão `.tbl` significa dados de tabela, **não um script**. Sua sintaxe segue o subconjunto `return { ["chave"] = valor, ... }` de que o parser seguro precisa. A configuração de referência contém:

- `format=1`, `id`, `provenance="experimental"`, `width`, `height`;
- `rows` numeradas de 1 a `height`, cada string com `width` símbolos `g`, `G`, `d`, `D` (grama e terra);
- `obstacles` com entradas `{x, y, typeName}` em células, admitindo `rocks` ou `forest`;
- `entities` com `{kind, team, x, y}` em células, admitindo unidades `infantry`, `tank` e edifícios `hq`, `barracks`, `factory`, `turret`;
- `money` e `income` indexados pelos times `1` e `2`.

**Limitações:** não existem gatilhos, objetivos alternativos, scripts de missão, campanhas, fog-of-war comprovado ou IA extraída do original. A topologia do exemplo é feita à mão. Somente mapear formatos do JAR/APK recuperado poderá estabelecer paridade.

## Compatibilidade e segurança

Os saves mantêm `w`, `h`, `tile` e `mapId`, além do estado da partida. Saves legados sem esses campos continuam utilizando as dimensões anteriores. Saves com geometria inválida são rejeitados. O carregamento de mapas não oferece acesso irrestrito ao sistema de arquivos.

Execute `texlua tests/mission_loader_regression.lua` (Lua 5.3), `texlua tests/squad_bay_reservation_regression.lua` e toda a suíte antes de adicionar qualquer novo mapa.

## Próximos passos para 1:1

1. Obter e inventariar o JAR da versão do JAD (ou o APK da edição Android alvo).
2. Localizar no executável os dados originais de mapas, terrenos, posicionamento de unidades, condições de vitória e gatilhos.
3. Implementar decodificadores de conteúdo **separados** dos mapas experimentais.
4. Comparar cada fase carregada pixel a pixel e comportamento a comportamento em emulador antes de marcá-la como verificada.
