# Desempenho — Harmony MR 3.1

Meta: interface a 60 quadros/s, com o valor medido do loop de animação na tela.
Não há garantia de 60 fps em todos os celulares: chipset, WebView, temperatura,
câmera e economia de bateria podem limitar a taxa. O contador não é um teste
independente do compositor físico do Android.

## Mudanças

- Rotação visual e busca do objeto de referência executadas em worker dedicado,
  com transferência do buffer e apenas um quadro em processamento. Respostas
  antigas são descartadas depois de parar, recalibrar ou trocar a referência.
- Modelos MediaPipe de mãos e objetos executados em workers separados, quando
  Worker, ImageBitmap e o ambiente WASM permitem inicialização. CPU no worker
  evita disputar o compositor gráfico com a inferência; existe fallback para
  navegadores sem suporte. Os modelos reais ainda precisam de validação no celular.
- Direção até 20 amostras/s, mãos até 15 inferências/s (adaptativas), objetos
  a cada 1,2 segundo ou 1,6 segundo com as mãos ativas. Essas taxas são distintas
  dos 60 fps da interface. Não se acumulam pedidos de inferência atrasados.
- Busca curta de fluxo óptico para movimentos pequenos; busca ampla continua
  disponível, com verificações de correlação, retorno e consenso preservadas.
- Fundo de câmera em superfícies de vídeo nativas, sem copiar imagens grandes
  para canvases a cada quadro; prévias redundantes ficam ocultas nesse modo.
- Layout da cena em cache, teste do cursor limitado, esqueleto redesenhado só
  quando chega uma nova detecção, status e contadores atualizados quando mudam.
- Removidos filtros de desfoque que repintavam o cenário/câmera atrás dos painéis.
  Bosque com resolução limitada, sem redesenhar quando a orientação está parada.
- APK pede modo de tela de 60 Hz, quando o aparelho oferece esse modo na mesma
  resolução; a câmera pede até 60 fps, sem exigir que o sensor consiga essa taxa.

## Comparação reproduzível

Chromium desktop, janela 960 × 720, câmera sintética 640 × 480 a 30 fps,
algoritmo visual real, inferência simulada com trabalho de 25 ms para mãos e
65 ms para objetos. Ambos os modelos e a visão do ambiente estavam ligados.
A referência é o commit `43c05d4`; cada medição dura aproximadamente 4,5 segundos.

| Medida | Versão anterior | Versão 3.1 |
| --- | ---: | ---: |
| Quadros do loop de animação por segundo | 33,0 | 60,0 |
| Intervalo entre quadros, percentil 95 | 50,0 ms | 16,8 ms |
| Tarefas longas na thread principal | 6 | 0 |
| Tempo total dessas tarefas | 465 ms | 0 ms |

Resultados do ambiente de teste, não medições de um celular. O teste verifica
workers reais, no máximo um trabalho pendente por worker, superfície VIDEO,
contador real de fps e descarte de sessões encerradas. A inferência de ML é
simulada; o modelo real não foi baixado neste teste.

Com o servidor da versão atual em uma porta e o HTML de `43c05d4` em outra:

```sh
QUEST_TEST_URL=http://127.0.0.1:8771/ \
QUEST_BASELINE_URL=http://127.0.0.1:8772/ \
node quest-vr/tests/performance-browser.cjs
```

O teste também pode executar somente a versão atual, omitindo a URL da referência.

## Versão 3.3 — comparação com 3.2.2

Não foi trocado o modelo de mãos nem reduzida a resolução de entrada. O adaptador
da versão fixa 0.4.1675469240 deixa de converter em resultados a imagem de saída
e os landmarks mundiais não utilizados. O stream de imagem permanece como sinal
de fim de quadro, para preservar callbacks quando não há mãos.

Em Chromium desktop com WebGL por software, rede bloqueada e fotografia pública
de duas mãos, oito inferências antes/depois continuaram detectando duas mãos
com 21 pontos. A imagem de saída, não utilizada, caiu de 8 resultados para 0.
O tempo central observado (5º de 8 tempos ordenados) caiu de 335,2 para 300,3 ms.
Esses números não são medições de Android nem garantia de FPS em celulares.
O teste de perda e reaquisição usa o modelo real e também passou.

O teste de desenho verifica 30 quadros em VR com duas mãos: cada par de olhos
executa só dois desenhos de esqueleto, em vez de quatro; o segundo olho recebe
uma cópia equivalente em pixels. As consultas de metadados da câmera ficam
limitadas a troca de câmera ou preferência, em vez de ocorrer por articulação.
Espelhamento, proporções e seleção das coordenadas atuais de objetos são testados.

Remover o modelo full não utilizado reduziu o APK de 12.98 para 9.48 MiB
(27.0%). O modelo lite efetivamente usado e os dois caminhos WASM foram preservados.

Testes: `real-hand-efficiency-browser.cjs`, `real-hands-browser.cjs`,
`render-efficiency-browser.cjs`, testes da interface, mãos estáveis, seleção,
objetos, jogos e rotação visual. O benchmark real usa
`QUEST_BASELINE_URL` para a referência e `QUEST_TEST_URL` para a versão atual.

O agendamento também deixa intervalo entre inferências caras, em vez de exigir
no mínimo 5 inferências/s mesmo quando cada uma consome mais de 200 ms. Em
aparelhos rápidos a frequência-alvo segue igual. Em aparelhos lentos, o limite
inferior adaptativo é 1/s, e sempre há espaço para o loop de desenho. O intervalo
aceito durante calibração acompanha o custo observado, limitado a 1,2 s; os
critérios de estabilidade, consenso e erro de rotação foram preservados.

## Versão 3.4 — abas e confiança visual

A troca de aplicativo atualiza somente os filhos do mundo espacial, preservando
vídeos, canvases de mãos e cenário. Há no máximo cinco abas e um painel ativo
renderizado. Mover uma janela atualiza sua transformação sem reconstruir a cena,
e a transformação não é reescrita se a posição arredondada não mudar.

O assistente novo mantém apenas estatísticas de três eixos. Usa a proporção de
pontos consistentes e o erro de projeção para graduar a suavização; o desvio de
calibração exige oito amostras e significância superior a três erros padrão,
com correção limitada a 0,004 rad/s por eixo. Não depende de outra rede neural,
serviço externo ou sensor físico. O pipeline de mãos foi preservado.

`visual-coach.cjs` valida correção de viés, ruído sem correção falsa, conservação
de giros reais, saltos fracos, movimento rápido confiável, perda de imagem e
desativação do assistente. `windows-browser.cjs` valida posições independentes,
persistência, movimento por ponteiro/teclado/indicador e alinhamento dos olhos.
`spatial-browser.cjs` verifica que o vídeo continua tocando, no mesmo elemento e
com o mesmo stream ao trocar de app. Nenhuma taxa de FPS adicional é prometida
com base nesses testes; o desempenho no celular precisa ser medido no aparelho.

## 3.5 — inferência local isolada da interface

O caminho padrão agora usa o modelo incluído em worker com inferência CPU.
O runtime legado tinha duas falhas nesse caminho: tentava importar o TFLite
como JavaScript e criava o contexto gráfico sem o mesmo registro usado pelo
grafo e pelas texturas de entrada. Corrigidos somente esses trechos, com
alterações documentadas no NOTICE. O worker recebe ImageBitmap de até 480 px
no maior lado e retorna somente landmarks/classificações. A resolução do
vídeo visível e a geometria normalizada dos pontos não mudam.

Comparação reproduzível entre 3.4 e 3.5, Chromium desktop com WebGL por
software, internet bloqueada e foto pública com duas mãos:

| Medida | 3.4 | 3.5 |
| --- | ---: | ---: |
| Tempo mediano de 8 inferências reais consecutivas | 357,2 ms | 76,0 ms |
| Animação durante 3 s de uso com mãos e direção ativas | 10,9 fps | 30,1 fps |
| Maior intervalo de animação nesses 3 s | 550 ms | 33,5 ms |
| Mãos detectadas em cada inferência | 2 | 2 |

Cerca de 79% menos tempo por inferência neste ambiente. A medição consecutiva
é um teste de estresse distinto da taxa adaptativa de uso normal. CPU versus
GPU por software, captura sintética e computador não permitem extrapolar
esses valores para Android, GPU física, condições reais ou garantir 60 fps.

Comando: executar `tests/real-hand-efficiency-browser.cjs` com
`QUEST_BASELINE_URL` apontando para 3.4 e `QUEST_TEST_URL` para 3.5.
`real-hands-browser.cjs` também verifica limpar ao perder mãos, readquirir
e recuperar após encerrar o worker de propósito, sem baixar outro modelo.

## 3.5.1 — reduzir atraso do esqueleto

A versão 3.5 melhorou a renderização, mas mantinha o agendamento conservador
da inferência na thread principal: limite de 15 Hz, período de 1,8 vezes o
processamento e pausa de 35% após cada resposta. O worker agora tem limite
de 30 Hz, período alvo de processamento + 4 ms e pausa de 4 ms. Continua
apenas uma inferência em voo, somente para imagens novas; o fallback mantém
o orçamento anterior. O custo real da câmera/inferência ainda limita a resposta.

O filtro de landmarks reage mais rápido à velocidade (corte mínimo 3,8 Hz,
beta 10, filtro da derivada 8 Hz). A interpolação de apresentação cai de 18
para 6 ms. Não se extrapolam posições futuras nem se inventam mãos.

`tests/hand-latency-browser.cjs` compara trajetórias a 15/30/60 Hz com o filtro
antigo. O erro médio de acompanhamento cai para aproximadamente 23% do antigo,
com ruído alternado de mão parada reduzido em todas as taxas. O teste também
verifica resposta no primeiro quadro de apresentação, convergência após parar
e os orçamentos separados do worker e do fallback. São trajetórias sintéticas,
sem medição de latência física de uma mão real até a tela do Android.

## 3.6 — planos independentes sem reiniciar o rastreamento

Até cinco painéis DOM em perspectiva CSS 3D, com pose independente. O modelo
de mãos e seu agendamento rápido permanecem iguais aos da 3.5.1. Mover, girar
ou redimensionar altera somente as transformações e dimensões do painel.
Atualizar um aplicativo conserva o DOM dos demais e as superfícies de vídeo
e esqueleto. Desfoque desligado em celular, com mãos, em VR e com várias janelas.

O renderer nativo WebXR é carregado localmente, sem biblioteca ou modelos
adicionais. Ele desenha quads WebGL, com texturas de interface em cache e
atualizações de conteúdo espaçadas (350 ms). Não converte DOM em imagem em
cada quadro. Poses de olhos e controles vêm da sessão XR quando disponível.
Para digitação, use o navegador antes de entrar: não foi incluído teclado VR.

Ver `SPATIAL.md` e os testes `windows-browser.cjs` / `native-xr-browser.cjs`.
Validação de headset utiliza poses sintéticas; não houve ensaio de hardware.
O fluxo sem giroscópio no celular continua estimando somente a rotação visual.
