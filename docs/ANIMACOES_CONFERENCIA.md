# Reconstrução de animações — procedimento de evidência (v0.8)

**Objetivo inalterado:** equivalência 1:1 com Art of War 2: Global Confederation J2ME. O pacote recebido contém atlas PNG com numerosas poses, mas **não** contém a tabela que determina frame, direção, estado ou duração. As sequências criadas neste estágio são somente hipóteses para estudo e comparação; **não integram o jogo automaticamente**.

## Capturar uma sequência candidata no LÖVE

1. Execute o protótipo e pressione **F2** para abrir o inspetor de atlas (o RTS fica pausado).
2. Navegue pelos 67 PNGs com setas. Para cada quadro, selecione uma região com o botão esquerdo do mouse, arrastando até o canto oposto. O recorte conserva as coordenadas originais inclusive após zoom.
3. Pressione **G** para adicionar essa região à sequência de teste; pode navegar para outro PNG antes de adicionar o quadro seguinte. O limite é 64 quadros.
4. **P** ativa/desativa a prévia no canto inferior direito; **F** alterna a velocidade de 1 a 16 FPS. O padrão é 8 FPS, **não é a velocidade original verificada**.
5. **E** exporta o conjunto para `atlas_sequences_candidates.csv` no diretório de salvamento do LÖVE. Nomes incrementais `draft_0001`, `draft_0002` etc. Todas as linhas têm `verification=unverified`.
6. **X** descarta a sequência de teste da memória. Não apaga o CSV existente. **S** continua exportando uma região isolada para `atlas_regions.csv`, como na v0.5.

**Atenção:** `A` já é atalho de navegar para o atlas anterior; usamos `G` para adicionar o quadro. A prévia **não** altera os sprites exibidos durante o combate. F2 e a exportação são ferramentas de engenharia reversa, não parte da interface do jogo original.

## Gerar uma tira de quadros para comparar

```sh
python tools/preview_atlas_sequences.py "CAMINHO/atlas_sequences_candidates.csv" --dry-run
python tools/preview_atlas_sequences.py "CAMINHO/atlas_sequences_candidates.csv"
```

É necessário o Pillow. O utilitário recusa nomes inseguros, regiões fora do PNG, FPS fora do intervalo, quadros duplicados/pulando números e tentativas de sobrescrever prévias existentes. Os PNGs de comparação são escritos em `assets/derived/sequence_previews/`, não em `assets/original/`.

## Promover uma animação à renderização do jogo

`src/animation_sequences.lua` está propositalmente vazio. Só preenchê-lo depois de verificar no jogo J2ME o **nome da unidade**, **estado** (`idle`, `walk`, `attack`, `death`), **ordem dos quadros**, **FPS/durações** e **coordenadas dos atlas**. Registrar a evidência e a versão do binário no mapa de validação. O formato de entrada é:

```lua
return {
  blue_infantry = {
    walk = {
      verification = 'verified',
      fps = 8,
      loop = true,
      frames = {
        { atlas = 'i0_8_77x152.png', x = 0, y = 0, w = 15, h = 17 },
        -- Somente quadros comprovados. Valores desta amostra NAO sao evidencias.
      }
    }
  }
}
```

Se o JAR demonstrar tempo específico para cada quadro, há um campo opcional
`durations_ms = {80, 220, 100}` com um valor inteiro, em milissegundos,
para **cada quadro**. Esse exemplo de durações também é fictício e serve
somente para mostrar a sintaxe. A velocidade `fps` continua obrigatória
como valor de referência/fallback; quando `durations_ms` está presente,
ela tem prioridade para a escolha de quadros. Cada duração deve ser de
1 a 5.000 ms e a sequência inteira não pode exceder 60.000 ms.

Quando a unidade passa de `idle` para `walk` ou inicia um disparo, o relógio
local da animação reinicia no primeiro quadro. Uma unidade bloqueada não
entra automaticamente no estado `walk` apenas por possuir uma ordem.
Durações e estados visuais não alteram cadência de tiros, dano ou movimento.

**O exemplo é didático e não deve ser ativado como animação original.** O carregador restringe estados/unidades, FPS de 1 a 30, até 64 frames, coordenadas inteiras dentro de cada atlas, e `verification='verified'`; quando qualquer frame está ausente, rejeita a sequência inteira, preservando fallback estático. Quads de animação compartilham a mesma textura do atlas que os sprites estáticos e não são gravados nos saves. A renderização sequencial não muda a lógica da simulação. O manifesto não é carregado de arquivos CSV externos ou executado dinamicamente.

## Restrições atuais

- Nenhum `walk`, `attack` ou `death` real foi reconstruído do bytecode original; o **JAR ainda não está disponível**.
- O renderer suporta recortes de qualquer um dos PNGs, mas a disposição exata das sequências permanece desconhecida.
- `assets/animations/<sprite>/<state>_NN.png` permanece como fallback opcional legado, não como prova de fidelidade.
- Testes em LÖVE real, Windows e Android ainda necessários; testes atuais são executados com mock e biblioteca Lua local.

## Etapa v0.9 — regiões sugeridas por análise de transparência

`python tools/detect_sprite_candidates.py` examina os 67 PNGs **sem modificá-los**, localizando regiões contíguas de pixels com alfa não zero (vizinhança 8-conectada). O resultado é determinístico em `docs/ATLAS_CANDIDATOS.csv` e `src/atlas_candidates.lua`, limitado a 256 componentes por atlas, com filtro mínimo de área para reduzir ruído.

No inspetor `F2`, pressione **B** para mostrar/ocultar as regiões candidatas em laranja. **N** seleciona o próximo candidato no atlas atual; **M** seleciona o anterior. Ao selecionar um candidato, **G** o adiciona à sequência de estudo e **E** exporta CSV como `unverified`. Os recortes verdes de `V` continuam sendo somente os 21 PNGs com correspondência de pixels verificada.

**Limitação estrutural:** uma sprite pode ser dividida em muitas ilhas se seus pixels não se tocam; duas sprites podem ser unidas em uma região se os pixels se encostam. Portanto **nenhuma das sugestões identifica automaticamente um frame, direção ou unidade original**. Não são ativadas no renderer do jogo e continuam exigindo observação do J2ME/JAR. Revalidar a base com `python tools/detect_sprite_candidates.py --verify`.

O motor também preserva visualmente uma animação `attack` verificada até o final do tempo total (`durations_ms` ou FPS uniforme), sem prolongar o cooldown de tiro nem alterar dano. Na ausência de animação verificada, conserva o indicador visual provisório de 0,15 s. Torres podem entrar no estado visual `attack`; QGs e edifícios de produção continuam inativos. Isso **não certifica** as animações do Art of War 2 original.
