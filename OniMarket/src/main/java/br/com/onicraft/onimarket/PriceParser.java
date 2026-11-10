package br.com.onicraft.onimarket;

import java.text.Normalizer;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Interpreta textos visíveis ao jogador; nenhum preço é inventado. */
public final class PriceParser {
    private PriceParser() {}
    public record Quote(Double buy, Double sell) {}
    private static final Pattern LABEL = Pattern.compile(
        "(?<![a-z])(?:comprar|compra|comprando|custo|preco de compra|preco da compra|buy|vender|venda|vendendo|sell)(?![a-z])");
    private static final Pattern VALUE = Pattern.compile(
        "(?i)(?:R\\$\\s*|\\$\\s*)?\\d[\\d.,]*(?:\\s*[km])?");
    private static final Pattern COLOR = Pattern.compile("(?i)§[0-9a-fk-or]");

    public static Quote parse(String raw) {
        if (raw == null || raw.isBlank()) return new Quote(null,null);
        String t=Normalizer.normalize(COLOR.matcher(raw).replaceAll(""),Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "").toLowerCase(Locale.ROOT);
        Matcher label=LABEL.matcher(t);
        Double buy=null,sell=null;
        int start=-1;
        boolean isBuy=false;
        while(label.find()) {
            if(start>=0) {
                Double value=findAmount(t.substring(start,label.start()));
                if(value!=null) {if(isBuy) buy=value;else sell=value;}
            }
            String kind=label.group();
            isBuy=kind.startsWith("compr") || kind.startsWith("custo") || kind.startsWith("preco") || kind.equals("buy");
            start=label.end();
        }
        if(start>=0) {
            Double value=findAmount(t.substring(start));
            if(value!=null){if(isBuy)buy=value;else sell=value;}
        }
        return new Quote(buy,sell);
    }
    private static Double findAmount(String seg) {
        if(seg.length()>160) seg=seg.substring(0,160);
        Matcher m=VALUE.matcher(seg);
        String value=null;
        boolean currency=false;
        while(m.find()){
            String v=m.group().trim();
            boolean marked=v.contains("$");
            if(value==null || (marked && !currency)) {
                value=v;
                currency=marked;
            }
            if(marked) break;
        }
        return value==null?null:parseNumber(value);
    }
    public static Double parseNumber(String raw) {
        if(raw==null || raw.isBlank())return null;
        String s=raw.toLowerCase(Locale.ROOT).replaceAll("[^\\d.,km]","");
        double scale=1;
        if(s.endsWith("k")) { scale=1000;s=s.substring(0,s.length()-1);}
        else if(s.endsWith("m")) { scale=1000000;s=s.substring(0,s.length()-1);}
        if(s.isEmpty())return null;
        int c=s.lastIndexOf(','),d=s.lastIndexOf('.');
        if(c>=0 && d>=0){
            s=c>d ? s.replace(".","").replace(',','.') : s.replace(",","");
        } else if(c>=0) {
            if(s.length()-c-1==3 && s.indexOf(',')==c) s=s.replace(",","");
            else s=s.replace(',','.');
        } else if(d>=0) {
            if(s.length()-d-1==3 && s.indexOf('.')==d) s=s.replace(".","");
            else if(s.indexOf('.')!=d) s=s.replace(".","");
        }
        try {
            double value=Double.parseDouble(s)*scale;
            return Double.isFinite(value) && value>=0 && value<1.0e14 ? value : null;
        }catch(NumberFormatException e){return null;}
    }
}
