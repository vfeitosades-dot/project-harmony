# VYREL — FPS R6

Abra **VYREL_R6.rbxlx** no Roblox Studio e use Play. O menu, a citadela, as arenas e os bots são criados pelos scripts ao iniciar. O avatar mantém sua aparência, convertido para R6, e a câmera fica em primeira pessoa. Não exige importar meshes ou cadastrar IDs de animação.

## Atualização do menu

Correção da inicialização: a linha visual agora se chama `SelectionLine` e é acessada com `FindFirstChild`, sem conflitar com a propriedade booleana nativa `GuiButton.Selected`. O teste reproduziu a falha anterior (`attempt to index boolean with Visible`) e verifica as seis abas com essa propriedade presente.

Cursor liberado durante o menu e restaurado ao jogar; captura modal reduzida a 1 pixel; camadas decorativas sem captura de cliques; botões com entrada explícita. O carregamento opcional do PlayerModule não bloqueia os eventos da GUI. Sincronização sem alterações mantém os botões existentes. Nova tela inicial, prévias 3D nos cards e rolagem em telas pequenas.

## Conteúdo

- Menu animado: Início, Jogar, Arsenal, Operadores, Loja e Carreira. Armas em prévia 3D, preços, itens possuídos, compra, equipamento e teste gratuito no treinamento.
- Loja com créditos de jogo, destaque diário com desconto de 20% e compras determinadas pelo servidor. Sem sorteios ou cobrança de Robux. Começa com 500 CR, ION, VETOR C4 e NOMAD P9. Cada outro operador custa 220 CR.
- 12 armas com geometrias próprias: VETOR C4, KESTREL K7, LYRA B9, FERAL S5, PULSAR V2, BASIL A1, ARGO D6, TORQ M8, MAREA P8, RUPTURA D2, VESPER H50 e NOMAD P9. Rifles, SMGs, sniper, DMR, LMG, duas escopetas e duas pistolas. Modelos estilizados com referências de construção reais; não são réplicas oficiais de fabricantes.
- Dano maior na cabeça, cadências e recargas distintas, escopetas com vários projéteis, disparo semiautomático ou automático por arma, reserva de munição e troca entre primária/secundária.
- Pose da arma à direita, apoio da mão esquerda, idle, caminhada, corrida, salto, aterrissagem, recarga, inspeção, recoil, dash e gestos de habilidades. As poses do corpo são aplicadas no servidor para os demais jogadores. A apresentação em primeira pessoa usa braços próprios sem colisões.
- VFX de tiro, impacto, rastros, hitmarker, eliminação, dash e habilidades. Informação privada só é enviada para quem pode recebê-la. Sons próprios ainda não foram fornecidos: o catálogo de áudio fica vazio, sem sons externos obrigatórios.

## Modos

**Casual:** arena PvE cooperativa com rodadas de 5 minutos; 2 bots por pessoa, até 6. Recompensa de 6 CR por eliminação e bônus ao terminar a rodada. Bots usam reação, dispersão, recarga, busca, coberturas, movimentação lateral e linha de visão; não atiram através de paredes ou fumaça.

**Treinamento:** alvos estáticos e móveis; todas as armas podem ser experimentadas sem compra. Não concede créditos ou Elo por eliminar os bots.

**Ranqueado:** duelo entre humanos no mesmo servidor, fila aproximada por Elo, primeiro a 5 eliminações ou 4 minutos. Até três duelos simultâneos. Vitória +24 Elo, derrota -18, empate sem alteração; primeiras 5 partidas são provisórias. Sair ou desconectar durante um duelo conta como derrota. A fila não conecta servidores diferentes e não coloca bots no ranqueado.

## Operadores — mantém a roupa e os acessórios do jogador

**ION / mobilidade:** Q Arco condutor (12 de dano + lentidão leve de 2 s); E Trilho de impulso (+12% de velocidade por 3 s); C Eco residual (distração destrutível de 20 HP, sem dano e sem recompensa de eliminação).

**ÂMBAR / suporte:** Q Película cinética (absorve até 25 de dano, 4 s); E Sutura de campo (2 HP/s por 5 s fora de combate); C Tranca de pulso (cobertura de 40 HP por 4 s).

**VÉU / informação:** Q Farol espectral (revela por 0,8 s dentro da linha de visão); E Neblina fragmentada (4 s de fumaça; balas atravessam); C Escuta direcional (sensor de disparos por 6 s; ping privado e breve).

As nove habilidades têm cooldowns no servidor. Nenhuma concede invulnerabilidade. Balanceamento numérico inicial: precisa de avaliação com jogadores reais.

## Controles

WASD mover • Mouse mirar • Clique disparar • Direito ADS • Shift correr • Ctrl ou F dash • R recarregar • H inspecionar • 1/2 trocar arma • Q/E/C habilidades • B menu • Tab placar • V objetivos • M opções. Há botões de toque para ações principais; adaptação completa para controle ainda não foi validada.

O dash é terrestre, percorre cerca de 8 studs, tem cooldown de 4 s e verifica paredes. Não é uma rasteira. Não permite atirar durante sua janela curta e não concede invulnerabilidade.

## Publicação e salvamento

1. Abra o lugar e teste com **Test > Start Server**, usando pelo menos dois jogadores para conferir replicação, fila e duelo.
2. Publique pelo Studio na sua conta/grupo. Para testar persistência no Studio, habilite **Game Settings > Security > Enable Studio Access to API Services** em uma experiência de teste publicada.
3. O DataStore `VYREL_Profile_v1` guarda créditos, compras, equipamento, operador e Elo. Sem acesso ao DataStore, o menu avisa que o progresso é apenas da sessão. Perfil já em uso fica protegido contra compras concorrentes. Não há produtos ou passes pagos configurados.
4. Ajustes de armas: `WeaponCatalog`; agentes: `AgentCatalog` e `SkillService`; economia: `ProfileService`; modos: `SessionService`; arenas: `WorldService`.

O instalador opcional é destinado a um lugar vazio e para instalação fora do Play. O caminho recomendado é abrir o RBXLX incluído. Não instale duas cópias do sistema no mesmo lugar.

## Fontes, Blender e validação

`Fontes/` contém todos os scripts. `Blender/` inclui o arquivo editável com as 12 armas e seus geradores. O jogo usa a geometria nativa equivalente; os bevels do arquivo Blender não são meshes importados automaticamente. `Previas/` contém renders técnicos, não capturas de execução do Roblox Studio. `Referencias.md` documenta a pesquisa de RIVALS/VALORANT; nomes, habilidades e geometrias deste projeto são originais.

O teste de entrada do menu simula hit testing por camadas e a disputa de cursor com a câmera em primeira pessoa; verifica navegação, compra, treino, retorno ao jogo, atalhos, rolagem por toque e limpeza.

Foram executados testes Luau com serviços e física simulados para tiro, munição, dano, movimento, pose, aparência, GUI, economia, habilidades, bots e ciclo de partida. O RBXLX foi lido e regravado pelo rbxmk, verificando referências e preservação dos 36 scripts. Os scripts finais foram compilados com Luau. Esses testes não substituem a validação no motor Roblox: o Studio não estava disponível neste ambiente. Não há garantia de ausência de bugs ou de balanceamento final.
