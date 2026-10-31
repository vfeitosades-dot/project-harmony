# TRIOBUG — Amigos em Pane!

Beta cooperativa 3D para 1–3 jogadores. Três robôs escapam do Laboratório Zero usando magnetismo, baixa gravidade e um cabo elástico. Projeto em Godot 4.6.3 estável, GDScript, renderizador Compatibility/OpenGL.

## Baixar o jogo

[Baixar TRIOBUG para Windows 64 bits](downloads/TRIOBUG-Windows.zip?raw=true). Extraia o ZIP inteiro e abra `TRIOBUG.exe`.

## Abrir no Windows

Abra `TRIOBUG.exe` em Windows 64 bits. A versão com os dados incorporados funciona com um único executável. Se estiver usando o pacote portátil com `TRIOBUG.pck` separado, extraia o ZIP inteiro e mantenha o `.exe` e o `.pck` na mesma pasta. Não é necessário instalar Godot, pedir acesso de administrador ou desativar o antivírus.

Escolha **Jogar solo** ou **Hospedar partida**. As configurações permitem alterar resolução, tela cheia, VSync, modo gráfico leve, sensibilidade do mouse e volume.

## Controles

| Ação | Controle |
| --- | --- |
| Andar / correr | WASD / Shift |
| Pular | Espaço |
| Girar câmera / ajustar distância | Mouse / roda do mouse |
| Usar habilidade; cancelar magnetismo ou cabo | Clique esquerdo |
| Trocar de robô disponível | Tab ou 1 / 2 / 3 |
| Restaurar núcleo perto da estação amarela | E |
| Reunir equipe e restaurar objetos pendentes no checkpoint | R |
| Pausa / continuar | Esc |

No solo, os outros robôs permanecem onde foram deixados; seus mecanismos já ativados continuam válidos. Com dois jogadores, é possível assumir o terceiro robô quando estiver livre. Com três, cada participante ocupa um robô. R reúne toda a equipe no checkpoint no solo; em rede, retorna apenas o robô de quem pressionou a tecla. A pausa online interrompe apenas os comandos locais.

## Habilidades e solução dos desafios

**Bipo, amarelo:** conecta o núcleo metálico mais próximo dentro de 7 m. O núcleo acompanha um ponto à frente do robô; mova Bipo e gire a câmera para levá-lo ao encaixe luminoso. Outro clique solta o objeto.

**Gravi, ciano:** cria um campo de baixa gravidade por 5 s, com alcance próximo de 8 m e raio de 3 m. Olhe na direção do núcleo desejado antes de clicar. Há 2 s de recarga após o campo terminar.

**Liga, coral:** conecta a âncora rosa mais próxima em até 10 m. Outro clique desfaz o cabo. Alguns dispositivos ficam travados depois de ativados, facilitando o solo.

1. **O despertar:** aproxime Liga da âncora rosa e clique para liberar o suporte. Troque para Bipo, atraia a esfera e caminhe até o encaixe ciano. A porta abre e salva o primeiro checkpoint. Use R para reunir a equipe.
2. **Gravidade quebrada:** Gravi aplica o campo no núcleo perto da entrada. Liga se aproxima do vão e conecta a âncora do outro lado para estender a ponte. Bipo transporta o núcleo pela ponte até o terminal. O efeito de estabilização fica registrado mesmo depois de o campo terminar. A porta abre e salva o segundo checkpoint.
3. **O núcleo central:** Bipo leva a esfera ao módulo magnético à esquerda. Gravi sustenta com o campo o núcleo do dispositivo ao fundo por 3 s. Liga mantém o cabo no dispositivo rosa à direita por 3 s. Os três módulos permanecem ativados; não precisam ser acionados ao mesmo tempo. Atravesse a saída liberada para ver o encerramento de 8 s e as opções de jogar novamente ou voltar ao menu.

Objetos fora do mapa retornam ao suporte. As estações amarelas com E restauram o núcleo ainda pendente da sala; R reúne a equipe no último checkpoint sem apagar os desafios resolvidos.

## LAN e IP direto

O anfitrião seleciona **Hospedar partida**, escolhe a porta UDP — padrão **24569** — e informa seu IP aos outros participantes. Os amigos escolhem **Entrar em partida**, digitam esse IP e a mesma porta. Quando os participantes estiverem no lobby, o anfitrião inicia. O limite é de três participantes no total.

Na mesma máquina, use `127.0.0.1` para testes. Na mesma rede, use o endereço local do anfitrião. Caso o Windows solicite permissão de rede, o jogo utiliza UDP para a partida. Conexões fora da LAN podem exigir encaminhamento de porta e uma rede sem bloqueio por CGNAT; esta beta não oferece matchmaking, convites ou retransmissão pela internet.

O anfitrião controla a física compartilhada, os dispositivos, as portas e a vitória. Entradas dos clientes são validadas. Se o anfitrião sair, a sessão termina; não há migração de servidor.

## Abrir e exportar o código-fonte

Importe `project.godot` no editor oficial Godot **4.6.3** e pressione F5 para iniciar o jogo. Instale os modelos oficiais de exportação da mesma versão em **Editor → Gerenciar modelos de exportação**. No preset **Windows Desktop**, use arquitetura x86_64 e substitua eventuais caminhos locais de modelos personalizados, ou deixe-os vazios para usar os modelos instalados.

Crie a pasta `builds` e execute, a partir da pasta do projeto:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --export-release "Windows Desktop" builds/TRIOBUG.exe
```

No preset, **Embed PCK** define se os dados ficam incorporados no `.exe`. Com a opção desligada, distribua também o `.pck`. Inclua a pasta `licenses` e estes avisos junto à distribuição. Não há dependências de plugins, backend, contas ou chaves de API.

Preferências são gravadas em `user://preferences.cfg`, normalmente em `%APPDATA%\Godot\app_userdata\TRIOBUG - Amigos em Pane!\` no Windows. O jogo não inclui telemetria nem pede privilégios administrativos.

## Verificação e limites

Consulte `TESTES.md` para os testes executados e como reproduzi-los. O executável Windows foi exportado a partir de modelos oficiais; execução nativa no Windows, medição no Ryzen 5/RX 550 e análise por antivírus não foram realizadas neste ambiente Linux. Não há garantia de FPS para um hardware específico.

## Licenças

Código original: MIT, em `LICENSE`. Arte procedural original e áudio sintetizado original: CC0 1.0, em `licenses/ORIGINAL-ASSETS-CC0.txt` e `audio/LICENSE.txt`. Godot e componentes: `licenses/GODOT-LICENSE.txt` e `licenses/GODOT-COPYRIGHT.txt`.
