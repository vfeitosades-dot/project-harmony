# OniMarket 1.6 — Fabric 1.21.11 (somente o cliente)

**JAR único.** Não precisa instalar plugin no servidor.

## Instalação
- Minecraft Java 1.21.11, Java 21, Fabric Loader e Fabric API
- Remova **todas** as versões anteriores de OniMarket da pasta `.minecraft/mods`.
- Coloque `OniMarket-1.21.11-1.6.0.jar` na mesma pasta.
- Entre no servidor, pressione **P** ou use `/onimarketui`.

## Aba ECONOMIA
O mod carrega **242 itens de referência** do projeto ONICRAFT 5.1, mesmo antes de acessar a loja. **Esses valores não são garantidos como atuais**: são identificados com um asterisco (*) e o rodapé indica quantos são referência.
Abra `/shop` e percorra as páginas. As descrições de itens do inventário são analisadas e os preços reais passam a substituir os valores de referência, que deixam de ter o asterisco. Se uma compra ou venda não estiver disponível, mostra `--`. A comparação só usa preços conhecidos e positivos.

**Não é possível garantir o preço atual de todas as páginas sem o servidor enviar os dados.** O mod não compra ou vende nada automaticamente.

## Aba JOGADORES
Mostra os nicks disponíveis na lista TAB e, no mínimo, o seu próprio jogador. X/Y/Z são mostrados somente para entidades de jogadores que o cliente realmente tem carregadas. Para jogadores distantes, `--` significa coordenadas desconhecidas. Nenhum plugin é necessário.

## Diagnóstico
Se o conteúdo real da loja não for capturado, o rodapé mostra a última janela analisada e o número de capturas. Ao informar um erro, compartilhe o arquivo `.minecraft/logs/latest.log` e, se possível, uma imagem de `/shop` com o item selecionado.
