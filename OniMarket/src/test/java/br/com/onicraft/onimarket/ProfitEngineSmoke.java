package br.com.onicraft.onimarket;
import java.util.*;
public final class ProfitEngineSmoke {
    private static void require(boolean cond,String message){if(!cond)throw new AssertionError(message);}
    public static void main(String[] args) {
        Map<String,ProfitEngine.Quote> p=new HashMap<>();
        require(ProfitEngine.analyze(p).isEmpty(),"sem dados = sem oportunidades");
        p.put("DIAMOND",new ProfitEngine.Quote(100,145));
        List<ProfitEngine.Opportunity> a=ProfitEngine.analyze(p);
        require(a.size()==1,"revenda encontrada");
        require(a.get(0).kind().equals("REVENDA"),"tipo revenda");
        require(a.get(0).profit()==45,"lucro revenda 45");
        p.clear();
        p.put("WHEAT",new ProfitEngine.Quote(2,-1));
        p.put("BREAD",new ProfitEngine.Quote(-1,10));
        a=ProfitEngine.analyze(p);
        require(a.stream().anyMatch(o->o.kind().equals("CRAFT")&&o.product().equals("BREAD")&&o.profit()==4),
            "craft bread 3 trigo x 2, venda 10, lucro 4");
        p.clear();
        p.put("OAK_LOG",new ProfitEngine.Quote(5,-1));
        p.put("OAK_PLANKS",new ProfitEngine.Quote(-1,3));
        a=ProfitEngine.analyze(p);
        require(a.stream().anyMatch(o->o.product().equals("OAK_PLANKS")&&o.profit()==7),
            "craft 1 tronco para 4 tábuas");
        p.clear();
        p.put("DIAMOND",new ProfitEngine.Quote(150,100));
        require(ProfitEngine.analyze(p).isEmpty(),"prejuízo não é oportunidade");
        p.put("IRON_BLOCK",new ProfitEngine.Quote(-1,1000));
        require(ProfitEngine.analyze(p).isEmpty(),"sem ingrediente não recomendar craft");
        p.put("IRON_INGOT",new ProfitEngine.Quote(0,5));
        require(ProfitEngine.analyze(p).isEmpty(),"preço zero nunca significa compra grátis");
        p.clear();
        p.put("BAMBOO",new ProfitEngine.Quote(1,2));
        p.put("BAMBOO_BLOCK",new ProfitEngine.Quote(15,20));
        a=ProfitEngine.analyze(p);
        require(a.stream().anyMatch(o->o.product().equals("BAMBOO_BLOCK")&&o.kind().equals("CRAFT")
            &&o.profit()==11),"bambu 9 por 1 e venda 20 = 11 de lucro");
        // Verifica a varredura de centenas de itens sem pesquisar nada individualmente.
        p.clear();
        for(int i=0;i<240;i++)p.put("BLOCK_"+i,new ProfitEngine.Quote(100,25));
        p.put("LUCRO_A",new ProfitEngine.Quote(20,35));
        p.put("LUCRO_B",new ProfitEngine.Quote(45,120));
        a=ProfitEngine.analyze(p);
        require(a.stream().filter(o->o.kind().equals("REVENDA")).count()==2,
            "deve achar ambos os itens lucrativos entre 242 ofertas");
        require(a.stream().anyMatch(o->o.product().equals("LUCRO_A")),"lucro A presente");
        require(a.stream().anyMatch(o->o.product().equals("LUCRO_B")),"lucro B presente");
        System.out.println("OniMarket ProfitEngine: testes de 242 itens + 14 casos OK");
    }
}
