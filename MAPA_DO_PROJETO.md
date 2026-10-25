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
| 6. Interface 1:1 | Abertura, menus, HUD, comandos, seleção, telas, transições e fontes | **HUD provisório; v0.4: inspetor técnico de atlas (não é HUD original)** |
| 7. Conteúdo completo | Todos os mapas, missões, campanhas, eventos e condições de vitória | **Pendente** |
| 8. Audiovisual | Animações, partículas, sprites corretos, efeitos sonoros e música | **Protótipo v0.4: PNG proporcional, vegetação e unidades em ordem Y, FX, inventário dos 67 atlas; dados originais incompletos** |
| 9. Windows e Android | Mesma lógica em ambas as plataformas; comandos e renderização adaptados | **Windows e Android não validados em dispositivo** |
| 10. Paridade final | Testes comparativos, correção de divergências e regressão | **Regressões locais v0.4; comparações 1:1 pendentes** |

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
