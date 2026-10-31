# Verificação da beta TRIOBUG

Ambiente: Linux x86_64, Godot oficial 4.6.3 estável. Os testes automatizados usam o código real do jogo e a física da Godot; posicionam robôs/objetos para alcançar os cenários de teste. Não equivalem a uma partida manual completa em PCs Windows separados.

## Executado

- Importação e análise dos scripts sem erros críticos de parsing.
- Teste solo integrado com **27 verificações**: início e HUD, bloqueio/liberação do primeiro núcleo, transporte físico magnético, três habilidades, três desafios, ponte física, restauração de objeto, checkpoints, ativação do reator, saída, encerramento de 8 s e reinício.
- Transporte ENet em **três processos locais**: anfitrião e dois clientes, atribuição de robôs, início de sessão, comandos de clientes e sincronização de estado. Também foram exercitados limite de participantes, desconexão e rejeição de entradas inválidas no teste do transporte.
- Visualização gráfica real pelo renderizador Compatibility em display Xorg virtual; capturas do jogo são imagens da aplicação em execução.

- Teste integrado completo em **três processos separados**, com **39 verificações aprovadas**: movimento e física no servidor, todas as habilidades, três desafios, portas/checkpoints compartilhados, reator, vitória após a saída, encerramento de 8 s, pausa local sem parar o servidor, replay solicitado por cliente e desconexões. Os dois clientes receberam 393 e 380 snapshots na execução registrada. Ações pontuais usam entrega confiável; movimento e snapshots usam atualizações ordenadas sem confirmação.
- Interface conferida em 1280×720 e 1920×1080; resolução, sensibilidade, volume e modo gráfico leve foram exercitados. A saída da sessão multiplayer solicita confirmação.
- Exportação Windows x86_64 concluída com modelos oficiais: um executável com PCK incorporado e um pacote portátil com PCK separado. O conteúdo incorporado no próprio `.exe` também foi aberto pela Godot Linux, em diretório separado, e passou por menu, três robôs, início solo, HUD e créditos/licenças. Foram capturadas imagens reais desse conteúdo exportado. Isso verifica o conteúdo distribuído, sem equivaler à execução nativa do binário Windows.
- O display virtual Linux usa renderização por software e não tem dispositivo de áudio físico; os avisos de VSync e áudio desse ambiente não foram tratados como medição de hardware ou teste de saída sonora.

## Reproduzir no código-fonte

Com Godot 4.6.x instalado e acessível como `godot`, execute na pasta do projeto:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/solo_smoke.gd --fixed-fps 60
python3 tests/run_multiplayer_smoke.py
```

O teste multiplayer abre três processos e requer permissão para sockets UDP locais. O script grava os logs em `multiplayer-test-logs`, ao lado da pasta do projeto, e retorna código diferente de zero em caso de falha.

## Não verificado neste ambiente

- Execução nativa do `.exe` em Windows e compatibilidade de drivers gráficos nesse sistema.
- Partida entre três computadores físicos ou redes distintas; comportamento com latência/perda real de pacotes e configuração de roteadores.
- Meta de 50 FPS no Ryzen 5 5500/RX 550; não foi feita medição nesse hardware.
- Varredura do executável por ferramenta antimalware. Não havia scanner disponível.

O uso dos modelos oficiais, os avisos de licença e os hashes distribuídos documentam a origem e a integridade dos arquivos; não substituem os testes acima.
