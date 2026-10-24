# Horizon Web — sensor visual de rotação

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

## Usar a rotação pela câmera

1. Toque em **Direção pela câmera** e autorize a câmera traseira.
2. Deixe a lente descoberta no suporte VR Box. Mostre um cenário fixo,
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

## Outros recursos

- Biblioteca com busca sem distinção de acentos e histórico de recentes.
- Menu universal, ajustes rápidos, três cenários e modo foco.
- Notas com salvamento automático neste navegador, sem sincronização.
- Layout móvel com duas colunas e rolagem.
- Mãos com 21 landmarks, filtro One Euro e seleção por pinça sem repetição.
- Controle por mouse, toque e teclado, mesmo sem câmera.

Ative mãos separadamente se quiser apontar com o indicador e selecionar por
pinça. Abra polegar e indicador antes de juntá-los; solte para clicar de novo.
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

Há sete suítes. As verificações de rotação usam imagens e movimentos conhecidos
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
```

Variáveis opcionais: `QUEST_TEST_URL`, `QUEST_ARTIFACT_DIR` e `CHROMIUM_PATH`.
Em contêineres que exijam isso, `CHROMIUM_NO_SANDBOX=1` configura o Chromium
utilizado nos testes. Os testes de orientação física exercitam apenas rotinas
legadas isoladas e não tornam esses sensores um requisito da interface.

**Validação em celular real ainda pendente.** Imagens sintéticas não comprovam
precisão, desempenho, conforto nem rastreamento de mãos reais. O download do
modelo externo das mãos foi bloqueado no ambiente de desenvolvimento em uma
versão anterior; a direção pela câmera é independente dele.
