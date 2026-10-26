# Harmony MR 3.5 para Android

APK de instalação direta para Android 8.0 ou mais recente. A interface HTML
está incluída no aplicativo: não depende de publicar a última versão na Netlify.
Os modelos de IA e bibliotecas MediaPipe são baixados da internet em tempo de uso.
É necessário Android System WebView/Chrome atualizado. A compilação e a assinatura
são verificadas neste ambiente; câmera, WebGL e desempenho precisam ser conferidos
em um celular real. Não equivale a rastreamento de um headset dedicado.

## Instalar

Baixe `dist/Harmony-VR.apk` no celular, abra o arquivo e permita a instalação
por esse navegador/gerenciador quando o Android solicitar. Abra Harmony MR,
toque para ativar a câmera e conceda a permissão. Em caso de bloqueio permanente,
use Configurações > Aplicativos > Harmony MR > Permissões > Câmera.

O app usa apenas permissões de câmera e internet, sem microfone ou armazenamento.
A interface é servida por uma origem HTTPS interna, com acesso a arquivos locais
desabilitado. Pedidos de câmera só são aceitos dessa origem, após autorização Android.

## Compilar novamente

Instale JDK 21, Android SDK Platform 35 e Build Tools 35.0.0. Exporte
`ANDROID_JAR`, `ANDROID_BUILD_TOOLS` e `QUEST_KEYSTORE` e execute `./quest-android/build.sh`.
Sem `javac`, é possível usar o compilador Eclipse ECJ 3.40.0, informando
`ECJ_JAR` com o caminho do JAR (JRE 21 continua necessário).
A chave de desenvolvimento usa alias `harmony` e senha padrão Android `android`.
Ela fica fora do repositório. Preserve a mesma chave para instalar atualizações;
com outra chave, o Android exigirá desinstalar o app anterior, perdendo dados locais.
Para distribuição em loja, configure sua própria chave de produção e publicação.
O script copia sempre o HTML atual de `quest-vr/index.html` antes de compilar.

A versão 3.0 usa `versionCode=2`, o mesmo identificador de pacote e a mesma chave
da primeira versão para permitir atualização sobre ela. Agora inclui ícone próprio,
interface baseada nos vídeos fornecidos, câmera ao fundo, bosque e três minijogos
originais locais. Não executa scripts nem jogos do EnJoyTheMR/EnJoyTheVR.

A atualização 3.1 usa `versionCode=3` e pede tela de 60 Hz, se houver modo
compatível. A interface mostra o FPS medido; a IA trabalha em frequência menor
para priorizar o desenho. O resultado depende do hardware, do WebView e da
temperatura. Veja `quest-vr/PERFORMANCE.md` para as medições simuladas.

Versão 3.2 (`versionCode=5`): rastreamento de mãos refeito e VR sem HUD ou
painéis. O botão **Voltar** sai do VR; dois toques próximos também saem.
O aplicativo mantém a mesma chave para atualização sobre versões anteriores.

A versão 3.2.1 (`versionCode=6`) inclui o modelo de mãos e as dependências
locais no APK. O botão inicial liga câmera e mãos; o esqueleto é reativado
mesmo se uma versão antiga o tinha salvo como oculto. Os arquivos locais são
servidos pela origem HTTPS interna com MIME apropriado para JavaScript e WASM.
Use `dist/Harmony-MR-3.2.1.apk` para evitar baixar um APK antigo em cache.

Versão 3.2.2 (`versionCode=7`): biblioteca, dock e jogos visíveis e interativos no VR; apenas botões externos e indicadores ficam ocultos.

Versão 3.3 (`versionCode=8`): menos desenho e consultas por quadro, saída de mãos
reduzida aos dados usados e remoção do modelo full não utilizado. Modelo lite,
fallback não SIMD, permissões e funções permanecem iguais.

Versão 3.4 (`versionCode=9`): botões maiores, abas móveis com posições salvas e
assistente local de confiança/calibração da direção. A câmera continua em execução
ao trocar de aba. O modelo local de mãos permanece o mesmo. A interface principal
e o dock são mantidos no VR; apenas o HUD externo fica oculto.

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
