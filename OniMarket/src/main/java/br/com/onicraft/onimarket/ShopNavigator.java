package br.com.onicraft.onimarket;

import java.text.Normalizer;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Identifica somente interfaces e botões de navegação legíveis.
 * Compatível com a GUI ONICRAFT: 54 espaços, itens 0..44,
 * marcador de página no 46, seta seguinte no 53.
 */
public final class ShopNavigator {
    private ShopNavigator() {}
    private static final Pattern PAGE=Pattern.compile(
        "(?:pagina|page)\\s*(\\d+)\\s*/\\s*(\\d+)", Pattern.CASE_INSENSITIVE);
    public record Page(int current,int total) {
        public boolean last(){return current>=total;}
    }

    public static String normalize(String input) {
        if(input==null)return "";
        String t=Normalizer.normalize(input,Normalizer.Form.NFD).replaceAll("\\p{M}+","");
        return t.replaceAll("(?i)§[0-9a-fk-or]", "").replaceAll("\\s+"," ")
            .toLowerCase(Locale.ROOT).trim();
    }
    public static boolean isShopTitle(String title){
        String t=normalize(title);
        if(t.contains("editar") || t.contains("admin") || t.contains("vender") ||
           t.contains("sell") || t.contains("inventario"))return false;
        return t.contains("loja") || t.contains("shop") || t.contains("mercado");
    }
    public static boolean isOnicraft(String title){
        String t=normalize(title);
        return t.contains("onicraft") && t.contains("loja") && !t.contains("editar");
    }
    public static boolean isNextButton(int index,String itemId,String name,String window) {
        if(itemId==null || name==null)return false;
        String material=normalize(itemId);
        String title=normalize(name);
        if(!material.equals("arrow") && !material.equals("spectral_arrow"))return false;
        if(isOnicraft(window) && index==53 && title.equals("proxima pagina"))return true;
        return title.equals("proxima pagina") || title.equals("proxima") ||
            title.equals("pagina seguinte") || title.equals("next page") ||
            title.equals("next") || title.equals("avancar") ||
            title.equals("proxima pagina >>");
    }
    public static Page page(String description){
        Matcher m=PAGE.matcher(normalize(description));
        if(!m.find())return null;
        try {
            int now=Integer.parseInt(m.group(1)),total=Integer.parseInt(m.group(2));
            return now>=1 && total>=1 && now<=total && total<=500 ? new Page(now,total) : null;
        } catch(NumberFormatException ex){return null;}
    }
}
