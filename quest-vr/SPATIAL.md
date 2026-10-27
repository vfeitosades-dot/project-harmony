# Janelas espaciais — Harmony MR 3.6.1

Abra Biblioteca, Notas, Ambientes ou um minijogo. Agora até cinco aplicativos
podem permanecer visíveis ao mesmo tempo, cada um com sua posição, rotação,
escala e tamanho. Ao focar um aplicativo, a câmera virtual olha para ele;
a janela continua no mesmo lugar. O dock fica à frente do olhar como uma
barra flutuante em profundidade. Ele não altera as coordenadas dos painéis.

## Controles

| Ação | Mouse, toque ou teclado |
| --- | --- |
| Mover | Arrastar o título; setas com o título focado |
| Redimensionar | Arrastar a alça no canto inferior direito |
| Girar | Alt + arrastar, botão direito + arrastar ou ajustes da janela |
| Aproximar / afastar | Alt + roda, botões Mais perto / Mais longe |
| Mudar escala | Shift + roda ou ajustes da janela |
| Inclinar e ajustar profundidade | Botão de ajustes no cabeçalho |
| Alternar aplicativos | Dock ou seletor de janelas abaixo dele |
| Organizar várias janelas | Último botão do dock, ícone de três painéis |
| Olhar ao redor | Arrastar o fundo, setas ou direção pela câmera |
| Mover a câmera virtual | W/A/S/D; Q/E para subir/descer |
| Centralizar a câmera | R |
| Restaurar uma janela | Ícone de centralizar no cabeçalho |
| Fechar | ×, com animação de saída |

Com as mãos ativadas, mantenha o indicador sobre a alça de mão do cabeçalho
para selecionar. Mova o indicador e pare por 1,2 segundo para fixar. A seleção
continua sendo por permanência, sem pinça. Botões de distância, rotação e
escala também aceitam esse cursor. A câmera e seu modelo local não reiniciam
quando você abre ou alterna aplicativos.

Ao fechar todos os painéis, o dock continua disponível para reabri-los.
As poses e as janelas abertas são salvas localmente, relativamente à origem
da cena. A origem física pode mudar ao iniciar uma nova sessão WebXR. Existe uma janela por
aplicativo; o limite de cinco mantém o custo de composição previsível.
Os minijogos pausam enquanto outro aplicativo está em foco.

## Cena tridimensional

No navegador e no APK, os elementos interativos são planos CSS 3D, filhos de
um mundo com câmera de perspectiva: translate3d, três rotações e escala por
janela. O viewport ocupa a tela; os painéis não usam position:fixed. A origem
óptica da perspectiva corresponde à origem da câmera virtual. Arraste e
redimensionamento usam interseção de um raio com o plano orientado da janela,
em vez de aproximar o movimento com deslocamentos de tela.

Translação da câmera gera paralaxe diferente conforme a profundidade dos
painéis. Rotação e movimento da câmera não sobrescrevem as poses salvas.
Os valores em metros são a escala do espaço virtual (2 mm por unidade),
não uma medição de distância de objetos reais no cômodo.

**No celular sem sensores, a câmera continua estimando rotação relativa.**
Ela não fornece posição 6DoF, SLAM ou uma âncora física persistente no ambiente.
W/A/S/D demonstra a paralaxe de translação da cena virtual. Quando o cenário
real perde detalhes, a estimativa continua com as limitações já documentadas.

## Headset com WebXR

Em navegador HTTPS que anuncie `immersive-vr`, aparece **Entrar no headset VR**.
Esse botão solicita uma sessão WebXR nativa. O renderer WebGL usa as matrizes
de projeção e pose de cada olho, incluindo translação física fornecida pelo
headset, e compartilha os mesmos modelos de posição/rotação/tamanho das janelas.
Uma grade no chão oferece referência de escala. As superfícies são texturas
em quads 3D; a interface HTML não é uma sobreposição fixa dentro do headset.

- Aponte o controle e pressione o gatilho para clicar.
- Segure o gatilho sobre o título ou alça para mover.
- Segure a alça do canto para redimensionar.
- Durante o arraste, o analógico ajusta distância e rotação.
- Ajustes e seletores comuns aparecem como superfícies 3D adicionais.
- A edição de texto é feita no navegador antes de entrar: esta versão não
  inclui teclado virtual para o headset.
- Use o analógico, sem arrastar, para rolar o painel apontado.
- A saída usa o menu do próprio headset; recursos e texturas são liberados
  quando a sessão termina.

O Android WebView do APK normalmente não oferece WebXR imersivo. Nesse caso,
continua disponível o VR Box, que mostra duas vistas da cena e preserva os
painéis, dock e cursor. VR Box não fornece rastreamento físico 6DoF nem transforma
uma câmera comum em passthrough estereoscópico.

## Animação e desempenho

Entradas e saídas animam opacidade e escala, inclusive nos quads WebXR. Foco usa transformações curtas.
A preferência do sistema por movimento reduzido é respeitada. O vidro combina
transparência, gradiente, borda iluminada e sombras. Na versão 3.6.1, o desfoque fica desligado
em todos os modos para evitar artefatos de composição. O efeito de vidro
continua com transparência moderada e gradientes.

Mãos continuam no worker local, sem fila e com a resposta rápida da versão
3.5.1. Superfícies de câmera e esqueletos são reutilizados. No WebXR, texturas
são atualizadas quando o conteúdo muda, com verificação espaçada, e nunca são
rasterizadas a cada quadro. 60 fps é uma meta; hardware, WebView, resolução,
calor e inferência podem limitar a taxa.

## Verificação

`windows-browser.cjs` compara geometria matemática com os limites realmente
pintados pelo navegador, além de arraste, tamanho, rotação, profundidade,
paralaxe, persistência, mãos, VR Box, toque e layout de celular.
`native-xr-browser.cjs` executa WebGL e testa seleção por raios, arraste,
poses compartilhadas, modais e descarte de recursos com poses XR sintéticas.
Não houve validação em headset físico nem medição de latência em celular.

## Estabilidade — 3.6.1

A geometria e a superfície de composição têm o mesmo tamanho. A centralização
fica no plano externo; a animação do conteúdo termina sem reter uma matriz
de transformação. Pequenos afastamentos fixos entre planos evitam conflito
quando duas janelas têm a mesma profundidade. Redimensionar uma janela não
altera o campo de visão das demais. A câmera visual retém ruído inferior a
0,065 grau em repouso; movimentos claros continuam imediatos. A pose WebXR
não passa por esse filtro da câmera de celular.

Ver `tests/stability-regression-browser.cjs`: dimensões de camada, ausência de
animação residual, zoom estável, coerência de dedos/palma, correção e recuperação
de saltos, identidades ao cruzar mãos e desenho agrupado em tela de alta densidade.
O modelo real também é verificado com foto de duas mãos e sem acesso à rede.
Esses testes não substituem validação em um celular físico.
