package br.com.onicraft.onimarket;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandManager;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandRegistrationCallback;
import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.PlayerInfo;
import net.minecraft.client.player.AbstractClientPlayer;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.core.component.DataComponents;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.inventory.ClickType;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.component.ItemLore;
import net.fabricmc.loader.api.FabricLoader;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import org.lwjgl.glfw.GLFW;
import com.mojang.blaze3d.platform.InputConstants;
import java.util.*;

public class OniMarketClient implements ClientModInitializer {
    private static final KeyMapping.Category CATEGORY = KeyMapping.Category.register(net.minecraft.resources.Identifier.fromNamespaceAndPath("onimarket", "general"));
    private static final KeyMapping KEY = KeyBindingHelper.registerKeyBinding(new KeyMapping("Abrir OniMarket", InputConstants.Type.KEYSYM, GLFW.GLFW_KEY_P, CATEGORY));
    private static final Map<String, Prices> prices = new HashMap<>();
    private static final Map<String,ProfitEngine.Quote> observedPrices = new HashMap<>();
    private static List<ProfitEngine.Opportunity> opportunities = List.of();
    private static long observations = 0;
    private static boolean aiScanning = false;
    private static boolean aiShopOpened = false;
    private static boolean aiAwaitNext = false;
    private static long aiStarted = 0, aiLastPageAt = 0;
    private static int aiPages = 0, aiPageHash = 0, aiPendingHash = 0;
    private static long aiPendingSince = 0;
    private static final Set<Integer> aiSeenPages = new HashSet<>();
    private static String aiStatus = "IA pronta: clique em Iniciar varredura.";

    private static final Map<String, PlayerPos> playerPositions = new LinkedHashMap<>();
    private static long positionsUpdatedAt = 0;
    private static class PlayerPos {
        final String name, world;
        final int x,y,z;
        final boolean visible;
        PlayerPos(String name, String world, int x, int y, int z, boolean visible) {
            this.name=name;this.world=world;this.x=x;this.y=y;this.z=z;this.visible=visible;
        }
    }
    private static String serverName = "local";
    private static int capturedChanges = 0;
    private static int scannedSlots = 0;
    private static String lastWindow = "Sem janela de loja";
    private static int tick = 0;
    private static class Prices { double buy = -1, sell = -1; boolean reference = false; }
    @Override public void onInitializeClient() {
        ClientCommandRegistrationCallback.EVENT.register((dispatcher, registryAccess) ->
            dispatcher.register(ClientCommandManager.literal("onimarketui").executes(context -> {
                Minecraft.getInstance().execute(() -> Minecraft.getInstance().setScreen(new MarketScreen()));
                return 1;
            }))
        );
        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            while (KEY.consumeClick()) client.setScreen(new MarketScreen());
            if (client.player == null || client.getConnection() == null) return;
            String name = client.getCurrentServer() == null ? "singleplayer" : client.getCurrentServer().ip;
            if (!serverName.equals(name)) {
                savePrices();
                serverName = name;
                prices.clear();
                observedPrices.clear();
                opportunities=List.of();
                observations=0;
                aiScanning=false;
                aiStatus="IA pronta: clique em Iniciar varredura.";
                playerPositions.clear();
                positionsUpdatedAt=0;
                loadPrices();
                loadReferenceCatalog();
                capturedChanges = 0;
                scannedSlots = 0;
            }
            tick++;
            if(tick%2==0 && client.screen instanceof AbstractContainerScreen<?>)scanShop(client);
            if(tick%10==0) {
                if(aiScanning)autoScanTick(client);
                opportunities=ProfitEngine.analyze(observedPrices);
            }
            if (tick % 10 == 0 && client.level != null) refreshPlayers(client);
            if (tick % 200 == 0) savePrices();
        });
    }
    /**
     * Apenas informações recebidas normalmente pelo cliente.
     * Não usa API de coordenadas do servidor nem acessa jogadores descarregados.
     */
    private static void refreshPlayers(Minecraft client) {
        if(client.level==null || client.getConnection()==null) return;
        Map<String,PlayerPos> snapshot=new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
        for(PlayerInfo info:client.getConnection().getListedOnlinePlayers()) {
            String nick=info.getProfile().name();
            if(nick!=null && !nick.isBlank()) {
                snapshot.put(nick,new PlayerPos(nick,"fora do alcance",0,0,0,false));
            }
        }
        String dimension=client.level.dimension().identifier().toString();
        for(AbstractClientPlayer player:client.level.players()) {
            String nick=player.getName().getString();
            if(nick==null || nick.isBlank())continue;
            snapshot.put(nick,new PlayerPos(nick,dimension,
                player.blockPosition().getX(),player.blockPosition().getY(),
                player.blockPosition().getZ(),true));
        }
        if(client.player!=null) {
            String own=client.player.getName().getString();
            snapshot.put(own,new PlayerPos(own,dimension,
                client.player.blockPosition().getX(),client.player.blockPosition().getY(),
                client.player.blockPosition().getZ(),true));
        }
        playerPositions.clear();
        playerPositions.putAll(snapshot);
        positionsUpdatedAt=System.currentTimeMillis();
    }
    private static void startAiScan(Minecraft client) {
        if(client.player==null || client.getConnection()==null) {
            aiStatus="Entre no servidor antes de iniciar a varredura."; return;
        }
        aiScanning=true;
        aiShopOpened=false;
        aiAwaitNext=false;
        aiPages=0;
        aiPageHash=0;
        aiPendingHash=0;
        aiPendingSince=0;
        aiSeenPages.clear();
        observedPrices.clear(); // nova análise: apenas /shop desta sessão
        for(Prices p:prices.values()) {
            p.reference=true; // histórico fica marcado e não entra nos cálculos
        }
        opportunities=List.of();
        observations=0;
        aiStarted=System.currentTimeMillis();
        aiLastPageAt=aiStarted;
        aiStatus="Abrindo /shop...";
        client.setScreen(null); // feche o painel ANTES de enviar /shop
        client.getConnection().sendCommand("shop");
    }
    private static void stopAiScan(String reason) {
        aiScanning=false;
        aiAwaitNext=false;
        opportunities=ProfitEngine.analyze(observedPrices);
        aiStatus=reason+" | "+aiPages+" páginas, "+observedPrices.size()+
            " itens, "+opportunities.size()+" oportunidades.";
    }
    private static int pageFingerprint(AbstractContainerScreen<?> screen) {
        int total=screen.getMenu().slots.size();
        int n=total>36?total-36:total;
        int hash=17, count=0;
        for(int i=0;i<n;i++){
            ItemStack stack=screen.getMenu().slots.get(i).getItem();
            if(stack.isEmpty())continue;
            hash=31*hash+BuiltInRegistries.ITEM.getKey(stack.getItem()).hashCode();
            hash=31*hash+stack.getHoverName().getString().hashCode();
            ItemLore lore=stack.get(DataComponents.LORE);
            if(lore!=null) for(Component line:lore.lines())
                hash=31*hash+line.getString().hashCode();
            count++;
        }
        return count==0?0:hash;
    }
    private static ShopNavigator.Page currentPage(AbstractContainerScreen<?> screen) {
        List<Slot> slots=screen.getMenu().slots;
        int upper=slots.size()>36?slots.size()-36:slots.size();
        // ONICRAFT reserva o slot 46 para "Pagina X/Y".
        if(ShopNavigator.isOnicraft(screen.getTitle().getString()) && upper>46){
            var page=ShopNavigator.page(slots.get(46).getItem().getHoverName().getString());
            if(page!=null)return page;
        }
        for(int i=0;i<upper;i++){
            ItemStack item=slots.get(i).getItem();
            if(item.isEmpty())continue;
            if(BuiltInRegistries.ITEM.getKey(item.getItem()).getPath().equals("book")) {
                var page=ShopNavigator.page(item.getHoverName().getString());
                if(page!=null)return page;
            }
        }
        return null;
    }
    private static int findSafeNextPage(AbstractContainerScreen<?> screen) {
        List<Slot> slots=screen.getMenu().slots;
        int upper=slots.size()>36?slots.size()-36:slots.size();
        String title=screen.getTitle().getString();
        if(!ShopNavigator.isShopTitle(title))return -1;
        // Primeiro tenta o slot exato da loja ONICRAFT.
        if(ShopNavigator.isOnicraft(title) && upper>53){
            ItemStack arrow=slots.get(53).getItem();
            if(!arrow.isEmpty() && ShopNavigator.isNextButton(53,
                BuiltInRegistries.ITEM.getKey(arrow.getItem()).getPath(),
                arrow.getHoverName().getString(),title))return slots.get(53).index;
        }
        // Alternativa conservadora para outras GUIs compatíveis.
        for(int i=0;i<upper;i++){
            ItemStack stack=slots.get(i).getItem();
            if(stack.isEmpty())continue;
            String id=BuiltInRegistries.ITEM.getKey(stack.getItem()).getPath();
            if(!ShopNavigator.isNextButton(i,id,stack.getHoverName().getString(),title))continue;
            ItemLore lore=stack.get(DataComponents.LORE);
            if(lore!=null) {
                boolean mayTrade=false;
                for(Component text:lore.lines()){
                    PriceParser.Quote q=PriceParser.parse(text.getString());
                    if(q.buy()!=null||q.sell()!=null){mayTrade=true;break;}
                }
                if(mayTrade)continue;
            }
            return slots.get(i).index;
        }
        return -1;
    }
    private static void autoScanTick(Minecraft client) {
        long now=System.currentTimeMillis();
        if(now-aiStarted>180000){stopAiScan("Tempo limite de varredura");return;}
        if(!(client.screen instanceof AbstractContainerScreen<?> screen)) {
            if(!aiShopOpened) {
                if(now-aiStarted>12000)stopAiScan("A loja não abriu. Confira /shop.");
            }else stopAiScan("Loja fechada");
            return;
        }
        if(!ShopNavigator.isShopTitle(screen.getTitle().getString())){
            if(now-aiStarted>12000 || aiShopOpened)
                stopAiScan("Interface diferente de /shop: "+screen.getTitle().getString());
            return;
        }
        aiShopOpened=true;
        // varredura tem limite para nunca fazer clicagem sem controle
        int fingerprint=pageFingerprint(screen);
        if(fingerprint==0)return;
        if(aiAwaitNext) {
            if(fingerprint==aiPageHash) {
                if(now-aiLastPageAt>7000)stopAiScan("Próxima página não respondeu");
                return;
            }
            aiAwaitNext=false;
        }
        // Aguarde a página ficar estável: abertura da GUI e itens podem
        // chegar em pacotes diferentes. Evita pular páginas sem ler preços.
        if(fingerprint!=aiPendingHash) {
            aiPendingHash=fingerprint;
            aiPendingSince=now;
            return;
        }
        if(now-aiPendingSince<350)return;
        if(aiSeenPages.contains(fingerprint)){
            stopAiScan("Página repetida; varredura concluída");
            return;
        }
        aiSeenPages.add(fingerprint);
        aiPages++;
        aiPageHash=fingerprint;
        aiLastPageAt=now;
        opportunities=ProfitEngine.analyze(observedPrices);
        ShopNavigator.Page pageInfo=currentPage(screen);
        aiStatus="Lendo página "+(pageInfo==null?aiPages:pageInfo.current()+"/"+pageInfo.total())+
            " | "+observedPrices.size()+" itens com preços do /shop";
        if(pageInfo!=null && pageInfo.last()) {
            stopAiScan("Última página da loja alcançada");
            return;
        }
        if(aiPages>=64){stopAiScan("Limite de segurança: 64 páginas");return;}
        int nextSlot=findSafeNextPage(screen);
        if(nextSlot<0) {stopAiScan("Finalizado; sem próxima página segura");return;}
        // Apenas a SETA explicitamente rotulada como próxima página.
        // Nenhum clique sobre produtos, e nunca compra ou venda.
        if(client.gameMode!=null && client.player!=null) {
            client.gameMode.handleInventoryMouseClick(
                screen.getMenu().containerId,nextSlot,0,ClickType.PICKUP,client.player);
            aiAwaitNext=true;
            aiLastPageAt=now;
            aiStatus="Próxima página solicitada ("+aiPages+").";
        }else stopAiScan("Cliente sem conexão");
    }

    private static void scanShop(Minecraft client) {
        if(!(client.screen instanceof AbstractContainerScreen<?> screen))return;
        String title=screen.getTitle().getString();
        if(!ShopNavigator.isShopTitle(title))return; // nunca lê /sell ou inventários normais
        lastWindow=title;
        List<Slot> slots=screen.getMenu().slots;
        int n=slots.size()>36 ? slots.size()-36 : slots.size();
        if(ShopNavigator.isOnicraft(title))n=Math.min(45,n);
        for(int i=0;i<n;i++){
            ItemStack stack=slots.get(i).getItem();
            if(stack.isEmpty())continue;
            String id=BuiltInRegistries.ITEM.getKey(stack.getItem()).getPath().toUpperCase(Locale.ROOT);
            if(id.equals("AIR"))continue;
            if(ShopNavigator.isNextButton(i,id,stack.getHoverName().getString(),title))continue;
            ItemLore lore=stack.get(DataComponents.LORE);
            if(lore==null || lore.lines().isEmpty())continue;
            scannedSlots++;
            Prices previous=prices.get(id);
            double buy=previous==null?-1:previous.buy;
            double sell=previous==null?-1:previous.sell;
            boolean ref=previous!=null && previous.reference;
            for(Component line:lore.lines())scanPrice(id,line.getString());
            Prices current=prices.get(id);
            if(current!=null && (current.buy!=buy || current.sell!=sell || ref!=current.reference))
                capturedChanges++;
        }
    }
    private static Path dataFile() {
        String id = serverName.replaceAll("[^a-zA-Z0-9._-]", "_");
        if (id.length() > 70) id = id.substring(0, 70);
        return FabricLoader.getInstance().getConfigDir().resolve("onimarket").resolve(id+".tsv");
    }
    private static void savePrices() {
        try {
            Path file=dataFile();Files.createDirectories(file.getParent());
            List<String> lines=new ArrayList<>();
            for(var entry:prices.entrySet()) {
                Prices p=entry.getValue();
                if(!p.reference)lines.add(entry.getKey().replace("\t"," ")+"\t"+p.buy+"\t"+p.sell);
            }
            Files.write(file,lines,StandardCharsets.UTF_8);
        }catch(Exception ex){System.err.println("[OniMarket] salvar: "+ex);}
    }
    private static void loadPrices() {
        try {
            if(!Files.exists(dataFile()))return;
            for(String line:Files.readAllLines(dataFile(),StandardCharsets.UTF_8)) {
                String[] p=line.split("\t");
                if(p.length!=3)continue;
                Prices v=new Prices();v.buy=Double.parseDouble(p[1]);v.sell=Double.parseDouble(p[2]);
                v.reference=true; // cache antigo, sem confirmação no /shop atual
                prices.put(p[0],v);
            }
        }catch(Exception ex){System.err.println("[OniMarket] carregar: "+ex);}
    }
    private static void loadReferenceCatalog() {
        try(InputStream in=OniMarketClient.class.getResourceAsStream("/onimarket_reference_prices.tsv")) {
            if(in==null){System.err.println("[OniMarket] Catálogo de referência não incluído.");return;}
            try(BufferedReader reader=new BufferedReader(new InputStreamReader(in,StandardCharsets.UTF_8))) {
                String line;
                while((line=reader.readLine())!=null){
                    String[] p=line.split("\t");
                    if(p.length!=3 || p[0].startsWith("#") || prices.containsKey(p[0]))continue;
                    Prices v=new Prices();
                    v.buy=-1;v.sell=-1;v.reference=true; // só nomes; nenhum preço inventado
                    prices.put(p[0],v);
                }
            }
        }catch(Exception ex){System.err.println("[OniMarket] referência: "+ex);}
    }
    private static void scanPrice(String item,String raw) {
        if(item==null || item.isBlank() || raw==null)return;
        PriceParser.Quote q=PriceParser.parse(raw);
        if(q.buy()==null && q.sell()==null)return;
        Prices p=prices.computeIfAbsent(item,k->new Prices());
        if(p.reference){p.buy=-1;p.sell=-1;p.reference=false;}
        if(q.buy()!=null)p.buy=q.buy();
        if(q.sell()!=null)p.sell=q.sell();
        // A IA recebe SOMENTE dados observados nesta sessão, nunca o catálogo antigo.
        ProfitEngine.Quote prev=observedPrices.getOrDefault(item,new ProfitEngine.Quote(-1,-1));
        double buy=q.buy()==null?prev.buy():q.buy();
        double sell=q.sell()==null?prev.sell():q.sell();
        observedPrices.put(item,new ProfitEngine.Quote(buy,sell));
        observations++;
    }
    private static String fmt(double v) {
        if (!Double.isFinite(v) || v < 0) return "--";
        if (v >= 1000000) return String.format(Locale.US, "%.1fM", v / 1000000);
        if (v >= 10000) return String.format(Locale.US, "%.1fk", v / 1000);
        return String.format(Locale.US, "%.2f", v);
    }
    private static class MarketScreen extends Screen {
        private static boolean playersTab = false;
        private static boolean aiTab = false;
        private static int aiPage = 0;
        private static boolean onlyProfit = false;
        private static int sortMode=0;
        private static String searchText="";
        private static int pricePage=0;
        private static int playersPage=0;
        private EditBox filterBox;
        private static final int MAX_AUTOCOMPLETE = 6;
        private final List<Button> autocompleteButtons = new ArrayList<>();
        private final List<Button> shopActionButtons = new ArrayList<>();
        private List<String> autocompleteResults = List.of();
        private boolean autocompleteOpen = false;
        private String status="Catálogo de referência disponível; percorra /shop para obter preços atuais.";
        private int startX, panelW, rowsPerPage;

        MarketScreen() { super(Component.literal("OniMarket")); }
        @Override protected void init() {
            panelW = Math.min(760, width-20);
            startX = (width-panelW)/2;
            rowsPerPage=Math.max(1,(height-189)/16);
            int x=startX;
            addRenderableWidget(Button.builder(Component.literal("PREÇOS"), b -> {
                playersTab=false; aiTab=false; searchText=""; Minecraft.getInstance().setScreen(new MarketScreen());
            }).bounds(x+8,22,Math.min(120,panelW/3),20).build());
            addRenderableWidget(Button.builder(Component.literal("JOGADORES"), b -> {
                playersTab=true;
                aiTab=false;
                searchText="";
                refreshPlayers(Minecraft.getInstance());
                Minecraft.getInstance().setScreen(new MarketScreen());
            }).bounds(x+Math.min(138,panelW/3+14),22,Math.min(120,panelW/3),20).build());
            addRenderableWidget(Button.builder(Component.literal("IA • LUCRO"), b -> {
                playersTab=false; aiTab=true; searchText="";
                opportunities=ProfitEngine.analyze(observedPrices);
                Minecraft.getInstance().setScreen(new MarketScreen());
            }).bounds(x+268,22,Math.min(125,Math.max(75,panelW-315)),20).build());
            addRenderableWidget(Button.builder(Component.literal("X"), b -> onClose())
                .bounds(x+panelW-30,22,22,20).build());

            filterBox=new EditBox(font,x+8,49,Math.max(100,Math.min(260,panelW/3)),20,Component.literal("Pesquisar"));
            filterBox.setMaxLength(70);
            filterBox.setValue(searchText);
            addRenderableWidget(filterBox);

            if(aiTab) {
                addRenderableWidget(Button.builder(Component.literal("Iniciar varredura /shop"), b ->
                    startAiScan(Minecraft.getInstance())).bounds(x+8,76,190,20).build());
                addRenderableWidget(Button.builder(Component.literal("Reanalisar"), b -> {
                    opportunities=ProfitEngine.analyze(observedPrices); aiPage=0;
                    status="Análise atualizada.";
                }).bounds(x+204,76,110,20).build());
                addRenderableWidget(Button.builder(Component.literal("Parar IA"), b ->
                    stopAiScan("Parado manualmente")).bounds(x+320,76,95,20).build());
            } else if (!playersTab) {
                int fx=x+Math.max(115,Math.min(270,panelW/3)+12);
                addRenderableWidget(Button.builder(Component.literal(sortLabel()), b -> {
                    sortMode=(sortMode+1)%4;
                    b.setMessage(Component.literal(sortLabel()));
                    pricePage=0;
                }).bounds(fx,49,Math.max(75,Math.min(145,panelW/4)),20).build());
                int profitX=fx+Math.max(75,Math.min(145,panelW/4))+5;
                if (profitX+95<x+panelW)
                    addRenderableWidget(Button.builder(Component.literal(profitLabel()), b -> {
                        onlyProfit=!onlyProfit; pricePage=0;
                        b.setMessage(Component.literal(profitLabel()));
                    }).bounds(profitX,49,Math.min(130,x+panelW-profitX-8),20).build());
                shopActionButtons.add(addRenderableWidget(Button.builder(Component.literal("Abrir /shop"), b -> send("shop"))
                    .bounds(x+8,76,142,20).build()));
                shopActionButtons.add(addRenderableWidget(Button.builder(Component.literal("IA: varrer loja"), b ->
                    startAiScan(Minecraft.getInstance())).bounds(x+158,76,165,20).build()));
                if(panelW>465)shopActionButtons.add(addRenderableWidget(
                    Button.builder(Component.literal("Ver oportunidades"), b -> {
                        aiTab=true; playersTab=false; searchText="";
                        opportunities=ProfitEngine.analyze(observedPrices);
                        Minecraft.getInstance().setScreen(new MarketScreen());
                    }).bounds(x+331,76,145,20).build()));
            } else {
                shopActionButtons.add(addRenderableWidget(Button.builder(Component.literal("Atualizar jogadores"), b -> { refreshPlayers(Minecraft.getInstance()); status="Lista local atualizada."; })
                    .bounds(x+8,76,190,20).build()));
            }
            addRenderableWidget(Button.builder(Component.literal("◀ Anterior"), b -> {
                if(aiTab) aiPage=Math.max(0,aiPage-1);
                else if(playersTab) playersPage=Math.max(0,playersPage-1);
                else pricePage=Math.max(0,pricePage-1);
            }).bounds(x+8,height-36,110,20).build());
            addRenderableWidget(Button.builder(Component.literal("Próximo ▶"), b -> {
                if(aiTab) aiPage++;
                else if(playersTab) playersPage++;
                else pricePage++;
            }).bounds(x+124,height-36,110,20).build());
            if(panelW>=340) {
                addRenderableWidget(Button.builder(Component.literal("Limpar busca"), b -> {
                    searchText="";
                    autocompleteOpen=false;
                    pricePage=0; playersPage=0;
                    filterBox.setValue("");
                    filterBox.setFocused(false);
                    updateAutocomplete();
                }).bounds(x+240,height-36,Math.min(110,panelW-250),20).build());
            }

            // O menu de sugestões é colocado sobre as ações enquanto o usuário digita.
            // Os botões de ação são ocultados durante a escolha, evitando cliques acidentais.
            int suggestionWidth=Math.max(100,Math.min(260,panelW/3));
            int maxRows=Math.min(MAX_AUTOCOMPLETE,Math.max(1,(height-160)/20));
            for(int i=0;i<maxRows;i++) {
                final int index=i;
                Button option=Button.builder(Component.empty(),button -> {
                    if(index>=autocompleteResults.size())return;
                    String selected=autocompleteResults.get(index);
                    filterBox.setValue(selected);
                    searchText=selected;
                    pricePage=0; playersPage=0;
                    autocompleteOpen=false;
                    filterBox.setFocused(false);
                    updateAutocomplete();
                }).bounds(x+8,73+i*21,suggestionWidth,20).build();
                option.visible=false;
                autocompleteButtons.add(option);
                addRenderableWidget(option);
            }
        }

        private void updateAutocomplete() {
            if(filterBox==null)return;
            boolean hasQuery=autocompleteOpen && !filterBox.getValue().isBlank();
            Collection<String> source=playersTab ? playerPositions.keySet() : prices.keySet();
            autocompleteResults=hasQuery
                ? SearchSuggestions.find(source,filterBox.getValue(),autocompleteButtons.size())
                : List.of();
            boolean popup=!autocompleteResults.isEmpty();
            for(int i=0;i<autocompleteButtons.size();i++) {
                Button button=autocompleteButtons.get(i);
                button.visible=popup && i<autocompleteResults.size();
                if(button.visible) {
                    String item=autocompleteResults.get(i);
                    String display=playersTab ? item : SearchSuggestions.displayName(item);
                    button.setMessage(Component.literal((i+1)+". "+shortText(display,Math.max(75,Math.min(260,panelW/3)-22))));
                }
            }
            for(Button button:shopActionButtons)button.visible=!popup;
        }

        private String sortLabel() {
            return switch(sortMode) {
                case 1 -> "Compra menor";
                case 2 -> "Venda maior";
                case 3 -> "Nome A-Z";
                default -> "Lucro maior";
            };
        }
        private String profitLabel() { return onlyProfit?"Apenas lucro: SIM":"Apenas lucro: NÃO"; }

        private void send(String command) {
            Minecraft mc=Minecraft.getInstance();
            if(mc.getConnection()==null) {status="Conecte-se ao servidor.";return;}
            mc.getConnection().sendCommand(command);
            status="Abrindo /shop para leitura de preços.";
        }

        @Override public void render(GuiGraphics g,int mouseX,int mouseY,float delta) {
            // Minecraft 1.21.11: Screen.render desenha o fundo opaco. Nos builds
            // antigos ele era chamado no final e cobria TODA a tabela!
            // 1) fundo/controles do Minecraft
            super.render(g,mouseX,mouseY,delta);

            // 2) tabela, cabeçalhos, valores e diagnósticos DEPOIS do fundo
            g.fill(startX+5,100,startX+panelW-5,height-42,0xE419202C);
            String current=filterBox==null?"":filterBox.getValue();
            if(!searchText.equals(current)) {
                searchText=current;
                pricePage=0;
                playersPage=0;
                autocompleteOpen=!current.isBlank();
                updateAutocomplete();
            }
            if(aiTab) drawAi(g);
            else if(playersTab) drawPlayers(g);
            else drawPrices(g);
            g.drawCenteredString(font,"ONIMARKET 1.9 | "+(aiTab?"IA DE LUCRO":playersTab?"JOGADORES":"ECONOMIA"),width/2,10,0xFFFFFF);

            // 3) opções de autocomplete sobrepostas à tabela, por último
            if(autocompleteOpen && !autocompleteResults.isEmpty()) {
                int w=Math.max(100,Math.min(260,panelW/3));
                g.fill(startX+5,70,startX+11+w,
                    75+autocompleteResults.size()*21,0xFF151E2C);
                for(Button option:autocompleteButtons) {
                    if(option.visible)option.render(g,mouseX,mouseY,delta);
                }
            }
        }

        private void drawAi(GuiGraphics g) {
            int x=startX, w=panelW;
            g.drawString(font,"TIPO / RESULTADO",x+10,111,0xDDDDDD);
            int costX=x+(int)(w*.51), saleX=x+(int)(w*.68), gainX=x+(int)(w*.85);
            g.drawString(font,"CUSTO",costX,111,0xF9BC75);
            g.drawString(font,"VENDA",saleX,111,0x8ECBFF);
            g.drawString(font,"LUCRO",gainX,111,0x70F7AD);
            g.fill(x+8,122,x+w-8,123,0xFF47576A);
            List<ProfitEngine.Opportunity> filtered=new ArrayList<>();
            for(ProfitEngine.Opportunity op:opportunities) {
                if(SearchSuggestions.matches(op.product(),searchText))
                    filtered.add(op);
            }
            int maxRows=Math.max(1,(height-195)/32);
            int pages=Math.max(1,(filtered.size()+maxRows-1)/maxRows);
            aiPage=Math.min(aiPage,pages-1);
            for(int i=0;i<maxRows && aiPage*maxRows+i<filtered.size();i++) {
                ProfitEngine.Opportunity op=filtered.get(aiPage*maxRows+i);
                int y=128+i*32;
                if(i%2==0)g.fill(x+8,y-3,x+w-8,y+28,0x223D566F);
                String item=op.kind()+": "+op.product().replace('_',' ');
                g.drawString(font,shortText(item,costX-x-20),x+10,y,0xE9F2FE);
                g.drawString(font,fmt(op.cost()),costX,y,0xF9BC75);
                g.drawString(font,fmt(op.revenue()),saleX,y,0x8ECBFF);
                g.drawString(font,"+"+fmt(op.profit()),gainX,y,0x70F7AD);
                g.drawString(font,shortText(op.steps(),w-28),x+10,y+12,0x9DAFC5);
            }
            if(filtered.isEmpty())g.drawCenteredString(font,
                observedPrices.isEmpty()
                    ? "Sem preços atuais. Clique em Iniciar varredura /shop."
                    : "Nenhum lucro comprovado com os preços coletados.",
                width/2,150,0xFFCB7D);
            g.drawCenteredString(font,aiStatus,width/2,height-61,0xDDDDDD);
            g.drawCenteredString(font,
                observedPrices.size()+" itens reais | "+opportunities.size()+
                    " oportunidades | página "+(aiPage+1)+"/"+pages,width/2,height-49,0xA9C6E8);
            g.drawCenteredString(font,
                "Valores por operação; sem referências antigas, taxas ou preços inventados.",
                width/2,height-16,0xFFCB7D);
        }

        private void drawPrices(GuiGraphics g) {
            int x=startX;
            String filter=searchText;
            List<Map.Entry<String,Prices>> list=new ArrayList<>(prices.entrySet());
            list.removeIf(e -> !SearchSuggestions.matches(e.getKey(),filter)
                || (onlyProfit && (e.getValue().buy<=0 || e.getValue().sell<=0 || e.getValue().sell<=e.getValue().buy)));
            Comparator<Map.Entry<String,Prices>> byProfit=Comparator.comparingDouble(e->{
                Prices p=e.getValue();return p.buy>0 && p.sell>0 ? p.sell-p.buy : -Double.MAX_VALUE;
            });
            switch(sortMode) {
                case 1 -> list.sort(Comparator.comparingDouble(e->e.getValue().buy>0?e.getValue().buy:Double.MAX_VALUE));
                case 2 -> list.sort(Comparator.comparingDouble((Map.Entry<String,Prices> e)->e.getValue().sell).reversed());
                case 3 -> list.sort(Map.Entry.comparingByKey(String.CASE_INSENSITIVE_ORDER));
                default -> list.sort(byProfit.reversed());
            }
            int pages=Math.max(1,(list.size()+rowsPerPage-1)/rowsPerPage);
            pricePage=Math.min(pricePage,pages-1);
            g.drawString(font,"ITEM / BLOCO (*ref)",x+10,109,0xDDDDDD);
            int buy=x+(int)(panelW*.45), sell=x+(int)(panelW*.63), gain=x+(int)(panelW*.81);
            g.drawString(font,"COMPRA",buy,109,0xFFCA7B);
            g.drawString(font,"VENDA",sell,109,0x89CBFF);
            g.drawString(font,"LUCRO",gain,109,0x83F4A1);
            g.fill(x+8,122,x+panelW-8,123,0xFF47576A);
            int first=pricePage*rowsPerPage;
            for(int j=0;j<rowsPerPage && first+j<list.size();j++) {
                var e=list.get(first+j);
                int y=128+j*16;
                if(j%2==0) g.fill(x+8,y-2,x+panelW-8,y+13,0x2AFFFFFF);
                Prices p=e.getValue();
                String name=shortText((p.reference?"*":"")+e.getKey(),Math.max(80,buy-x-16));
                g.drawString(font,name,x+10,y,0xEEEEEE);
                g.drawString(font,p.buy>0?fmt(p.buy):"--",buy,y,0xFFCA7B);
                g.drawString(font,p.sell>0?fmt(p.sell):"--",sell,y,0x89CBFF);
                double profit=p.sell-p.buy;
                g.drawString(font,p.buy<=0||p.sell<=0?"--":fmtSigned(profit),gain,y,
                    p.buy<=0||p.sell<=0?0x999999:profit>0?0x63E18C:0xF48787);
            }
            if(list.isEmpty()) g.drawCenteredString(font,
                prices.isEmpty() ? "Sem catálogo carregado: reinicie o Minecraft com o mod." :
                "Nenhum item combina com a pesquisa. Clique em Limpar busca.",
                width/2,145,0xFFCB7D);
            long referenceCount=prices.values().stream().filter(p->p.reference).count();
            String footer=list.size()+" itens | "+referenceCount+" referência, "+
                (prices.size()-referenceCount)+" atualizados | página "+(pricePage+1)+"/"+pages;
            g.drawCenteredString(font,footer,width/2,height-61,0xCCCCCC);
            g.drawCenteredString(font,"Lidos: "+capturedChanges+" | Inventário: "+lastWindow,width/2,height-49,0xAAAAAA);
        }

        private void drawPlayers(GuiGraphics g) {
            int x=startX;
            g.drawString(font,"NICK",x+10,109,0xDDDDDD);
            int worldX=x+(int)(panelW*.30), cx=x+(int)(panelW*.58),
                cy=x+(int)(panelW*.72), cz=x+(int)(panelW*.85);
            g.drawString(font,"MUNDO",worldX,109,0xDDDDDD);
            g.drawString(font,"X",cx,109,0xFFCA7B);
            g.drawString(font,"Y",cy,109,0x89CBFF);
            g.drawString(font,"Z",cz,109,0x83F4A1);
            g.fill(x+8,122,x+panelW-8,123,0xFF47576A);
            List<PlayerPos> list=new ArrayList<>(playerPositions.values());
            list.removeIf(p -> !SearchSuggestions.matches(p.name,searchText));
            list.sort(Comparator.comparing(p->p.name.toLowerCase(Locale.ROOT)));
            int pages=Math.max(1,(list.size()+rowsPerPage-1)/rowsPerPage);
            playersPage=Math.min(playersPage,pages-1);
            int first=playersPage*rowsPerPage;
            for(int j=0;j<rowsPerPage && first+j<list.size();j++) {
                PlayerPos p=list.get(first+j);
                int y=128+j*16;
                if(j%2==0)g.fill(x+8,y-2,x+panelW-8,y+13,0x2AFFFFFF);
                g.drawString(font,shortText(p.name,worldX-x-16),x+10,y,0xEEEEEE);
                g.drawString(font,shortText(p.world,cx-worldX-10),worldX,y,p.visible?0xBBBBBB:0x888888);
                g.drawString(font,p.visible?Integer.toString(p.x):"--",cx,y,p.visible?0xFFCA7B:0x888888);
                g.drawString(font,p.visible?Integer.toString(p.y):"--",cy,y,p.visible?0x89CBFF:0x888888);
                g.drawString(font,p.visible?Integer.toString(p.z):"--",cz,y,p.visible?0x83F4A1:0x888888);
            }
            if(list.isEmpty()) g.drawCenteredString(font,
                playerPositions.isEmpty() ? "Sem conexão ao mundo: entre em um servidor." :
                "Nenhum jogador combina com a pesquisa. Clique em Limpar busca.",
                width/2,145,0xFFCB7D);
            long loaded=list.stream().filter(p->p.visible).count();
            g.drawCenteredString(font,list.size()+" online | "+loaded+" com coordenadas visíveis | página "+
                (playersPage+1)+"/"+pages,width/2,height-58,0xCCCCCC);
            g.drawCenteredString(font,"Sem plugin: posições somente de jogadores carregados no seu mundo.",
                width/2,height-46,0xAAAAAA);
        }
        private String shortText(String value,int maxWidth) {
            if(maxWidth<25)return "...";
            while(value.length()>1 && font.width(value)>maxWidth) value=value.substring(0,value.length()-1);
            return value;
        }
        private String fmtSigned(double v) {return (v>0?"+":"")+fmt(v);}
    }
}
