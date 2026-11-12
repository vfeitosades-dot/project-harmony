# OniMarket 2.0 - leitura automática somente de /shop

**Um único mod cliente Fabric 1.21.11; não precisa de plugin no servidor.**

## Instalação
1. Use Minecraft Java 1.21.11, Java 21, Fabric Loader e Fabric API.
2. Exclua TODOS os `OniMarket*.jar` anteriores da pasta `.minecraft/mods`.
3. Coloque `OniMarket-1.21.11-2.0.0.jar` em `mods/`.
4. Entre no servidor e pressione **P**; alternativa: `/onimarketui`.

## Varredura automática do /shop
- Abra **IA • LUCRO** e clique **Iniciar varredura /shop**, ou no menu **PREÇOS**, clique **IA: varrer loja**.
- O mod executa somente o comando `/shop`. **Não envia `/preco`**, não usa a fila antiga de consultas, não compra nem vende produtos.
- Reconhece a loja do plugin ONICRAFT: janela **ONICRAFT | Loja**, 45 itens por página, marcador **Pagina X/Y** no slot 46 e seta **Proxima pagina** no slot 53.
- Lê **Comprar: N** e **Vender: N** dos textos dos itens; **indisponivel** equivale a não negociável. Espera o inventário estabilizar antes de avançar de página.
- Só clica no botão de navegação **com nome explícito**. Não clica em produtos, compras, vendas ou itens da janela de administração. Para outras lojas com GUI diferente, a navegação pode exigir adaptação.
- Limites de segurança: 64 páginas, 180 segundos, sem transações automáticas.

## IA • LUCRO
O motor analítico compara as cotações coletadas **da loja nesta sessão** para encontrar:
- **REVENDA**: comprar 1 unidade por menos do que a loja paga na venda.
- **CRAFT**: adquirir ingredientes, criar a quantidade indicada por uma receita conhecida e vender o resultado por mais do que o custo dos ingredientes.

A tabela mostra **tipo, item, materiais, custo, venda e lucro** por operação. Não são feitas previsões inventadas. Custos extras e taxas do servidor não são incluídos.

**Importante:** o próprio plugin ONICRAFT possui proteções que impedem muitos negócios com lucro. Se a varredura terminar e nenhuma oportunidade aparecer, isso pode significar que **não há lucro real** nos preços publicados; não é automaticamente um defeito do leitor.

## Aba PREÇOS
Os 242 itens do catálogo antigo são incluídos só como **nomes de referência**, com `--` até que o scanner leia o preço atual no `/shop`. Preços antigos armazenados no computador recebem a marca `*` de histórico e não entram nos cálculos de IA.

## Jogadores
Lista nicks conhecidos pelo cliente Minecraft e as posições de jogadores carregados. Jogadores distantes não expõem coordenadas ao mod sem cooperação do servidor.

## Diagnóstico
Abra `/shop` e observe o título da GUI. A aba IA informa quantas páginas e itens foram lidos e se parou por fim da loja, página repetida ou botão não reconhecido. Se necessário, envie `.minecraft/logs/latest.log` e uma imagem da loja aberta.

## Testes
O GitHub Actions compila o cliente 1.21.11, valida a presença do JAR e executa testes do parser, navegação e cálculo de lucro. O funcionamento real dentro da sua host precisa ser validado no jogo.
