# OniMarket 2.1 — analisador de TODAS as ofertas do /shop

Mod único de cliente Fabric 1.21.11. Não precisa de plugin na host.

## Instalar
1. Remova todos os JARs anteriores `OniMarket*.jar` da pasta `.minecraft/mods`.
2. Tenha Minecraft Java 1.21.11, Java 21, Fabric Loader e Fabric API.
3. Instale `OniMarket-1.21.11-2.1.0.jar`.
4. Entre no servidor e pressione **P** (ou execute o comando cliente `/onimarketui`).

## Menu
A aba **IA • LUCRO** abre por padrão e procura **todos** os itens rentáveis; você não precisa digitar um item nem usar /preco. 
- **Varrer /shop inteiro**: abre /shop, percorre as páginas quando reconhece uma seta de próxima página e lê os preços dos itens.
- **Revenda**: TODAS as operações com compra positiva e venda maior que compra, classificadas por lucro.
- **Craft**: receitas conhecidas cujos ingredientes podem ser comprados por menos do que a loja paga no produto final.
- **Todos**: une as duas modalidades.
- **PREÇOS**: lista todos os preços coletados, inclusive os que dariam prejuízo.
- **JOGADORES**: mostra nicks e posições apenas dos jogadores carregados no cliente.

Quando a varredura termina, o próprio menu reabre com os resultados. O rodapé informa páginas visitadas, itens, preços de compra/venda conhecidos, quantidade de revendas e crafts lucrativos.

**Se houver ZERO oportunidades**, o menu mostra os preços coletados e alguns exemplos negativos, em vez de ficar vazio. Não inventa lucro.

## Compatibilidade
Reconhece a estrutura real da loja no código-fonte ONICRAFT v4: título "ONICRAFT | Loja", 45 itens por página, botão de próxima página no slot 53 e marcador de página no 46. Permite até 64 páginas e 180 segundos. Não clica em produtos nem efetua transações.

O catálogo padrão do ONICRAFT v4 tem 242 itens: 214 com compra mais cara que venda e 28 indisponíveis para comprar. Portanto, não existe compra e revenda direta lucrativa nessa configuração original. Se o dono editar os preços no servidor, o mod procura oportunidades usando os preços **atuais** lidos da GUI.

## Limitações
Os números refletem o /shop recebido pelo cliente e podem mudar se o servidor alterar preços, taxas ou regras. O mod não consegue descobrir dados que a host não envia. O cálculo de craft considera receitas pré-mapeadas, não todas as receitas de todos os mods. A compilação e os testes automatizados não substituem um teste conectado ao servidor real.

Se o mod não mostrar resultados, envie print de /shop aberto e `.minecraft/logs/latest.log`.
