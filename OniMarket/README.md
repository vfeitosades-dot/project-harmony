# OniMarket 2.2 - correção do fechamento automático do /shop

Mod único para **Minecraft Fabric 1.21.11**, Java 21 + Fabric API. Nenhum plugin extra na host.

## Instalação
1. Apague todos os JARs antigos OniMarket da pasta `.minecraft/mods`.
2. Instale somente `OniMarket-1.21.11-2.2.0.jar`.
3. Entre no seu servidor e pressione **P** (alternativa: `/onimarketui`).

## Como usar sem fechar a loja

1. Na aba **IA • LUCRO**, clique **Varrer /shop inteiro**.
2. O OniMarket fecha sua própria janela; **quatro ticks depois** executa `/shop`.
3. A GUI **ONICRAFT | Loja permanece aberta** enquanto o mod lê itens e solicita as próximas páginas, quando possível.
4. O progresso aparece na **barra de ação** e no arquivo `logs/latest.log`, com prefixo `[OniMarket]`.
5. Ao terminar, o mod mostra um aviso no **chat**, mas **NÃO FECHA O /shop**. Pressione **P** quando quiser consultar os resultados.

## Correção importante
A versão 2.1 fechava a loja ao terminar a varredura porque `stopAiScan` chamava `Minecraft.setScreen(new MarketScreen())`. Isso foi removido. A abertura do `/shop` foi adiada quatro ticks para evitar corrida entre o clique e o fechamento da tela do mod.

## O que faz
- Extrai compra e venda dos itens de todas as páginas do /shop reconhecidas
- Mostra todos os produtos analisados e oportunidades de **REVENDER** e de **CRAFT**
- Ordena oportunidades por lucro estimado, sem exigir pesquisa por item
- Quando a loja não tiver operações com lucro, exibe claramente **0 oportunidades** e permite inspecionar os valores coletados
- Não envia `/preco` e **não clica em produtos para comprar ou vender**

## Segurança
A navegação automática só clica em setas de próxima página reconhecidas na GUI. Fecha a varredura após 64 páginas ou 180 segundos. Se o servidor usar outro formato de loja, pode não conseguir navegar automaticamente, mas mantém o inventário aberto.

## Diagnóstico
Se o problema persistir, envie **`.minecraft/logs/latest.log`** depois de reproduzi-lo, ou copie as linhas com `[OniMarket]`. Com essas linhas é possível diferenciar erro de navegação, GUI não reconhecida e fechamento vindo do servidor.

**Nota:** a versão 2.2 passa pela compilação e pelos testes automatizados, mas não foi executada dentro da sua host durante o desenvolvimento. Não é possível garantir comportamento idêntico em todos os servidores sem reproduzir a falha real.
