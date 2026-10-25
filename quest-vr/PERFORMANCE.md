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
