# Harmony MR 3.1 para Android

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
