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

## Privacidade e compatibilidade

Os quadros da câmera são processados no aparelho. O código não faz upload de
imagens nem notas. A câmera pausa quando a aba é ocultada e é liberada ao sair.
Notas e preferências ficam no armazenamento deste navegador; não há backup ou
sincronização automática. Se o armazenamento estiver bloqueado, a interface
avisa que o texto existe somente na sessão atual.

O rastreamento baixa MediaPipe Tasks Vision **0.10.21**, seus arquivos WASM e
o modelo oficial Hand Landmarker. Estes destinos precisam estar acessíveis:

- `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.21/`
- `https://storage.googleapis.com/mediapipe-models/hand_landmarker/`

A primeira ativação exige internet. GPU é tentada primeiro, com alternativa
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
```

Variáveis opcionais: `QUEST_TEST_URL`, `QUEST_ARTIFACT_DIR` e `CHROMIUM_PATH`.
Em um contêiner que exija isso, `CHROMIUM_NO_SANDBOX=1` configura o Chromium dos
testes. Os scripts usam apenas o navegador para teste, sem alterar a aplicação.

O download do modelo externo foi bloqueado no ambiente de desenvolvimento
(HTTP 403 na versão anterior). A inferência com mãos reais, a precisão dos
sensores físicos e o conforto com lentes precisam ser validados em um celular
real. Os testes simulados não comprovam esses resultados.
