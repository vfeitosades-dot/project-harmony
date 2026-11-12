package br.com.onicraft.onimarket;
public final class PriceParserSmoke {
    static void close(Double actual,double expected) {
        if(actual==null || Math.abs(actual-expected) > .001)
            throw new AssertionError("Esperado "+expected+"; veio "+actual);
    }
    public static void main(String[] args) {
        close(PriceParser.parseNumber("R$ 1.200,50"),1200.50);
        close(PriceParser.parseNumber("$1,200.50"),1200.50);
        close(PriceParser.parseNumber("1.5k"),1500);
        close(PriceParser.parseNumber("10000"),10000);
        close(PriceParser.parse("Comprar: R$ 900 | Vender: R$ 1.250").buy(),900);
        close(PriceParser.parse("Comprar: R$ 900 | Vender: R$ 1.250").sell(),1250);
        close(PriceParser.parse("Preço de compra: 1.200,50").buy(),1200.50);
        close(PriceParser.parse("Preço de venda: 2.500").sell(),2500);
        close(PriceParser.parse("buy: $45 / sell: $75").buy(),45);
        close(PriceParser.parse("buy: $45 / sell: $75").sell(),75);
        close(PriceParser.parse("§aVender por: R$ 1.450").sell(),1450);
        close(PriceParser.parse("Comprar: 55").buy(),55);
        close(PriceParser.parse("Vender: 10").sell(),10);
        close(PriceParser.parse("Comprar: indisponivel").buy(),0);
        close(PriceParser.parse("Vender: indisponivel").sell(),0);
        System.out.println("OniMarket parser: 15 testes OK (inclui a loja ONICRAFT)");
    }
}
