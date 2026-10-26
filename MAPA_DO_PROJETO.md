# Mapa do projeto — reconstrução fiel 1:1

## Norte do projeto

**Recriar Art of War 2: Global Confederation de forma 1:1 em Lua + LÖVE.** Queremos jogar a mesma obra, não um RTS inspirado nela. A arquitetura pode mudar para funcionar em Windows e Android, mas **a experiência externa e a lógica original são a especificação**. Fidelidade precede novas funcionalidades.

**Referência identificada:** Java ME (J2ME), HeroCraft, versão 1.12.0, 240×320. O arquivo `.jad` é apenas o descritor; sem o `.jar`, regras e recursos binários ainda não são verificáveis. Se a meta mudar para a edição Android, será preciso ter o respectivo APK e registrar quais diferenças existem entre as edições.

## Regra para todo desenvolvimento

1. **Observar** o original (arquivos, screenshots, gravações, execução no emulador e bytecode quando disponível).
2. **Documentar** comportamento observado, números e coordenadas com a fonte e a versão.
3. **Implementar** em Lua de modo equivalente, sem inventar mudanças de design.
4. **Comparar** lado a lado, inclusive casos-limite e temporização.
5. **Validar** e marcar como fiel apenas quando o teste demonstrar equivalência.

Quando não houver evidência suficiente, anotar explicitamente **provisório / desconhecido**. Priorizar paridade sobre extensões. Ajustes necessários para Android e Windows devem preservar uma camada de simulação comum.

## Etapas e entregáveis

| Etapa | Entrega | Estado |
|---|---|---|
| 0. Inventário | Organizar JAD, PNGs, sprite sheets e lacunas documentadas | **Parcial** |
| 1. Recuperar executável | JAR v1.12.0 correspondente ou APK da edição desejada; hashes e recursos | **Pendente** |
| 2. Engenharia reversa | Classes, formatos de mapas/`d0`, tabelas `/a`, dados `m0`–`m5`, scripts e fontes | **Pendente** |
| 3. Motor determinístico | Atualização, grade, pathfinding, colisão, visão e interações iguais ao original | **Protótipo v0.2: tick fixo e regressões; paridade J2ME não validada** |
| 4. RTS e progressão | Dinheiro, construção, produção, pesquisa, unidades, parâmetros, upgrades | **Protótipo parcial** |
| 5. Inteligência artificial | Prioridades, alvos, ordens, defesa, agressividade e comportamento de missões | **Protótipo simples** |
| 6. Interface 1:1 | Abertura, menus, HUD, comandos, seleção, telas, transições e fontes | **HUD provisório; v0.6: inspetor exibe contornos dos recortes com igualdade RGBA; não é HUD original** |
| 7. Conteúdo completo | Todos os mapas, missões, campanhas, eventos e condições de vitória | **Pendente** |
| 8. Audiovisual | Animações, partículas, sprites corretos, efeitos sonoros e música | **Protótipo v0.6: 21 sprites mapeados pixel a pixel em 12 atlas; Quad LÖVE com fallback, animações ainda não verificadas** |
| 9. Windows e Android | Mesma lógica em ambas as plataformas; comandos e renderização adaptados | **Windows e Android não validados em dispositivo** |
| 10. Paridade final | Testes comparativos, correção de divergências e regressão | **Regressões locais v0.6; comparações 1:1 de comportamento pendentes** |

## Matriz obrigatória de fidelidade

| Área | Para chamar de 1:1, verificar | Agora |
|---|---|---|
| Regras e economia | Valores, tempos, produção, upgrades e condições exatas | Desconhecidos/provisórios |
| Movimento e combate | Caminhos, colisões, alcances, dano, cadência, prioridades, IA | Desconhecidos/provisórios |
| Mapas e missões | Conteúdo, topologia, unidades iniciais, gatilhos, progressão | Não recuperados |
| UI/UX | Posição, aparência, texto, fluxo e resposta de cada tela | Provisório |
| Imagens | Atlas, recortes corretos, animações e ordem de desenho | Material parcial |
| Áudio | Trilhas, efeitos, eventos de disparo e reprodução | Incompleto |
| Plataformas | Comportamento real no Windows e Android e save compatível | Não certificado |

## Arquivos e rastreabilidade

- `docs/ANALISE.md`: fatos já obtidos e itens faltantes;
- `docs/manifest_original.jad`: referência técnica recebida;
- `assets/original/`: PNGs extraídos preservados com seus nomes;
- `assets/sprites/`: recortes derivados, **não fonte de verdade para o motor**;
- `src/`: código do protótipo a ser gradualmente substituído por sistemas verificados;
- `tests/`: espaço dos testes de regressão e, futuramente, paridade por missão.

## Definição de pronto

Não encerrar o projeto só porque o jogo abre, move tropas ou vence uma partida. Cada item da matriz precisa de evidência comparativa; nenhuma funcionalidade relevante do original pode ser omitida, substituída por uma aproximação permanente ou inventada sem identificação explícita. Problemas de fidelidade têm prioridade sobre funcionalidades novas.

**Marco imediato:** obter `artofwea_S8000.jar` correspondente ao manifesto ou APK equivalente; identificar tabelas/mapas/classes e substituir o cenário de demonstração pelos dados originais. Sem esses binários, qualquer afirmação de paridade completa seria incorreta.

## Marco v0.2 — integridade do núcleo provisório

As correções abaixo são **engenharia de robustez**, não equivalência comprovada com o JAR:

- Atualização em passos fixos de 1/30 s, com entrada de `dt` limitada em pausas longas;
- Busca de caminho por células, sem atravessar paredes quando um destino não possui rota;
- Ordens de esquadrão distribuídas em células distintas e livres;
- Validação de sobreposição de construções com tropas e obstáculos;
- RNG pseudoaleatório com estado persistido para reprodutibilidade após carregar;
- Save restaurando acumulador de simulação e sem execução de Lua do arquivo externo;
- Regressões automatizadas (caminhos, economia, movimento, construção, save e UI mock).

**Limitações:** o bloqueio por células e o espaçamento ainda são provisórios; não reproduzem algoritmos que ainda não foram extraídos do JAR. O LÖVE real e o Android seguem aguardando teste manual. A prioridade seguinte continua sendo recuperar os dados binários originais e verificar o atlas e o HUD lado a lado.

## Marco v0.3 — interface visual e efeitos provisórios

- Sprite de unidades e edifícios conserva a proporção real do arquivo de imagem, evitando esticamento vertical/horizontal;
- Entidades são desenhadas do fundo para a frente pela coordenada Y e ganham sombra no solo;
- Indicador temporário de destino, impacto e explosão; sem uso do RNG da simulação para efeitos;
- Prévia verde/vermelha para construções, usando `canBuild` existente, sem cobrar créditos antes da confirmação;
- Carregamento opcional de frames `idle`, `walk`, `attack`, `death` em `assets/animations`; quando ausentes usa-se PNG estático com oscilação mínima provisória;
- Efeitos são transitórios: não modificam save nem alteram o estado de mundo usado pelas regras;
- Testes de proporção, quadros, efeitos, desenho, save e compatibilidade com saves anteriores.

**Limite de fidelidade:** a composição do HUD, cadência visual e ordem de animações NÃO foram reconstruídas do bytecode J2ME. Ainda falta executar os novos visuais no LÖVE Windows/Android e verificar contra capturas do jogo real. A prioridade 1 continua sendo obter o JAR referente ao JAD.

## Marco v0.4 — análise visual rastreável

- `F2`: inspetor de PNGs **originais**, com navegação natural por numeração (`i0_2` antes de `i0_10`), zoom pixelado, consulta de coordenadas e pausa automática da simulação durante inspeção;
- `tools/inventory_atlas.py` + `docs/ATLAS_INVENTARIO.csv`: dimensões, tamanho e SHA-256 dos **67 PNGs originais**, sem alterar qualquer recurso do pacote recebido;
- Ordenação por profundidade compartilhada entre construções, unidades, árvores e rochas. Elementos à frente ocultam os de trás (correção da falha que fazia unidades aparecerem sobre árvores mesmo estando atrás);
- Regressões próprias para visualização, zoom, navegação e ordenação da cena, adicionadas ao CI.

**Importante:** inspetor, regra de profundidade e demais ferramentas v0.4 são melhorias técnicas demonstráveis, **não prova de paridade** com o programa J2ME. Mapas, HUD, frames, scripts, atributos e campanhas permanecem pendentes de extração do JAR.

## Marco v0.5 — catalogação manual de regiões

- Seleção visual e registro de regiões por coordenadas originais no inspetor F2;
- Exportação isolada em PNG por `tools/export_atlas_regions.py`, sem regravar fontes;
- Todo recorte manual fica `unverified` até prova independente.

## Marco v0.6 — correspondências por igualdade de pixels

- Comparação RGBA encontrou **21 de 21 sprites atuais idênticos** aos recortes localizados em **12 atlas de origem** entre os 67 PNGs fornecidos.
- `src/atlas_catalog.lua` e `docs/ATLAS_SPRITES_VERIFICADOS.csv` documentam a mesma posição e dimensões; `tools/verify_sprite_provenance.py` verifica novamente todos os pixels e detecta divergências; nenhuma alteração nos PNGs originais.
- `src/art.lua` passa a renderizar os sprites originais como **LÖVE Quads**, compartilhando a mesma textura para recortes do mesmo atlas, sem gerar novo PNG. As imagens isoladas de `assets/sprites/` continuam como fallback se um atlas estiver ausente ou sem Quad disponível.
- O inspetor `F2` passa a marcar em verde recortes com igualdade de pixels, com tecla `V` para ligar/desligar a sobreposição. A identificação manual por CSV continua separada.
- Regressões validam recortes, desenhar rotacionado, transparência através da imagem original, fallback por atlas ausente, catálogo, integridade do material e núcleo.

**Precisão do marco:** a designação `pixel-exact` comprova **somente igualdade dos pixels destes 21 recortes com os PNGs originais recebidos**. Não comprova que sejam os quadros usados em todos os estados do RTS J2ME, nem o timing de animação, nem a interface/missões/IA/regras. Compor a primeira cena do jogo continua provisório. Próxima meta: recuperar classes e a tabela original de animações/direções do JAR, registrar evidências e substituir suposições.

## Marco v0.7 — laboratório de sequências e integração verificada

- O inspetor `F2` captura sequências de até 64 recortes em múltiplos atlas, permite prévia temporal (`G`, `P`, `F`, `E`, `X`) e exporta CSV separado identificado exclusivamente como `unverified`.
- `tools/preview_atlas_sequences.py` valida o CSV e gera tira de quadros sem alterar os 67 atlas originais. Nomes, coordenadas, numeração e FPS são validados.
- `src/atlas_sequence.lua` e `src/animation_sequences.lua` introduzem manifesto de animações: só sequências explicitamente confirmadas (`verification='verified'`) são usadas no jogo; manifestos não são executados a partir dos exports do usuário.
- Em caso de falta de atlas/Quad, os frames da sequência são rejeitados atomicamente e a entidade mantém seu sprite estático. Sem sequência, o jogo continua com os placeholders visuais conhecidos; não há invenção de quadros originais.
- Testes novos para temporização, bounds, fallback e CSV; CI do GitHub Actions corrigido para executar os três testes Python separadamente.

**Resultado de fidelidade:** infraestrutura de investigação e reprodução de sequências aprimorada; **nenhuma animação J2ME foi certificada**. Continuamos dependentes do JAR original e da comparação quadro a quadro com execução de referência.


## Marco v0.8 — temporização de animações sem suposições sobre o Java

- Cada entidade tem estado e tempo visuais próprios, reiniciados na mudança
  entre repouso/movimento/ataque ou quando um novo disparo é efetuado.
- Somente deslocamento real seleciona `walk`; tentativas bloqueadas deixam
  o sprite em `idle` em vez de simular caminhada no lugar.
- Manifestos de sequências aceitam durações inteiras em milissegundos por
  quadro (`durations_ms`); reproduzem quadros em loop ou mantêm o último em
  sequências sem loop. FPS uniforme continua suportado.
- Timers, estado visual e indicador de movimento são transitórios:
  nunca entram nos saves nem modificam regras de combate ou RNG.
- Regressão dedicada de transições, sequência não uniforme, estados ao carregar
  saves e compatibilidade do núcleo. **Sem animação J2ME certificada** e sem
  execução gráfica real ainda; fidelidade 1:1 permanece pendente do JAR.

## Marco v0.9 — detecção assistida de quadros (não-canônica)

- O inventário dos **67 PNGs originais** pode gerar regiões por componentes 8-conectados de pixels visíveis, com limites seguros por atlas. Nesta versão, foram geradas **178 regiões candidatas**; cada uma permanece `unverified`. São hipóteses de recortes, não quadros de animação comprovados.
- `src/atlas_candidates.lua` alimenta o inspetor `F2`. `B` alterna sobreposição laranja; `N/M` percorrem propostas no atlas; `G` adiciona à prévia e `E` exporta CSV para estudo. As 21 correspondências de pixels confirmadas continuam separadas em verde.
- `src/art.lua` fornece apenas a duração de sequências marcadas e validadas como `verified`. O relógio de ataque em `src/animation.lua` não encerra antes de uma sequência verificada terminar; ataques de torres também podem ser animados. Essas operações são **exclusivamente visuais** e não alteram IA, danos, economia ou regras.
- CI ampliado com testes da detecção, exportação determinística, limites das regiões, interface do inspetor e temporização de ataque.

**Estado do 1:1:** ainda NÃO concluído. Campanhas, controle de unidades, FPS, IA, missões e animações seguem sem certificação contra o JAR original. Apenas ferramentas de investigação e robustez do protótipo avançaram.

## Marco v0.10 — triagem de candidatos sem perda de evidência

- O índice `ATLAS_CANDIDATOS.csv` continua contendo as **178 regiões** dos
  67 atlas originais. Os novos campos `review_priority` e `reason` são
  heurísticas de navegação, **não** validação de sprites nem de animações.
- 72 regiões de revisão prioritária; 106 de baixa prioridade (58 quase
  abrangem o atlas inteiro, 44 são fragmentos pequenos e 4 faixas estreitas).
  Nenhum candidato anterior foi apagado ou teve coordenadas modificadas.
- No inspetor F2, `J` alterna revisão prioritária/todos os candidatos; `N/M`
  respeitam o filtro e mantêm os índices originais; caixas menos promissoras
  aparecem em cinza quando o filtro está desligado.
- Regressões verificam triagem determinística, navegação, limites dos recortes,
  que todos seguem `unverified`, integridade dos 67 PNGs e igualdade de pixels
  dos 21 sprites previamente confirmados.

**Pendente para a fidelidade 1:1:** sequências, direções, mapas, scripts e
parâmetros do JAR/execução original. Esta etapa melhora a investigação, não
certifica comportamento do jogo original.


### Etapa v0.11 — comparacao visual controlada

- **Concluido (ferramenta):** fixar regiao de referencia com `H` e comparar com a selecao atual, inclusive entre atlas; `L` para liberar. Nao altera estado do motor.
- **Concluido (inventario):** gerador deterministico de seis pranchas para as 72 regioes prioritarias com indice; 106 regioes de baixa prioridade mantidas.
- **Concluido (qualidade):** testes Lua e Python, inventario SHA-256 dos 67 atlas e regressao do jogo.
- **Ainda nao feito:** certificacao de ordem/direcao/tempo dos quadros, reproducao 1:1 do HUD e das missoes, teste grafico no LÖVE/Android. Dependencia principal: JAR completo original.
