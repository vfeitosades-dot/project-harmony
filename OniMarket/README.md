# OniMarket 1.5.0 — mod único Fabric 1.21.11

Este projeto é um **mod somente para o cliente**. Não exige plugin na host, nem OP, nem modificar o servidor.

## Instalação
1. Instale Fabric Loader e Fabric API compatíveis com Minecraft Java 1.21.11.
2. Remova versões antigas do OniMarket de `mods/` para evitar mods duplicados.
3. Coloque **somente** `OniMarket-1.21.11-1.5.0.jar` em `.minecraft/mods/`.
4. Inicie o jogo e pressione **P**, ou use o comando local `/onimarketui`.

## Economia
A aba PREÇOS mostra todos os produtos que conseguiu reconhecer em lojas GUI e mensagens. Cada linha possui compra, venda e lucro por unidade. Quando o servidor não divulga algum valor, mostra **--**; preços nunca são inventados. As lojas podem ter formatos diferentes — visite suas páginas após usar `/shop` para coletar os valores.

## Jogadores — limitações importantes
A aba JOGADORES mostra os nicks na lista TAB do servidor, e coordenadas X/Y/Z **somente de jogadores que estão carregados no cliente**, ou seja, geralmente os que estão próximos, na mesma dimensão. Para pessoas distantes, os valores aparecem como `--` e o estado 'fora do alcance'.

**Não há forma de um mod exclusivamente instalado no PC obter as coordenadas globais de outros jogadores se o servidor não enviar esses dados.** O plugin Paper antigo não é usado nesta versão.

## Arquivos
Basta instalar um único arquivo JAR. A versão é para Java 21, Fabric 1.21.11.
