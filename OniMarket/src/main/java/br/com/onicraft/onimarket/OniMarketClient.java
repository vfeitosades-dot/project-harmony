package br.com.onicraft.onimarket;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.message.v1.ClientReceiveMessageEvents;
import net.minecraft.client.Minecraft;
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
        PlayerPos(String name, String world, int x, int y, int z) {
            this.name=name; this.world=world; this.x=x; this.y=y; this.z=z;
        }
    }
    private static String serverName = "local";
    private static long scanUntil = 0;
    private static long nextAutoQuery = 0;
    private static int autoIndex = -1;
    private static int tick = 0;
    private static List<String> queue = new ArrayList<>();
    private static final Pattern MONEY = Pattern.compile("(?:R\\$|\\$)?\\s*([0-9][0-9.,]*)");
    private static final Pattern PRICE_KIND = Pattern.compile("(?i)\\b(comprar|compra|buy|vender|venda|sell)\\b");
    private static class Prices { double buy = -1, sell = -1; }
    @Override public void onInitializeClient() {
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
                scanUntil = 0;
                autoIndex = -1;
            }
            if (++tick % 7 == 0 && System.currentTimeMillis() < scanUntil) scanShop(client);
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
        ClientReceiveMessageEvents.GAME.register((message, overlay) -> scan(message.getString()));
    }
    private static void scanShop(Minecraft client) {
        if (!(client.screen instanceof AbstractContainerScreen<?> screen)) return;
        List<Slot> slots = screen.getMenu().slots;
        int n = slots.size() > 36 ? slots.size()-36 : slots.size();
        for (int i=0;i<n;i++) {
            ItemStack stack = slots.get(i).getItem();
            if (stack.isEmpty()) continue;
            ItemLore lore = stack.get(DataComponents.LORE);
            if (lore == null || lore.lines().isEmpty()) continue;
            String name = stack.getHoverName().getString();
            String old = lastItem;
            lastItem = name;
            for (Component l : lore.lines()) scan(l.getString());
            lastItem = old;
        }
    }
    private static Path dataFile() {
        String id = serverName.replaceAll("[^a-zA-Z0-9._-]", "_");
        if (id.length() > 70) id = id.substring(0, 70);
        return FabricLoader.getInstance().getConfigDir().resolve("onimarket").resolve(id+".tsv");
    }
    private static void savePrices() {
        try {
            Path file = dataFile();
            Files.createDirectories(file.getParent());
            List<String> lines = new ArrayList<>();
            for (var e : prices.entrySet()) lines.add(e.getKey().replace("\t"," ")+"\t"+e.getValue().buy+"\t"+e.getValue().sell);
            Files.write(file, lines, StandardCharsets.UTF_8);
        } catch (Exception ex) { System.err.println("[OniMarket] "+ex.getMessage()); }
    }
    private static void loadPrices() {
        try {
            if (!Files.exists(dataFile())) return;
            for (String line : Files.readAllLines(dataFile(),StandardCharsets.UTF_8)) {
                String[] p = line.split("\\t");
                if (p.length != 3) continue;
                Prices v = new Prices();
                v.buy = Double.parseDouble(p[1]); v.sell = Double.parseDouble(p[2]);
                prices.put(p[0], v);
            }
        } catch(Exception ex) { System.err.println("[OniMarket] "+ex.getMessage()); }
    }
    private static void scan(String raw) {
        if (raw.equals("[ONIMARKET:BEGIN]")) {
            playerPositions.clear();
            positionsUpdatedAt=0;
            return;
        }
        if (raw.startsWith("[ONIMARKET:POS]")) {
            try {
                String[] parts = raw.substring("[ONIMARKET:POS]".length()).split("\\|",5);
                if(parts.length==5 && parts[0].matches("[A-Za-z0-9_]{1,16}")) {
                    PlayerPos p = new PlayerPos(parts[0],parts[1],
                        Integer.parseInt(parts[2]), Integer.parseInt(parts[3]), Integer.parseInt(parts[4]));
                    if(playerPositions.size()<500) playerPositions.put(p.name,p);
                }
            } catch (RuntimeException ignored) { }
            return;
        }
        if (raw.equals("[ONIMARKET:END]")) {
            positionsUpdatedAt=System.currentTimeMillis();
            return;
        }
        String item = lastItem;
        Matcher named = Pattern.compile("(?:item|produto)\\s*[:=-]\\s*([\\p{L}0-9_ -]{2,35})", Pattern.CASE_INSENSITIVE).matcher(raw);
        if (named.find()) item = named.group(1).trim();
        if (item.isBlank()) return;
        Matcher label = PRICE_KIND.matcher(raw);
        List<int[]> hits = new ArrayList<>();
        List<Boolean> kinds = new ArrayList<>();
        while (label.find()) {
            hits.add(new int[]{label.start(), label.end()});
            String word = label.group(1).toLowerCase(Locale.ROOT);
            kinds.add(word.startsWith("compr") || word.equals("buy"));
        }
        if (hits.isEmpty()) return;
        Prices p = prices.computeIfAbsent(item, k -> new Prices());
        for (int i = 0; i < hits.size(); i++) {
            int from = hits.get(i)[1];
            int to = i + 1 < hits.size() ? hits.get(i+1)[0] : raw.length();
            if (to <= from) continue;
            String segment = raw.substring(from, to);
            Matcher amount = MONEY.matcher(segment);
            double value = -1;
            while (amount.find()) {
                try { value = parseMoney(amount.group(1)); } catch (NumberFormatException ignored) { }
            }
            if (!Double.isFinite(value) || value < 0) continue;
            if (kinds.get(i)) p.buy = value;
            else p.sell = value;
        }
    }
    private static double parseMoney(String n) {
        int comma = n.lastIndexOf(','), dot = n.lastIndexOf('.');
        int sep = Math.max(comma,dot);
        if(sep >= 0 && n.length()-sep-1 <= 2) return Double.parseDouble(n.substring(0,sep).replaceAll("[.,]","") + "." + n.substring(sep+1));
        return Double.parseDouble(n.replaceAll("[.,]",""));
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
                playersTab=true; Minecraft.getInstance().setScreen(new MarketScreen());
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
                addRenderableWidget(Button.builder(Component.literal("Atualizar coordenadas"), b -> send("onimarketplayers"))
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
            if(command.equals("shop")) scanUntil=System.currentTimeMillis()+180000;
            mc.getConnection().sendCommand(command);
            status="Enviado /"+command;
        }

        @Override public void render(GuiGraphics g,int mouseX,int mouseY,float delta) {
            g.fill(startX,8,startX+panelW,height-8,0xD9141923);
            super.render(g,mouseX,mouseY,delta);
            g.drawCenteredString(font,"ONIMARKET | "+(playersTab?"ADMINISTRAÇÃO":"ECONOMIA"),width/2,10,0xFFFFFF);
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
            g.drawString(font,"ITEM / BLOCO",x+10,109,0xDDDDDD);
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
                String name=shortText(e.getKey(),Math.max(80,buy-x-16));
                g.drawString(font,name,x+10,y,0xEEEEEE);
                g.drawString(font,fmt(p.buy),buy,y,0xFFCA7B);
                g.drawString(font,fmt(p.sell),sell,y,0x89CBFF);
                double profit=p.sell-p.buy;
                g.drawString(font,p.buy<0||p.sell<0?"--":fmtSigned(profit),gain,y,
                    p.buy<0||p.sell<0?0x999999:profit>0?0x63E18C:0xF48787);
            }
            if(list.isEmpty()) g.drawCenteredString(font,"Nenhum item coletado. Abra /shop e navegue pelas páginas.",width/2,150,0xCCCCCC);
            String footer=list.size()+" de "+prices.size()+" itens | página "+(pricePage+1)+"/"+pages+" | "+serverName;
            g.drawCenteredString(font,footer,width/2,height-61,0xCCCCCC);
            g.drawCenteredString(font,status,width/2,height-49,0xAAAAAA);
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
                g.drawString(font,shortText(p.world,cx-worldX-10),worldX,y,0xBBBBBB);
                g.drawString(font,Integer.toString(p.x),cx,y,0xFFCA7B);
                g.drawString(font,Integer.toString(p.y),cy,y,0x89CBFF);
                g.drawString(font,Integer.toString(p.z),cz,y,0x83F4A1);
            }
            String status=positionsUpdatedAt==0
                ?"Instale o complemento Paper no servidor para ver as coordenadas"
                :list.size()+" jogadores | página "+(playersPage+1)+"/"+pages+
                (System.currentTimeMillis()-positionsUpdatedAt>120000?" | ATUALIZE OS DADOS":" | atualizado");
            g.drawCenteredString(font,status,width/2,height-58,0xCCCCCC);
            g.drawCenteredString(font,"Coordenadas do servidor - visíveis a todos com o mod.",width/2,height-46,0xAAAAAA);
        }
        private String shortText(String value,int maxWidth) {
            if(maxWidth<25)return "...";
            while(value.length()>1 && font.width(value)>maxWidth) value=value.substring(0,value.length()-1);
            return value;
        }
        private String fmtSigned(double v) {return (v>0?"+":"")+fmt(v);}
    }
}
