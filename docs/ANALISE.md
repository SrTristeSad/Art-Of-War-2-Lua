# Art of War 2: Global Confederation — inventário inicial

## Arquivos recebidos

- `artofwea_S8000.jad`: descritor de instalação **Java ME**, versão `1.12.0`, fabricante `HeroCraft`, entrada `aow2`, e referência a um JAR de `546006` bytes.
- `art_of_war2_assets_partial.zip`: contém **67 arquivos PNG**, `music_s0m.mid`, `assets_index.lua` e notas de análise de um JAR anterior. O arquivo do código Java (`.jar`) **não veio nesse envio**, assim como os recursos binários brutos.

## Diferença Android/Java ME

O JAD é de um jogo de celular Java ME (MIDlet), não de um APK Android. Existiu posteriormente uma versão de Art of War 2 também para Android, mas não é a mesma distribuição binária. A interface/arte do pacote tem layout-base 240×320.

## Identificação dos dados originais

| Arte no pacote | Uso inferido (ainda não confirmado em bytecode) |
|---|---|
| `i0_0` | Tela/logomarca de abertura |
| `i0_1` | Texturas de terreno |
| `i0_2` a `i0_4` | Objetos naturais/decorativos |
| `i0_5` e `i0_6` | Atlas de construções dos dois lados |
| `i0_8` e `i0_9` | Atlas de soldados de dois lados |
| `i0_10` a `i0_15` | Unidades e máquinas militares |
| `i0_16` a `i0_31` | Efeitos e máscaras |
| `i0_32` a `i0_58` | HUD, botões, fundos e ícones |
| `music_s0m.mid` | Música original (MIDI; não tocável diretamente por LÖVE padrão) |

## Dados que faltam do original

Conforme o relatório de extração incluído pelo próprio pacote:

- `/a`: tabelas numéricas internas;
- `d0`: binário de mapas/grades;
- `m0...m5`, `mi0...mi6`, `dmt`: possíveis parâmetros de missões/interface;
- `f0_0...f3_0`, `ml`: arquivos de layout/fonte;
- Java bytecode para decodificar essas estruturas e entender a IA, o movimento, os upgrades, a economia e os scripts de missão.

**Não afirmar que as regras atuais são idênticas ao original.** A implementação desta versão é um **protótipo funcional provisório** sobre os sprites extraídos. A reconstrução 1:1 exigirá o JAR correspondente (ou APK Android, se a versão desejada for a de Android).

## Funcionalidade do protótipo Lua

- Menus com plano de fundo original, cenário de teste, pausa e ajuda;
- terreno formado com tiles derivados de sprites originais;
- bases azul e vermelha, quartel e fábrica;
- soldados e tanques com combate em tempo real;
- busca de caminho em grade (BFS provisório) em grade, movimentação e seleção de múltiplos soldados;
- receita de créditos automática, custos e fila de produção;
- oponente básico que treina unidades e investe contra o QG;
- construção de quartéis, fábricas e torres, condição de vitória/derrota;
- minimapa, controles de mouse, teclado e toque, salvamento local F5/F9;
- resolução virtual de 240×320 escalada para Windows e Android.

As missões originais e o equilíbrio exato não foram reconstruídos. O botão Campanha abre, por ora, o mesmo **cenário de demonstração**, até os mapas/scripts originais serem recuperados.
