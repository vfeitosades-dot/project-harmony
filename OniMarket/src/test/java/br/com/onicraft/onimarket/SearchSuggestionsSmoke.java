package br.com.onicraft.onimarket;

import java.util.List;

public final class SearchSuggestionsSmoke {
    private static void check(boolean condition, String message) {
        if(!condition)throw new AssertionError(message);
    }
    public static void main(String[] args) {
        List<String> items=List.of("DIAMOND","DIAMOND_BLOCK","DEEPSLATE_DIAMOND_ORE",
                                  "DIRT","IRON_INGOT","GOLD_INGOT","EMERALD","BAMBOO");
        List<String> dia=SearchSuggestions.find(items,"dia",6);
        check(dia.size()==3,"dias matched count");
        check(dia.get(0).equals("DIAMOND"),"prefix first");
        check(dia.contains("DIAMOND_BLOCK"),"related diamond block");
        check(dia.contains("DEEPSLATE_DIAMOND_ORE"),"substring diamond ore");
        check(SearchSuggestions.find(items,"diamante",6).contains("DIAMOND"),"portuguese alias");
        check(SearchSuggestions.find(items,"ferro",6).contains("IRON_INGOT"),"portuguese iron alias");
        check(SearchSuggestions.find(items,"di",2).size()==2,"max suggestions enforced");
        check(SearchSuggestions.find(items,"xyz",6).isEmpty(),"no matches");
        check(SearchSuggestions.find(items,"",6).isEmpty(),"empty query no popup");
        check(SearchSuggestions.normalize("PÓLVORA").equals("polvora"),"accents");
        check(SearchSuggestions.matches("DIAMOND_BLOCK","bloco de diamante"),"translated name");
        System.out.println("OniMarket autocomplete: 11 testes OK");
    }
}
