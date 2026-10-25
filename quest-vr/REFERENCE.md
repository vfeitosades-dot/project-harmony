# Referência visual e escopo da versão 3

Análise direta dos dois vídeos enviados pelo usuário em 25/10/2026:

- `ecfbdeb5f115052cb274ac35f311f482.mp4` (12,7 s): título EnJoyTheMR,
  biblioteca flutuante escura, dock colorido e configurações com contornos verdes;
  depois aparece um ambiente de jogo em primeira pessoa com mãos.
- `2f8bbf5010c020291d9eb95a512e11e5.mp4` (42 s): nome EnJoyTheMR/EnJoyTheVR,
  painel sobre imagem de ambiente, esqueleto da mão, demonstração de jogos,
  código Lua e tela de canal/comunidade.

Foram inspecionados quadros em intervalos de 1 segundo no primeiro vídeo e de
5 segundos no segundo. Os vídeos são referências visuais, não instruções de código.
Links de pesquisa Google, YouTube, Play Store e TikTok não puderam ser acessados
neste ambiente (proxy devolveu 403). Não se afirma ter feito pesquisa nessas páginas.

## Implementação própria

Biblioteca de 13 itens, dock colorido, Central MR em três colunas com ações reais,
visão da câmera por trás dos painéis, bosque procedural sensível à rotação,
mãos articuladas já existentes e três minijogos locais: Alvos Neon,
Memória Espacial e Putt Verde. Todos os desenhos e jogos são originais.
Os recordes ficam no armazenamento local; nenhum vídeo ou quadro de câmera é salvo.

Mantidos: seleção por permanência do indicador, rastreamento visual sem giroscópio,
calibração do cenário sem objeto, detecção automática de categorias, objeto como
frente inicial e continuidade pelo cenário quando ele sai da imagem.

## Diferenças que afetam o uso

Não inclui os jogos, modelos, marcas, código ou catálogo do aplicativo original;
não executa seus scripts Lua nem importa jogos de terceiros. Não há locomoção
por braços como no jogo do primeiro vídeo. Os jogos locais usam painéis interativos,
não mundos 6DoF. A visão do ambiente é a mesma imagem 2D em cada olho, sem
reconstrução de profundidade, oclusão real ou rastreamento absoluto. No celular
sem giroscópio, movimentos rápidos, paredes lisas e pouca luz podem perder a
rotação; nesse caso a visão para na última orientação acompanhada.

## Verificação

Playwright: jogos e regras, recordes persistentes, responsividade, câmera simulada
compartilhada, fundo MR duplicado e saída do VR Box, mãos sintéticas, calibração,
perda do objeto e continuidade pelo cenário. Android: compilação, empacotamento,
manifesto e assinatura. O APK ainda precisa de validação em um celular real.
