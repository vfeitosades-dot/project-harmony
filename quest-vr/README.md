<!-- Mãos/VR 3.2: rastreamento com identidades estáveis e HUD externo oculto no VR. -->
# Harmony MR 3.5.1

Atualização de desempenho: workers, vídeo nativo, menos repinturas e contador real de FPS.
[Detalhes e comparação de desempenho](PERFORMANCE.md). Meta de 60 fps, dependente do aparelho.

Interface refeita a partir dos dois vídeos fornecidos do EnJoyTheMR/EnJoyTheVR.
Veja [a análise das referências e as diferenças](REFERENCE.md).

- Biblioteca flutuante com 13 itens, dock colorido e Central MR.
- Botão **Ver ambiente**: câmera ao fundo, compartilhada com a direção e as mãos.
- **Alvos Neon**, **Memória Espacial** e **Putt Verde**: minijogos próprios,
  sem câmera obrigatória ou internet. Recordes salvos no aparelho.
- **Bosque imersivo**: cenário procedural original que acompanha a direção.
- Calibração sem objeto, objeto de referência e seleção com indicador mantidos.
- APK em `quest-android/dist/Harmony-VR.apk`; Android 8 ou superior.

O fundo MR é câmera 2D duplicada nos olhos do VR Box. Não há profundidade,
rastreamento de posição ou compatibilidade com jogos/scripts do app de referência.
As bibliotecas/modelos de mãos e objetos precisam de internet; o resto é local.

## Versão anterior e detalhes técnicos — sensor visual de rotação

Interface espacial independente, inspirada em headsets VR. A direção principal
usa **somente a câmera**: não requer giroscópio, acelerômetro, bússola nem
permissões de sensores de movimento. Não é software oficial Meta.

## Iniciar

Não requer build nem instalação de dependências para a interface:

```sh
cd quest-vr
python3 -m http.server 8766
```

No computador, abra `http://localhost:8766`. No celular, hospede a pasta em
**HTTPS** para permitir acesso à câmera; HTTP de um IP da rede local costuma
bloquear essa permissão.

## Permissão de câmera e deploy na Netlify

Na primeira abertura aparece **Ativar câmera do dispositivo**. Toque em **Permitir
câmera traseira** para fazer o pedido nativo do navegador. A câmera só é
solicitada depois desse toque. Se o navegador já tiver uma autorização salva,
a câmera pode abrir diretamente, sem mostrar outra janela.

Se a câmera foi recusada anteriormente, JavaScript não pode forçar uma nova
janela ou trocar a decisão do navegador. No ícone ao lado do endereço, abra
as permissões do site e permita Câmera. Confira também a permissão do navegador
nas configurações do celular. Depois, tente novamente.

O aplicativo explica erros de HTTPS, navegador incompatível, política de iframe,
câmera ocupada e permissão bloqueada. Pedidos ignorados expiram em 30 segundos;
se uma autorização chegar depois do cancelamento, o stream é fechado.
A câmera traseira é o padrão para observar o ambiente e é solicitada por preferência, evitando uma exigência rígida
que alguns navegadores rejeitam antes de exibir a permissão. Se o navegador identificar uma câmera diferente da selecionada, ela é
descartada e o app tenta selecionar o dispositivo correto. A frontal continua
disponível em Conforto, mas o padrão desta versão é a traseira.

Para aplicar esta correção em **https://vrzin1.netlify.app/**, envie o ZIP
atualizado como um novo deploy manual do mesmo site. Atualizar o GitHub não
altera um site publicado por upload manual. A raiz do ZIP contém `index.html`
e `_headers`; este último permite câmera no próprio domínio da Netlify e
solicita revalidação do HTML para evitar uma cópia antiga em cache.

Após publicar, atualize a página no Chrome ou Safari. Não é necessário build:
a interface e o fluxo de câmera estão dentro do próprio HTML. Abrir em outra
aba pode ajudar quando uma prévia incorporada bloqueia a solicitação.

## Usar a rotação pela câmera

1. Toque em **Direção pela câmera** e autorize a câmera traseira.
2. Deixe a lente frontal descoberta. Mostre um cenário fixo,
   iluminado e com detalhes, evitando paredes lisas e imagens muito escuras.
3. Aguarde a confirmação da referência. Vire o aparelho para olhar ao redor.
4. Use **Centralizar**, **R**, ou **Conforto → Renovar referência visual** para
   definir novamente a frente.
5. Em Conforto, ajuste Sensibilidade e Suavização. Campo visual estimado
   ajusta a aproximação óptica; não mede automaticamente a lente do celular.

O painel mostra pontos coerentes e erro de reprojeção em pixels. Esse erro
mede a coerência interna da imagem, não a precisão física do ângulo.
Ao perder detalhes ou detectar movimento inconsistente, a visão permanece
parada e aguarda duas leituras válidas para retomar. Não extrapola uma virada
sem imagens novas. Arraste com mouse ou dedo continua disponível.

**Entrar no VR Box** ativa tela dividida. O navegador pode permitir tela cheia
e bloqueio horizontal; caso contrário, gire o aparelho manualmente. Use
**Sair do VR** ou Escape para sair. Este modo não inclui correção óptica
específica das lentes de cada suporte.

## Como o sensor visual funciona

- Seleciona detalhes distribuídos pela imagem e procura correspondências em
  duas escalas, com refinamento de deslocamentos menores que um pixel.
- Verifica semelhança normalizada dos detalhes e correspondências nos dois
  sentidos, reduzindo falsos pares causados por textura repetitiva e exposição.
- Ajusta um modelo de **rotação de câmera em três eixos**, com seleção robusta
  de correspondências (RANSAC) e refinamento da projeção em perspectiva.
- Exige pontos coerentes espalhados em pelo menos três regiões da imagem.
- Acumula a orientação com quaternions, para considerar o efeito da inclinação
  lateral nas próximas viradas. O horizonte da interface permanece nivelado.
- Controla a frequência de processamento conforme o tempo gasto, sem inferir
  grandes movimentos a partir de quadros muito antigos.
- Exclui regiões de mãos quando seus landmarks estiverem disponíveis.

O **assistente adaptativo local** mede ruído e ajusta pesos de três previsores
com base nos erros observados. É um pequeno modelo estatístico de aprendizado
online, não uma rede neural pré-treinada. Neste modo ele suaviza o sinal;
a antecipação permanece desativada para evitar extrapolação visual indevida.
O código não baixa modelos nem envia imagens para estimar a rotação.

### Limites reais

Este método fornece **rotação relativa estimada por visão**, não um sensor
físico, rastreamento 6DoF ou um sistema SLAM completo. Uma câmera monocular não
consegue separar todo deslocamento lateral de uma rotação neste modelo.
Objetos móveis cobrindo grande parte da cena, desfoque, pouca luz, lente
obstruída, distorção óptica e movimentos muito rápidos podem invalidar ou
afetar a estimativa. Erro acumulado ainda é possível: recentralize quando
necessário. Uma perda de imagem não permite recuperar movimentos que não
foram observados. Precisão e conforto dependem do aparelho e do cenário.

## IA de objetos e referência visual

1. Ative a câmera traseira: a IA baixa e inicia automaticamente. Os nomes e
   a confiança aparecem na tela e atualizam conforme você move a câmera,
   mesmo com o painel **Objetos / referência** fechado.
2. Você pode tocar em um objeto ou arrastar para marcar a área dele. Inclua
   bordas ou textura; uma região inteiramente lisa não permite acompanhar.
3. Opcionalmente, escreva um nome, como **caixa**. A referência fica fixada
   e a interface indica câmera estimada à esquerda, direita, acima ou abaixo.
4. O modelo EfficientDet Lite0 int8 identifica objetos automaticamente a cada
   1,2 segundo (1,6 segundo com mãos ativas). Abra o painel para ver as caixas ou escolher uma referência.
   **Recarregar IA de objetos** permite tentar novamente se o download falhar.
5. Use **Limpar referência** para trocar de objeto; **Centralizar** renova o
   ponto de frente. Se o objeto sair da imagem, o sistema procura sua aparência
   novamente e continua pelo cenário quando esse acompanhamento estiver válido.

O modelo detecta categorias conhecidas, como cadeira, garrafa, livro e mesa.
**Caixa de papelão não é uma categoria garantida desse modelo**. A marcação
manual permite acompanhar a caixa sem inventar um reconhecimento semântico.
A lista de objetos não identifica endereços, GPS ou o nome do cômodo.

A referência usa comparação normalizada com uma imagem fixa do objeto,
para evitar que ela seja gradualmente substituída pelo fundo. Quando confiável,
a direção observada do objeto ajuda a corrigir pequenas inconsistências do
modelo de rotação. Se o cenário tiver poucos detalhes, uma referência válida
permite estimar os dois eixos de direção pela posição do objeto na imagem.
Um único objeto não fornece rotação lateral nem posição 3D completas.

**O objeto de referência precisa ficar parado.** Com câmera monocular, mover
um objeto pode parecer movimento da câmera; objetos iguais e grandes mudanças
de aparência também podem impedir o reencontro. Referências incertas não são
forçadas. Recentralize ou marque uma nova área quando necessário.

A IA é executada no aparelho e só infere enquanto o painel de escolha estiver
aberto, reduzindo trabalho durante o uso normal. Depois de fixar o objeto,
o acompanhamento visual leve continua. Se o download da IA falhar, a marcação
manual, a câmera, a direção e os demais controles continuam disponíveis.

O modelo de objetos usa o endereço oficial:
`https://storage.googleapis.com/mediapipe-models/object_detector/efficientdet_lite0/int8/1/efficientdet_lite0.tflite`.
A biblioteca é MediaPipe Tasks Vision 0.10.21, carregada por jsDelivr. Não usa
chave de API nem envia imagens para um serviço de reconhecimento.

## Seleção com círculo de progresso

A pinça foi removida como acionamento. A ponta do indicador move o cursor;
manter o cursor no mesmo botão completa o círculo e seleciona uma vez. Para
repetir, saia do botão e volte. O tempo fica em **Conforto → Tempo de seleção**
e também controla o carregamento pelo dedo. Desativar a seleção pelo olhar não
desativa a seleção por permanência da mão. Um sinal de mão antigo não completa
um clique. Mouse, toque e teclado continuam disponíveis.

## Outros recursos

- Biblioteca com busca sem distinção de acentos e histórico de recentes.
- Menu universal, ajustes rápidos, três cenários e modo foco.
- Notas com salvamento automático neste navegador, sem sincronização.
- Layout móvel com duas colunas e rolagem.
- Mãos com 21 landmarks, filtro One Euro e seleção por permanência, com círculo de progresso.
- Controle por mouse, toque e teclado, mesmo sem câmera.

Ative mãos separadamente. Mantenha o indicador sobre um botão até o círculo
completar; retire o cursor antes de selecionar o mesmo alvo novamente.
A pinça não aciona mais nenhum botão. Essa seleção pelo dedo continua ativa
mesmo quando a seleção adicional pelo olhar estiver desligada.
A seleção por olhar é suspensa durante digitação, movimento rápido e sinal
visual inválido. Em Conforto, ajuste alcance, suavização e tempo de seleção.

Mãos e rotação compartilham uma única câmera e têm controles independentes.
Se o modelo externo de mãos falhar, o sensor visual de rotação continua.

## Privacidade e dependências

Os quadros são processados no aparelho, sem uploads. A câmera pausa ao ocultar
a aba e é liberada ao sair. Notas e preferências ficam no armazenamento local
deste navegador; a interface avisa se ele estiver indisponível.

**Somente as mãos** precisam baixar MediaPipe Tasks Vision 0.10.21 e seu modelo:

- `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.21/`
- `https://storage.googleapis.com/mediapipe-models/hand_landmarker/`

O sensor visual funciona sem esse download, sem chave de API e sem acessar
`DeviceOrientation` ou `DeviceMotion`. O botão de sensores físicos foi retirado
da interface. Rotinas internas de versões anteriores são mantidas para
compatibilidade e testes isolados; não são ativadas pelo fluxo da câmera.

## Testes e evidência

Há dez suítes. As verificações de rotação usam imagens e movimentos conhecidos
gerados matematicamente, e testes de navegador com uma câmera por canvas.
O teste da câmera remove as APIs de sensores físicos e falha se o aplicativo
tentar registrar seus eventos. Também verifica ausência de chamadas externas,
perda de detalhes, referência, permissões e compartilhamento da câmera.

O ajuste de rotação é comparado com uma projeção de referência independente.
As imagens sintéticas cobrem guinada, inclinação vertical, lateral e giros
combinados. O teste aceita erro de até 0,3 grau por eixo nesses exemplos;
isso é uma condição de teste sintética, não uma garantia para celulares.
Quaternions são testados com múltiplas voltas, câmera frontal, mudanças de
referência e rotação com o aparelho inclinado lateralmente.

Com o servidor ativo, execute:

```sh
npm install --prefix /tmp/horizon-web-tests playwright
/tmp/horizon-web-tests/node_modules/.bin/playwright install chromium
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/interface.cjs
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/hands.cjs
node tests/direction.cjs
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/direction-browser.cjs
node tests/visual-motion.cjs
node tests/visual-rotation.cjs
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/visual-browser.cjs
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/camera-permission.cjs
node tests/object-reference.cjs
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/objects-browser.cjs
```

Variáveis opcionais: `QUEST_TEST_URL`, `QUEST_ARTIFACT_DIR` e `CHROMIUM_PATH`.
Em contêineres que exijam isso, `CHROMIUM_NO_SANDBOX=1` configura o Chromium
utilizado nos testes. Os testes de orientação física exercitam apenas rotinas
legadas isoladas e não tornam esses sensores um requisito da interface.

**Validação em celular real ainda pendente.** Imagens sintéticas não comprovam
precisão, desempenho, conforto nem rastreamento de mãos reais. O download do
modelo externo das mãos foi bloqueado no ambiente de desenvolvimento em uma
versão anterior; a direção pela câmera é independente dele.

A suíte de permissão verifica a API real `getUserMedia` no Chromium com câmera
simulada, toque com ativação do usuário, negação, contexto inseguro, política de
acesso, cancelamento e resposta tardia. A confirmação da janela e das permissões
no celular real e no domínio publicado continua dependendo do novo deploy e
das configurações desse navegador.

Os testes de referências cobrem esquerda/direita/acima/abaixo, nomeação,
perda e reencontro, falha do download da IA e seleção manual. A integração
com o detector é testada com resultados simulados; **o modelo real de objetos
não foi executado neste ambiente**. Seu endereço foi confirmado no exemplo
oficial do MediaPipe. As mãos são testadas com landmarks simulados: pinça sem
acionamento, círculo que seleciona uma vez e saída do alvo para rearmar.

### Ponto inicial de direção

Use **Fixar ponto de direção**, toque em um objeto parado ou arraste sua área.
O objeto define a frente inicial. Ao sair da imagem, a direção continua pela
rotação estimada dos detalhes do cenário, sem precisar manter o objeto visível.
O estado informa quando o ponto está memorizado e quando falta textura.
Ao voltar a ver o objeto, a correção só começa após três quadros confirmados.
Sem giroscópio, essa orientação é relativa e pode acumular desvio; pouca luz,
paredes lisas ou movimentos rápidos impedem acompanhar. Não há orientação
absoluta nem garantia de retorno exato após uma volta completa.
A confiança da IA é suavizada entre detecções próximas da mesma categoria.

### Calibração sem objeto

A câmera inicia com calibração do cenário, mesmo sem objetos reconhecidos ou
sem baixar o modelo de IA. Também é possível usar **Calibrar sem objeto**.
Mantenha o celular parado por 1,2 segundo de acompanhamento estável; movimento,
falta de detalhes ou interrupção dos quadros reiniciam a contagem. O progresso
aparece na tela. O ponto define a frente relativa, sem bússola ou giroscópio.
Ao perder o acompanhamento, a visão fica parada na última direção válida.
A calibração não permite medir movimentos diante de uma parede lisa ou no escuro.

## Mãos e modo VR — versão 3.2

O rastreamento mantém dois históricos independentes com identidade por posição,
escala da palma e lateralidade quando disponível. Filtra as duas mãos, valida
articulações, rejeita duplicatas e confirma a detecção antes de exibir. O desenho
usando canvas e o cursor compartilham as mesmas coordenadas de câmera, recorte
e espelhamento; não há ampliação do esqueleto. A perda da mão limpa o cursor
e impede selecionar com uma detecção antiga. O filtro interpola quadros, sem
inventar mãos quando a câmera não as detecta.

No VR, a tela principal, a biblioteca, o dock e os jogos permanecem visíveis
e interativos. Somente os botões externos, prévias e indicadores de diagnóstico
ficam ocultos. Saia com **Voltar** no Android, **Esc** ou **dois toques próximos
fora dos painéis**.
Não há botão de saída visível no VR.

Verificado com detecções simuladas e testes de interface. O desempenho e a
precisão do modelo real ainda precisam de validação no celular, principalmente
quando as mãos se cruzam, ficam escondidas ou há pouca luz.

## Correção de inicialização e mãos offline — 3.2.1

O botão inicial de câmera agora também inicia o rastreamento de mãos, compartilhando
o mesmo stream e reativando a visualização do esqueleto. O modelo oficial MediaPipe
Hands 0.4.1675469240, seu grafo, JS e WASM estão incluídos em `assets/hands/`.
A integridade do pacote npm foi verificada; licença e origem acompanham os arquivos.
O caminho GPU/canvas compatível é o padrão verificado. A direção e a IA de objetos
continuam independentes. O modelo de objetos ainda requer internet.

A confirmação da mão agora tolera o intervalo real entre inferências: um celular
lento não reinicia a confirmação a cada 180 ms. O esqueleto continua sendo apagado
quando a próxima detecção confirma que a mão saiu, e existe prazo máximo para
um resultado pendente. Nenhuma mão falsa é desenhada na ausência de detecção.

Teste `real-hands-browser.cjs`: modelo real e fotografia pública de duas mãos,
21 landmarks por mão, pixels do canvas desenhados, perda/reaquisição e rede
bloqueada. Não é uma validação com câmera de um Android físico.

Para Netlify, envie o ZIP completo com a pasta `assets`, não somente o HTML.
Para Android, o APK já inclui todos os arquivos das mãos.

Versão 3.2.2: restaurado o conteúdo principal no VR, mantendo apenas o HUD externo oculto.

## Otimização preservando os recursos — 3.3

- Mesmo modelo local de mãos, mesma resolução de entrada, 21 pontos, duas mãos
  e mesmos filtros. Saídas de imagem e coordenadas mundiais não usadas deixam
  de ser convertidas em resultados; o sinal de fim de quadro permanece ativo
  para detectar também a ausência de mãos.
- Configurações da câmera e projeções em cache; coordenadas reutilizadas e
  desenho do esqueleto reaproveitado no segundo olho quando as dimensões coincidem.
- Bosque reaproveitado nos dois olhos, projeções de árvores e matriz de rotação
  reutilizadas, menos alocações e cálculos redundantes.
- Frequência das mãos ajustada ao custo real, com intervalo para a interface
  responder em aparelhos lentos; a calibração tolera esse intervalo sem reduzir
  as verificações geométricas.
- Cursores por composição gráfica, referências de elementos em cache e lista
  de objetos atualizada sem recriar botões quando os nomes permanecem iguais.
- APK menor pela remoção apenas do arquivo de modelo de maior complexidade,
  que não é usado: o app continua no mesmo modelo lite, com WASM SIMD e não SIMD.

VR mantém biblioteca, painel principal e dock; só HUD externo fica oculto.
Mãos offline, objetos, direção, calibração, seleção e jogos continuam disponíveis.
Veja a seção 3.3 de [PERFORMANCE.md](PERFORMANCE.md) para os testes e limites.

## Interação espacial e direção — 3.4

O visual anterior foi mantido, com botões e dock maiores e uma moldura mais
próxima de interfaces de headsets. No celular, deslize a barra superior para
alcançar os controles restantes. No VR, a biblioteca e o dock continuam
visíveis; somente os botões e indicadores externos ficam ocultos.

### Mover e organizar abas

- Arraste o título com toque ou mouse. Cada aba guarda sua própria posição.
- Com a mão detectada, mantenha o indicador na alça de mão do título; mova o
  indicador e pare por 1,2 segundo para fixar. Não usa pinça. Retire o indicador
  da alça antes de iniciar outro movimento.
- O ícone de centralizar na janela restaura a posição. Centralizar pelo dock
  também traz a janela ativa para a frente. O título aceita as setas do teclado.
- Até cinco abas ficam no seletor, com apenas um painel ativo desenhado para
  manter o desempenho. Notas, posições e abas são salvas localmente. Os jogos
  abertos mantêm seus estados em memória ao alternar abas.

### Assistente de direção local

A calibração usa estatísticas das rotações visuais para aprender pequenos
desvios de repouso quando há amostras suficientes. A correção é limitada e só
é aplicada quando o desvio é estatisticamente confiável. A suavização acompanha
a qualidade dos pontos e o movimento; saltos isolados de imagem ruim são rejeitados.
Nenhum movimento é previsto quando faltam quadros, e um incremento zero não
gera rotação inventada. O assistente pode ser desligado em Conforto.

A direção continua sendo uma estimativa monocular pela câmera, sem giroscópio,
sem rastreamento de posição 6DoF e sem equivalência ao hardware Meta Quest 3S.
A inspiração de headset é visual e de interação; o aplicativo é independente.

Trocar de aba reaproveita os vídeos, as camadas das mãos e o cenário, sem
reiniciar a câmera. O modelo local de mãos e as otimizações da 3.3 foram mantidos.
Testes incluem movimentos das janelas em toque/mouse/indicador, persistência,
estéreo, preservação do vídeo ao vivo, jogos, direção e mãos com modelo real.

## Mãos com menos travadas — 3.5

O modelo local agora roda em worker, com inferência CPU, sem executar a rede
na thread que desenha os controles. Uma correção pontual no runtime incluído
permite reconhecer as duas mãos nessa execução separada. A imagem enviada ao
rastreador tem até 480 pixels no maior lado; o vídeo de realidade mista mantém
a resolução da câmera. Não há fila de imagens: apenas uma inferência por vez.
Continuam os 21 pontos, a seleção por permanência, as abas móveis e o painel
principal no modo VR. Se o WebView não oferecer suporte, ou o worker falhar,
o app usa automaticamente o motor compatível. APK: versão 3.5, código 10.

O teste com modelo real e foto de duas mãos passou sem internet, incluindo
perda e recuperação das mãos e falha forçada do worker. Os números de
desempenho em computador estão em `quest-vr/PERFORMANCE.md`; não representam
medição em um celular Android.

## Resposta mais rápida das mãos — 3.5.1

Reduzida a suavização dos movimentos rápidos e a interpolação visual extra
(de 18 para 6 ms). O worker pode atualizar até 30 vezes/s, limitado pelo tempo
de inferência e pela chegada de imagens novas. A pausa após cada resposta é
de 4 ms, em vez de 35% do tempo de processamento; o modo de compatibilidade
mantém o orçamento conservador para não travar a interface. Não se acumulam
quadros em fila. A suavização continua reduzindo tremor quando a mão está parada.

O teste de trajetórias sintéticas verifica resposta mais rápida em 15/30/60 Hz,
tremor limitado e convergência quando a mão para. O teste com modelo real
verifica duas mãos, perda, readquisição e fallback. Isso não elimina o atraso
físico da câmera e da inferência nem garante movimento instantâneo no celular.
APK 3.5.1, código 11; mantém a assinatura para atualizar o aplicativo instalado.
