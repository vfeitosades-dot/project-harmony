package br.com.onicraft.onimarket;
import java.util.*;
/** Analise deterministica: usa SOMENTE precos efetivamente lidos da loja. */
public final class ProfitEngine {
    private ProfitEngine(){}
    public record Quote(double buy,double sell){}
    public record Ingredient(String item,int count){}
    public record Recipe(String product,int quantity,List<Ingredient> materials){}
    public record Opportunity(String kind,String product,String steps,double cost,double revenue,double profit) {
        public double margin(){return cost>0 ? 100*profit/cost : 0;}
    }
    private static final List<Recipe> recipes=new ArrayList<>();
    private static void add(String out,int count,Object... args){
        List<Ingredient> items=new ArrayList<>();
        for(int i=0;i<args.length;i+=2)items.add(new Ingredient((String)args[i],(Integer)args[i+1]));
        recipes.add(new Recipe(out,count,List.copyOf(items)));
    }
    static {
        for(String wood:List.of("OAK","BIRCH","SPRUCE","JUNGLE","ACACIA","DARK_OAK","MANGROVE","CHERRY","PALE_OAK")){
            add(wood+"_PLANKS",4,wood+"_LOG",1);
        }
        for(String ingot:List.of("IRON","GOLD","COPPER")){
            add(ingot+"_BLOCK",1,ingot+"_INGOT",9);
            add(ingot+"_INGOT",9,ingot+"_BLOCK",1);
        }
        for(String gem:List.of("DIAMOND","EMERALD","REDSTONE","COAL")){
            add(gem+"_BLOCK",1,gem,9);
            add(gem,9,gem+"_BLOCK",1);
        }
        add("LAPIS_BLOCK",1,"LAPIS_LAZULI",9);
        add("LAPIS_LAZULI",9,"LAPIS_BLOCK",1);
        add("STICK",4,"OAK_PLANKS",2);
        add("STICK",4,"SPRUCE_PLANKS",2);
        add("STICK",4,"BIRCH_PLANKS",2);
        add("CRAFTING_TABLE",1,"OAK_PLANKS",4);
        add("CHEST",1,"OAK_PLANKS",8);
        add("CHEST",1,"SPRUCE_PLANKS",8);
        add("FURNACE",1,"COBBLESTONE",8);
        add("HOPPER",1,"IRON_INGOT",5,"CHEST",1);
        add("PISTON",1,"OAK_PLANKS",3,"COBBLESTONE",4,"IRON_INGOT",1,"REDSTONE",1);
        add("STICKY_PISTON",1,"PISTON",1,"SLIME_BALL",1);
        add("REDSTONE_TORCH",1,"STICK",1,"REDSTONE",1);
        add("REPEATER",1,"STONE",3,"REDSTONE_TORCH",2,"REDSTONE",1);
        add("REDSTONE_LAMP",1,"REDSTONE",4,"GLOWSTONE",1);
        add("OBSERVER",1,"COBBLESTONE",6,"REDSTONE",2,"QUARTZ",1);
        add("DROPPER",1,"COBBLESTONE",7,"REDSTONE",1);
        add("BREAD",1,"WHEAT",3);
        add("HAY_BLOCK",1,"WHEAT",9);
        add("WHEAT",9,"HAY_BLOCK",1);
        add("PAPER",3,"SUGAR_CANE",3);
        add("SUGAR",1,"SUGAR_CANE",1);
        add("MELON",1,"MELON_SLICE",9);
        add("MELON_SLICE",9,"MELON",1);
        add("BONE_MEAL",3,"BONE",1);
        add("BONE_BLOCK",1,"BONE_MEAL",9);
        add("SLIME_BLOCK",1,"SLIME_BALL",9);
        add("SLIME_BALL",9,"SLIME_BLOCK",1);
        add("GLOWSTONE",1,"GLOWSTONE_DUST",4);
        add("DRIED_KELP_BLOCK",1,"DRIED_KELP",9);
        add("BAMBOO_BLOCK",1,"BAMBOO",9);
        add("BAMBOO_PLANKS",2,"BAMBOO_BLOCK",1);
        add("SCAFFOLDING",6,"BAMBOO",6,"STRING",1);
        add("TORCH",4,"STICK",1,"COAL",1);
        add("LADDER",3,"STICK",7);
    }
    public static List<Recipe> recipes(){return List.copyOf(recipes);}
    private static boolean ok(double n){return Double.isFinite(n)&&n>0&&n<1e14;}
    public static List<Opportunity> analyze(Map<String,Quote> shop){
        if(shop==null)return List.of();
        Map<String,Quote> p=new HashMap<>();
        for(var e:shop.entrySet())if(e.getKey()!=null&&e.getValue()!=null)
            p.put(e.getKey().trim().toUpperCase(Locale.ROOT),e.getValue());
        List<Opportunity> out=new ArrayList<>();
        for(var e:p.entrySet()){
            Quote q=e.getValue();
            if(ok(q.buy())&&ok(q.sell())&&q.sell()>q.buy())
                out.add(new Opportunity("REVENDA",e.getKey(),"Compre 1 e venda 1",q.buy(),q.sell(),q.sell()-q.buy()));
        }
        for(Recipe r:recipes){
            Quote sale=p.get(r.product());
            if(sale==null||!ok(sale.sell()))continue;
            double cost=0;
            boolean possible=true;
            StringJoiner steps=new StringJoiner(" + ");
            for(Ingredient ing:r.materials()){
                Quote input=p.get(ing.item());
                if(input==null||!ok(input.buy())){possible=false;break;}
                cost+=ing.count()*input.buy();
                steps.add(ing.count()+"x "+ing.item());
            }
            double revenue=r.quantity()*sale.sell();
            if(possible&&ok(cost)&&revenue>cost)
                out.add(new Opportunity("CRAFT",r.product(),steps+" -> "+r.quantity()+"x "+r.product(),cost,revenue,revenue-cost));
        }
        out.sort(Comparator.comparingDouble(Opportunity::profit).reversed().thenComparing(Opportunity::kind));
        return out;
    }
}
