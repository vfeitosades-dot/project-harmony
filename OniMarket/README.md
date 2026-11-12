# OniMarket 1.9 — Fabric 1.21.11 (somente o cliente)

**JAR único.** Não precisa instalar plugin no servidor.

## Instalação
- Minecraft Java 1.21.11, Java 21, Fabric Loader e Fabric API
- Remova **todas** as versões anteriores de OniMarket da pasta `.minecraft/mods`.
- Coloque `OniMarket-1.21.11-1.9.0.jar` na mesma pasta.
- Entre no servidor, pressione **P** ou use `/onimarketui`.

## Aba ECONOMIA
O mod carrega **242 itens de referência** do projeto ONICRAFT 5.1, mesmo antes de acessar a loja. **Esses valores não são garantidos como atuais**: são identificados com um asterisco (*) e o rodapé indica quantos são referência.
Abra `/shop` e percorra as páginas. As descrições de itens do inventário são analisadas e os preços reais passam a substituir os valores de referência, que deixam de ter o asterisco. Se uma compra ou venda não estiver disponível, mostra `--`. A comparação só usa preços conhecidos e positivos.

**Não é possível garantir o preço atual de todas as páginas sem o servidor enviar os dados.** O mod não compra ou vende nada automaticamente.

## Aba JOGADORES
Mostra os nicks disponíveis na lista TAB e, no mínimo, o seu próprio jogador. X/Y/Z são mostrados somente para entidades de jogadores que o cliente realmente tem carregadas. Para jogadores distantes, `--` significa coordenadas desconhecidas. Nenhum plugin é necessário.

## Diagnóstico
Se o conteúdo real da loja não for capturado, o rodapé mostra a última janela analisada e o número de capturas. Ao informar um erro, compartilhe o arquivo `.minecraft/logs/latest.log` e, se possível, uma imagem de `/shop` com o item selecionado.

## Pesquisa com sugestões (1.9)
No menu (tecla P), digite qualquer parte do nome de um item no campo de pesquisa. O catálogo é filtrado ao vivo e até seis sugestões aparecem imediatamente abaixo do campo. Clique em uma opção para selecioná-la. Itens que começam com o texto digitado aparecem primeiro. Os nomes também aceitam buscas em português para itens comuns (ex.: `diamante`, `ferro`, `pedra`). A aba JOGADORES também aceita busca instantânea por nick.

## Correção da tabela vazia (1.9)
Foi corrigida a ordem de renderização no Minecraft 1.21.11: primeiro o fundo/widgets, depois o conteúdo da tabela (em versões anteriores o fundo era desenhado por cima dos textos). Os resultados da busca e os nomes dos jogadores ficam visíveis, com aviso explícito quando o filtro não encontra correspondência. Há botão **Limpar busca** no rodapé e as sugestões continuam aparecendo por cima da tabela.

## IA de lucro (v1.9)

Abra a tecla **P** -> **IA • LUCRO** -> **Iniciar varredura /shop**.

- O cliente usa `/shop` para abrir a interface e analisa preços que o servidor enviar.
- Para avançar de página, o leitor só clica em itens do tipo *seta* rotulados inequivocamente como "Próxima página" ou "Next Page". A varredura tem limite de 24 páginas e 120 segundos. Se a GUI usar outro nome ou botão, a varredura termina com um diagnóstico — não tenta comprar produtos nem deduzir botões.
- A seção IA compara preços efetivamente coletados nesta sessão para detectar **REVENDA** (comprar por menos e vender por mais) e **CRAFT** (custo dos ingredientes vs venda da quantidade produzida) a partir de receitas básicas predefinidas.
- Cada oportunidade mostra tipo, produto, custo, receita, lucro e materiais necessários. Os números valem por operação e não incluem taxas, combustível, custos extras ou limites do servidor.
- **Nunca** usa os preços dos 242 itens de referência para recomendar lucro. Se não houver preços reais suficientes, o menu diz que não há oportunidades verificadas.
- É um analisador de regras matemáticas offline, não um modelo de IA treinado. Não há promessa de lucro ou compatibilidade automática com todas as lojas: isso depende do formato de GUI e das mensagens do servidor.

Retorne ao menu com **P** depois que a varredura terminar e veja **IA • LUCRO**.
