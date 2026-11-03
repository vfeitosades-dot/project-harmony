# Validacao R6 / UI minimalista

Testes executados com Luau 0.698 e APIs Roblox simuladas. Nao substituem testes no Roblox Studio.

- GAMEPLAY_OK: cinco mundos, 21 handlers, aviso, dano, impulso e explosao
- TESTS_OK: config, settings, catalog, rate limit, map, placement, rejection, undo
- UI_OK: construcao mobile, cinco papeis, seis estados, catalogo, loja, opcoes, ajuda e resultado
- GAMEPLAY_OK: cinco mundos, 21 handlers, aviso, dano, impulso e explosao
- TESTS_OK: config, settings, catalog, rate limit, map, placement, rejection, undo
- R6_OK: rig com sete partes, seis motores e grupo de colisao
- RUNNER_OK: checkpoints sequenciais sem Touched, chegada unica, tres vidas, invulnerabilidade, ajudante e dash validado
- COSMETICS_OK: saldo, compra unica, reequipar gratuito e IDs invalidos
- PASSES_OK: posse validada; id desconhecido, cancelamento e falha de API nao concedem beneficios
- Nomes de classes e enums comparados ao API Dump Roblox: OK.
- 33 scripts extraidos do arquivo final e compilados: OK.
- XML lido e regravado pelo rbxmk 0.9.1, preservando os scripts: OK.

## Ainda exige teste no motor Roblox

Fisica, replicacao entre clientes, camera/controles reais, renderizacao e acessibilidade em dispositivos, DataStore ao vivo e compras reais. Os passes permanecem com ID zero. Audio sem IDs configurados. Use o roteiro LEIA-ME antes da publicacao.
