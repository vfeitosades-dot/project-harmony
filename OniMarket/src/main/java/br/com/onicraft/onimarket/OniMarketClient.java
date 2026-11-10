package br.com.onicraft.onimarket;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.message.v1.ClientReceiveMessageEvents;
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
import java.util.regex.*;

public class OniMarketClient implements ClientModInitializer {
    private static final KeyMapping.Category CATEGORY = KeyMapping.Category.register(net.minecraft.resources.Identifier.fromNamespaceAndPath("onimarket", "general"));
    private static final KeyMapping KEY = KeyBindingHelper.registerKeyBinding(new KeyMapping("Abrir OniMarket", InputConstants.Type.KEYSYM, GLFW.GLFW_KEY_P, CATEGORY));
    private static final Map<String, Prices> prices = new HashMap<>();
    private static String lastItem = "";
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
    private static long scanUntil = 0;
    private static int capturedChanges = 0;
    private static int scannedSlots = 0;
    private static String lastWindow = "Sem janela de loja";
    private static long nextAutoQuery = 0;
    private static int autoIndex = -1;
    private static int tick = 0;
    private static List<String> queue = new ArrayList<>();
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
                playerPositions.clear();
                positionsUpdatedAt=0;
                loadPrices();
                loadReferenceCatalog();
                scanUntil = 0;
                capturedChanges = 0;
                scannedSlots = 0;
                autoIndex = -1;
            }
            tick++;
            if(tick%2==0 && client.screen instanceof AbstractContainerScreen<?>)scanShop(client);
            if (tick % 10 == 0 && client.level != null) refreshPlayers(client);
            if (autoIndex >= 0 && System.currentTimeMillis() >= nextAutoQuery) {
                if (autoIndex >= Math.min(12, queue.size())) { autoIndex = -1; savePrices(); }
                else {
                    lastItem = queue.get(autoIndex++);
                    client.getConnection().sendCommand("preco " + lastItem.replace("/", "").replace("\\n", ""));
                    nextAutoQuery = System.currentTimeMillis() + 5000;
                }
            }
            if (tick % 200 == 0) savePrices();
        });
        ClientReceiveMessageEvents.GAME.register((message, overlay) -> { if(!overlay)scan(message.getString()); });
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
    private static void scanShop(Minecraft client) {
        if (!(client.screen instanceof AbstractContainerScreen<?> screen)) return;
        lastWindow=screen.getTitle().getString();
        List<Slot> slots=screen.getMenu().slots;
        int n=slots.size()>36 ? slots.size()-36 : slots.size();
        for(int i=0;i<n;i++) {
            ItemStack stack=slots.get(i).getItem();
            if(stack.isEmpty())continue;
            scannedSlots++;
            ItemLore lore=stack.get(DataComponents.LORE);
            if(lore==null || lore.lines().isEmpty())continue;
            String id=BuiltInRegistries.ITEM.getKey(stack.getItem()).getPath().toUpperCase(Locale.ROOT);
            Prices prev=prices.get(id);
            double buy=prev==null?-1:prev.buy, sell=prev==null?-1:prev.sell;
            boolean wasReference=prev!=null && prev.reference;
            for(Component line:lore.lines())scanPrice(id,line.getString());
            Prices current=prices.get(id);
            if(current!=null && (buy!=current.buy || sell!=current.sell || wasReference!=current.reference))
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
                    v.buy=Double.parseDouble(p[1]);v.sell=Double.parseDouble(p[2]);v.reference=true;
                    prices.put(p[0],v);
                }
            }
        }catch(Exception ex){System.err.println("[OniMarket] referência: "+ex);}
    }
    private static void scan(String raw) {
        String item=lastItem;
        Matcher named=Pattern.compile("(?iu)(?:item|produto)\\s*[:=-]\\s*([\\p{L}0-9_ -]{2,35})").matcher(raw);
        if(named.find())item=named.group(1).trim();
        if(!item.isBlank())scanPrice(item,raw);
    }
    private static void scanPrice(String item,String raw) {
        if(item==null || item.isBlank() || raw==null)return;
        PriceParser.Quote q=PriceParser.parse(raw);
        if(q.buy()==null && q.sell()==null)return;
        Prices p=prices.computeIfAbsent(item,k->new Prices());
        if(p.reference) {p.buy=-1;p.sell=-1;p.reference=false;}
        if(q.buy()!=null)p.buy=q.buy();
        if(q.sell()!=null)p.sell=q.sell();
    }
    private static String fmt(double v) {
        if (!Double.isFinite(v) || v < 0) return "--";
        if (v >= 1000000) return String.format(Locale.US, "%.1fM", v / 1000000);
        if (v >= 10000) return String.format(Locale.US, "%.1fk", v / 1000);
        return String.format(Locale.US, "%.2f", v);
    }
    private static class MarketScreen extends Screen {
        private static boolean playersTab = false;
        private static boolean onlyProfit = false;
        private static int sortMode=0;
        private static String searchText="";
        private static int pricePage=0;
        private static int playersPage=0;
        private EditBox filterBox;
        private EditBox priceItemBox;
        private String status="Abra /shop e percorra as páginas para coletar os itens.";
        private int startX, panelW, rowsPerPage;

        MarketScreen() { super(Component.literal("OniMarket")); }
        @Override protected void init() {
            panelW = Math.min(760, width-20);
            startX = (width-panelW)/2;
            rowsPerPage=Math.max(1,(height-189)/16);
            int x=startX;
            addRenderableWidget(Button.builder(Component.literal("PREÇOS"), b -> {
                playersTab=false; Minecraft.getInstance().setScreen(new MarketScreen());
            }).bounds(x+8,22,Math.min(120,panelW/3),20).build());
            addRenderableWidget(Button.builder(Component.literal("JOGADORES"), b -> {
                playersTab=true;
                refreshPlayers(Minecraft.getInstance());
                Minecraft.getInstance().setScreen(new MarketScreen());
            }).bounds(x+Math.min(138,panelW/3+14),22,Math.min(120,panelW/3),20).build());
            addRenderableWidget(Button.builder(Component.literal("X"), b -> onClose())
                .bounds(x+panelW-30,22,22,20).build());

            filterBox=new EditBox(font,x+8,49,Math.max(100,Math.min(260,panelW/3)),20,Component.literal("Pesquisar"));
            filterBox.setMaxLength(70);
            filterBox.setValue(searchText);
            addRenderableWidget(filterBox);

            if (!playersTab) {
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
                addRenderableWidget(Button.builder(Component.literal("/shop"), b -> send("shop"))
                    .bounds(x+8,76,75,20).build());
                priceItemBox=new EditBox(font,x+88,76,Math.max(75,Math.min(245,panelW/3)),20,Component.literal("Item para /preco"));
                priceItemBox.setMaxLength(64);
                addRenderableWidget(priceItemBox);
                int queryX=x+93+Math.max(75,Math.min(245,panelW/3));
                if(queryX+75<x+panelW) addRenderableWidget(Button.builder(Component.literal("/preco"), b -> {
                    String item=priceItemBox.getValue().trim().replace("/","");
                    if(item.isBlank()) { status="Digite o nome do item."; return; }
                    lastItem=item; send("preco "+item);
                }).bounds(queryX,76,75,20).build());
                int findX=queryX+80;
                if(findX+80<x+panelW) addRenderableWidget(Button.builder(Component.literal("Pesquisar"), b -> {
                    queue=new ArrayList<>(prices.keySet());
                    queue.sort(String::compareToIgnoreCase);
                    autoIndex=queue.isEmpty()?-1:0;
                    nextAutoQuery=System.currentTimeMillis();
                    status=queue.isEmpty()?"Explore /shop primeiro.":"Consultando até 12 itens coletados.";
                    if(autoIndex>=0) onClose();
                }).bounds(findX,76,Math.min(106,x+panelW-findX-8),20).build());
            } else {
                addRenderableWidget(Button.builder(Component.literal("Atualizar jogadores"), b -> { refreshPlayers(Minecraft.getInstance()); status="Lista local atualizada."; })
                    .bounds(x+8,76,190,20).build());
            }
            addRenderableWidget(Button.builder(Component.literal("◀ Anterior"), b -> {
                if(playersTab) playersPage=Math.max(0,playersPage-1);
                else pricePage=Math.max(0,pricePage-1);
            }).bounds(x+8,height-36,110,20).build());
            addRenderableWidget(Button.builder(Component.literal("Próximo ▶"), b -> {
                if(playersTab) playersPage++;
                else pricePage++;
            }).bounds(x+124,height-36,110,20).build());
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
            if(command.equals("shop")) {
                scanUntil=System.currentTimeMillis()+20L*60*1000;
                capturedChanges=0;
            }
            mc.getConnection().sendCommand(command);
            status="Enviado /"+command;
        }

        @Override public void render(GuiGraphics g,int mouseX,int mouseY,float delta) {
            g.fill(startX,8,startX+panelW,height-8,0xD9141923);
            super.render(g,mouseX,mouseY,delta);
            g.drawCenteredString(font,"ONIMARKET | "+(playersTab?"JOGADORES":"ECONOMIA"),width/2,10,0xFFFFFF);
            String current=filterBox==null?"":filterBox.getValue();
            if(!searchText.equals(current)) {
                searchText=current;
                pricePage=0;playersPage=0;
            }
            if(playersTab) drawPlayers(g);
            else drawPrices(g);
        }

        private void drawPrices(GuiGraphics g) {
            int x=startX;
            String filter=searchText.toLowerCase(Locale.ROOT);
            List<Map.Entry<String,Prices>> list=new ArrayList<>(prices.entrySet());
            list.removeIf(e -> !e.getKey().toLowerCase(Locale.ROOT).contains(filter)
                || (onlyProfit && (e.getValue().buy<0 || e.getValue().sell<0 || e.getValue().sell<=e.getValue().buy)));
            Comparator<Map.Entry<String,Prices>> byProfit=Comparator.comparingDouble(e->{
                Prices p=e.getValue();return p.buy>=0 && p.sell>=0 ? p.sell-p.buy : -Double.MAX_VALUE;
            });
            switch(sortMode) {
                case 1 -> list.sort(Comparator.comparingDouble(e->e.getValue().buy>=0?e.getValue().buy:Double.MAX_VALUE));
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
                g.drawString(font,fmt(p.buy),buy,y,0xFFCA7B);
                g.drawString(font,fmt(p.sell),sell,y,0x89CBFF);
                double profit=p.sell-p.buy;
                g.drawString(font,p.buy<0||p.sell<0?"--":fmtSigned(profit),gain,y,
                    p.buy<0||p.sell<0?0x999999:profit>0?0x63E18C:0xF48787);
            }
            if(list.isEmpty()) g.drawCenteredString(font,"Nenhum item coletado. Abra /shop e navegue pelas páginas.",width/2,150,0xCCCCCC);
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
            list.removeIf(p -> !p.name.toLowerCase(Locale.ROOT).contains(searchText.toLowerCase(Locale.ROOT)));
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
