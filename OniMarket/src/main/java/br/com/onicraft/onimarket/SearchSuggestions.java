package br.com.onicraft.onimarket;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/** Busca imediata com prioridade para nomes iniciados pelo texto digitado. */
public final class SearchSuggestions {
    private SearchSuggestions() {}
    private static final Map<String, String> PT = new HashMap<>();

    static {
        alias("DIAMOND","diamante");
        alias("DIAMOND_BLOCK","bloco de diamante");
        alias("DIAMOND_ORE","minério de diamante");
        alias("EMERALD","esmeralda");
        alias("EMERALD_BLOCK","bloco de esmeralda");
        alias("IRON_INGOT","barra de ferro");
        alias("IRON_BLOCK","bloco de ferro");
        alias("IRON_ORE","minério de ferro");
        alias("GOLD_INGOT","barra de ouro");
        alias("GOLD_BLOCK","bloco de ouro");
        alias("GOLD_ORE","minério de ouro");
        alias("COPPER_INGOT","barra de cobre");
        alias("COAL","carvão");
        alias("COAL_BLOCK","bloco de carvão");
        alias("REDSTONE","redstone");
        alias("LAPIS_LAZULI","lápis-lazúli");
        alias("STONE","pedra");
        alias("COBBLESTONE","pedregulho");
        alias("DIRT","terra");
        alias("GRASS_BLOCK","bloco de grama");
        alias("SAND","areia");
        alias("GRAVEL","cascalho");
        alias("GLASS","vidro");
        alias("OBSIDIAN","obsidiana");
        alias("BAMBOO","bambu");
        alias("WHEAT","trigo");
        alias("CARROT","cenoura");
        alias("POTATO","batata");
        alias("APPLE","maçã");
        alias("GOLDEN_APPLE","maçã dourada");
        alias("SUGAR_CANE","cana de açúcar");
        alias("CACTUS","cacto");
        alias("OAK_LOG","tronco de carvalho");
        alias("OAK_PLANKS","tábuas de carvalho");
        alias("ENDER_PEARL","pérola do ender");
        alias("GUNPOWDER","pólvora");
        alias("NETHERITE_INGOT","barra de netherita");
        alias("NETHERITE_BLOCK","bloco de netherita");
        alias("TOTEM_OF_UNDYING","totem da imortalidade");
        alias("SLIME_BALL","bola de slime");
        alias("BONE","osso");
        alias("BLAZE_ROD","vara de blaze");
        alias("CHEST","baú");
        alias("HOPPER","funil");
        alias("PISTON","pistão");
        alias("FURNACE","fornalha");
        alias("TORCH","tocha");
        alias("LANTERN","lanterna");
        alias("BOOK","livro");
        alias("BOOKSHELF","estante de livros");
    }

    private static void alias(String id, String portuguese) {
        PT.put(id, portuguese);
    }

    public static String normalize(String value) {
        if (value == null) return "";
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD);
        return normalized.replaceAll("\\p{M}+", "")
            .replace('_', ' ').replace('-', ' ').toLowerCase(Locale.ROOT).trim();
    }

    public static String displayName(String name) {
        String portuguese = PT.get(name);
        String normal = name.replace('_', ' ');
        return portuguese == null ? normal : portuguese + " (" + normal + ")";
    }

    public static boolean matches(String item, String typed) {
        String query = normalize(typed);
        if (query.isEmpty()) return true;
        return normalize(item).contains(query) ||
            normalize(PT.getOrDefault(item, "")).contains(query);
    }

    private static int rank(String item, String query) {
        String main = normalize(item);
        String alias = normalize(PT.getOrDefault(item,""));
        if (main.equals(query) || alias.equals(query)) return 0;
        if (main.startsWith(query) || alias.startsWith(query)) return 1;
        for (String part : main.split("\\s+")) if (part.startsWith(query)) return 2;
        for (String part : alias.split("\\s+")) if (part.startsWith(query)) return 2;
        return 3;
    }

    public static List<String> find(Collection<String> names, String typed, int max) {
        String query = normalize(typed);
        if (names == null || query.isEmpty() || max <= 0) return List.of();
        List<String> result = new ArrayList<>();
        for (String name : names) {
            if (name != null && matches(name, typed)) result.add(name);
        }
        result.sort(Comparator.comparingInt((String item) -> rank(item, query))
            .thenComparingInt(String::length)
            .thenComparing(String.CASE_INSENSITIVE_ORDER));
        return result.subList(0, Math.min(max, result.size()));
    }
}
