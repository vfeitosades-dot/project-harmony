# Horizon Web — interface espacial

Interface web independente, inspirada nos menus de headsets como o Quest 3S.
Não é software oficial Meta e não reproduz os sensores físicos do headset.

## Iniciar

Não requer build nem instalação de dependências para a interface:

```sh
cd quest-vr
python3 -m http.server 8766
```

Abra `http://localhost:8766` no computador. Para usar câmera e sensores no
celular, hospede esta pasta em **HTTPS**. HTTP de um IP na rede local costuma
bloquear essas permissões.

## Recursos

- Biblioteca com busca sem distinção de acentos e histórico de recentes.
- Menu universal: início, biblioteca, ambientes, notas e ajustes rápidos.
- Três cenários, modo foco e controle de luz do cenário.
- Notas com salvamento automático local, sem sincronização em nuvem.
- Preferências persistentes de conforto, distância e seleção.
- Layout móvel com duas colunas e rolagem; tela dividida para VR Box.
- Mãos com 21 landmarks, duas mãos visíveis e uma principal para apontar.
- Filtro One Euro, aquisição estável e pinça com histerese e trava de repetição.
- Orientação por quaternion, centralização e tratamento da passagem de 360°.
- Mouse, toque e teclado continuam disponíveis sem câmera ou sensores.

## Controles

Arraste para olhar. Clique ou toque para abrir. **R** centraliza a visão.
Use **Ativar mãos** e **Ativar sensores** pelos botões superiores para conceder
permissões. Mostre a mão inteira para a câmera e aponte com o indicador. Abra
polegar e indicador antes de juntá-los; solte antes do próximo clique.

Em **Conforto**, ajuste sensibilidade, suavização, câmera frontal/traseira,
alcance, visualização das articulações e tempo de seleção. A câmera frontal
é espelhada. A seleção por olhar só atua quando mãos ou sensores estão ativos.
Ao digitar, ela é suspensa. Para evitar ações acidentais, pinça e olhar têm
proteção contra repetição; cliques e toques diretos continuam imediatos.

**Entrar no VR Box** ativa duas vistas. Tela cheia e orientação horizontal
são solicitadas quando o navegador permite. **Sair do VR** permanece visível;
Escape também sai. Se o bloqueio de orientação falhar, gire o celular à mão.

## Celular sem giroscópio

Use **Direção pela câmera**, no topo da interface ou nos ajustes rápidos.
Esse modo não depende de `DeviceOrientation` ou `DeviceMotion`, não solicita
permissão de sensores e não precisa baixar o modelo de mãos.

1. Sirva o projeto em HTTPS no celular e autorize a câmera.
2. Em Conforto, prefira **Câmera traseira · VR Box**. A lente precisa ficar
   descoberta no suporte VR Box.
3. Aponte para um ambiente fixo, iluminado e com detalhes. Faça movimentos
   lentos; use **Centralizar** para renovar a referência.
4. Se a rotação parecer forte ou fraca, ajuste Sensibilidade ou Campo visual
   estimado. O campo visual é uma aproximação, não uma calibração óptica do
   aparelho. A antecipação é desativada neste modo para evitar extrapolações.

O rastreador visual compara pequenos pontos entre quadros em duas escalas,
verifica os correspondentes nos dois sentidos, refina deslocamentos menores
que um pixel e exige consenso em pelo menos três regiões da imagem. Quando
as mãos estão sendo rastreadas, suas regiões são excluídas dessa estimativa.
O assistente adaptativo local suaviza os ângulos estimados.

Poucos detalhes, correspondências inconsistentes, oclusões e movimentos fora
da janela de busca suspendem a integração. A referência é renovada, sem
continuar uma virada inventada. O painel mostra quantos pontos são coerentes.
Arrastar com mouse ou dedo continua disponível.

Este é **movimento relativo estimado pela imagem**, não um giroscópio virtual
preciso, rastreamento 6DoF ou odometria visual completa. Câmera monocular não
separa, neste método, o deslocamento lateral de uma rotação. Objetos móveis,
uma mão cobrindo grande parte da câmera sem landmarks disponíveis, mudanças
de iluminação e erro acumulado podem afetar a direção. Recentralize quando
necessário. A qualidade real depende do celular e do cenário.

Mãos e direção visual compartilham uma única câmera, mas podem ser ligadas e
desligadas separadamente. Se o modelo externo das mãos falhar, a direção
visual continua. Câmera e sensores de orientação são modos de direção
alternativos: iniciar um desativa o outro, preservando a posição atual.
Os quadros são processados localmente, sem uploads ou API de IA.

## Direção assistida · IA local

Em **Conforto → Assistente de direção**, mantenha o assistente adaptativo
ativado e, depois de ativar os sensores, escolha **Calibrar estabilidade**.
Olhe para frente e mantenha o aparelho parado por aproximadamente um segundo.
Se houver movimento ou falta de sinal, a calibração aguarda estabilidade e
expira em sete segundos. Centralizar com R continua disponível imediatamente.

O assistente é um pequeno modelo de aprendizado online, não uma rede neural
pré-treinada: compara três previsores (repouso, velocidade constante e
velocidade amortecida), atualiza os pesos conforme os erros observados e estima
o ruído do sinal nesta sessão. Não baixa modelos nem envia dados para uma API. No modo visual, recebe
ângulos derivados da câmera processada localmente; no modo de sensores,
recebe as leituras de orientação. O modelo de mãos MediaPipe é um recurso separado.

- Filtro mais firme em repouso e resposta mais rápida durante movimentos.
- Tendência de movimento estimada por uma pequena janela de amostras.
- Antecipação ajustável de 0–35 ms, limitada a dois graus por eixo.
- Antecipação suspensa em repouso confirmado, reversões e sinal antigo.
- Giroscópio auxiliar, quando autorizado, confirma movimento/repouso.
- Saltos isolados são rejeitados; um salto persistente com giroscópio em
  repouso pode ser compensado sem deslocar a visão. Sem essa confirmação,
  uma nova posição sustentada é aceita, em vez de ser apagada indefinidamente.
- Rotação da tela, retorno à aba e interrupções longas preservam o centro
  atual. Olhar quase vertical mantém a elevação sem inventar um novo azimute.
- O olhar não seleciona apps durante calibração, movimento rápido ou sinal
  desatualizado. A pinça permanece independente desse bloqueio do olhar.

O painel exibe a frequência efetivamente observada, estado do estimador e
contagem de amostras rejeitadas. A permissão de movimento é opcional: se for
recusada, a orientação continua funcionando sem a confirmação do giroscópio.
As permissões de orientação e movimento são solicitadas a partir do toque
original, conforme as restrições dos navegadores móveis.

### Evidência em sinais sintéticos

O teste `tests/direction.cjs` usa sinais determinísticos a 30, 60 e 120 Hz.
A comparação usa o filtro anterior com constante de suavização de 90 ms.
Neste cenário, a redução do ruído em repouso foi de aproximadamente 28%.
Na trajetória constante de 60 graus/s a 60 Hz, o erro RMS do estimador caiu
de 4,91 para 0,23 grau, com antecipação configurada em 18 ms. Esses números
medem o estimador sobre sinais artificiais; não são uma medição de latência
fim a fim ou uma garantia de precisão em aparelhos reais.

Sensores reais, interferência magnética, atrasos do navegador e desempenho do
aparelho continuam limitando o resultado. O assistente não recupera dados
físicos ausentes nem garante eliminar toda deriva de orientação.

## Privacidade e compatibilidade

Os quadros da câmera são processados no aparelho. O código não faz upload de
imagens nem notas. A câmera pausa quando a aba é ocultada e é liberada ao sair.
Notas e preferências ficam no armazenamento deste navegador; não há backup ou
sincronização automática. Se o armazenamento estiver bloqueado, a interface
avisa que o texto existe somente na sessão atual.

O rastreamento de mãos baixa MediaPipe Tasks Vision **0.10.21**, seus arquivos WASM e
o modelo oficial Hand Landmarker. Estes destinos precisam estar acessíveis:

- `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.21/`
- `https://storage.googleapis.com/mediapipe-models/hand_landmarker/`

A primeira ativação das mãos exige internet; a direção visual não depende
desse download. GPU é tentada primeiro, com alternativa
em CPU. O processamento ajusta a frequência de inferência. Permissões, sensores,
desempenho e iluminação dependem do aparelho. Se o modelo não carregar, o erro é
exibido e os demais controles permanecem disponíveis.

O modo VR Box é uma interface em tela dividida, com pequeno deslocamento entre
olhos. Não inclui correção óptica específica de cada lente. Não implementa
rastreamento 6DoF, câmera de profundidade, controles Touch, limites físicos de
segurança, passthrough estereoscópico ou sistema operacional Horizon OS.

## Verificação

Testes funcionais em Chromium cobrem busca, notas e persistência, texto tratado
com segurança, recentes, temas, controles, permissões recusadas, entrada/saída
do VR e layout móvel. A regressão de mãos usa **landmarks sintéticos**, verifica
aquisição, rearme e clique único por pinça, além de falha de armazenamento.

Para reproduzir com o servidor acima ativo:

```sh
npm install --prefix /tmp/horizon-web-tests playwright
/tmp/horizon-web-tests/node_modules/.bin/playwright install chromium
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/interface.cjs
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/hands.cjs
node tests/direction.cjs
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/direction-browser.cjs
node tests/visual-motion.cjs
NODE_PATH=/tmp/horizon-web-tests/node_modules node tests/visual-browser.cjs
```

Variáveis opcionais: `QUEST_TEST_URL`, `QUEST_ARTIFACT_DIR` e `CHROMIUM_PATH`.
Em um contêiner que exija isso, `CHROMIUM_NO_SANDBOX=1` configura o Chromium dos
testes. Os scripts usam apenas o navegador para teste, sem alterar a aplicação.

O download do modelo externo foi bloqueado no ambiente de desenvolvimento
(HTTP 403 na versão anterior). A inferência com mãos reais, a precisão dos
sensores físicos e o conforto com lentes precisam ser validados em um celular
real. Os testes simulados não comprovam esses resultados.

Os testes visuais usam quadros sintéticos e uma câmera gerada por canvas no
Chromium, sem emitir eventos de orientação. Cobrem direção dos eixos, movimento
subpixel, exposição, regiões móveis, falta de textura, compartilhamento da
câmera, falha do modelo de mãos e permissões. Não foram executados em uma
câmera física; precisão e conforto devem ser verificados no seu celular.
