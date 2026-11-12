package br.com.onicraft.onimarket;

public final class ShopNavigatorSmoke {
    private static void yes(boolean ok,String why){
        if(!ok)throw new AssertionError(why);
    }
    public static void main(String[] args){
        yes(ShopNavigator.isShopTitle("ONICRAFT | Loja"),"actual shop title");
        yes(!ShopNavigator.isShopTitle("ONICRAFT | Editar loja"),"never scan staff editor");
        yes(!ShopNavigator.isShopTitle("ONICRAFT | Vender"),"never scan sell menu");
        yes(!ShopNavigator.isShopTitle("Inventário"),"never scan own inventory");
        yes(ShopNavigator.isNextButton(53,"arrow","Proxima pagina","ONICRAFT | Loja"),
            "real ONICRAFT next arrow");
        yes(!ShopNavigator.isNextButton(45,"arrow","Pagina anterior","ONICRAFT | Loja"),
            "never click previous arrow");
        yes(!ShopNavigator.isNextButton(0,"diamond","DIAMOND","ONICRAFT | Loja"),
            "never click sale item");
        yes(!ShopNavigator.isNextButton(53,"arrow","Comprar por 300","ONICRAFT | Loja"),
            "never click priced button");
        var page=ShopNavigator.page("Pagina 3/27");
        yes(page!=null && page.current()==3 && page.total()==27,"parse real page marker");
        yes(ShopNavigator.page("Página 27/27").last(),"parse last page");
        yes(ShopNavigator.page("Pagina 5/2")==null,"reject impossible page");
        yes(ShopNavigator.page("Saldo: 100")==null,"reject balance marker");
        System.out.println("OniMarket ShopNavigator: 12 testes OK");
    }
}
