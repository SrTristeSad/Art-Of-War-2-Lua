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
| 3. Motor determinístico | Atualização, grade, pathfinding, colisão, visão e interações iguais ao original | **Protótipo não validado** |
| 4. RTS e progressão | Dinheiro, construção, produção, pesquisa, unidades, parâmetros, upgrades | **Protótipo parcial** |
| 5. Inteligência artificial | Prioridades, alvos, ordens, defesa, agressividade e comportamento de missões | **Protótipo simples** |
| 6. Interface 1:1 | Abertura, menus, HUD, comandos, seleção, telas, transições e fontes | **Pendente** |
| 7. Conteúdo completo | Todos os mapas, missões, campanhas, eventos e condições de vitória | **Pendente** |
| 8. Audiovisual | Animações, partículas, sprites corretos, efeitos sonoros e música | **Parcial** |
| 9. Windows e Android | Mesma lógica em ambas as plataformas; comandos e renderização adaptados | **Windows e Android não validados em dispositivo** |
| 10. Paridade final | Testes comparativos, correção de divergências e regressão | **Pendente** |

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
