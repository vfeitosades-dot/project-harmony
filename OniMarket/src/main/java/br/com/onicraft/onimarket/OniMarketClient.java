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
        private String status = "Use /shop ou /preco no servidor.";
        private EditBox itemField;
        MarketScreen() { super(Component.literal("OniMarket")); }
        @Override protected void init() {
            int x = width/2-105;
            itemField = new EditBox(font, x, height/2-109, 210, 20, Component.literal("Item para /preco"));
            itemField.setMaxLength(64);
            addRenderableWidget(itemField);
            addRenderableWidget(Button.builder(Component.literal("Abrir /shop"), b -> send("shop")).bounds(x, height/2-75,210,20).build());
            addRenderableWidget(Button.builder(Component.literal("Consultar /preco"), b -> {
                String item = itemField.getValue().trim().replace("/", "");
                if(item.isBlank()) { status = "Digite um item antes de consultar."; return; }
                lastItem = item;
                send("preco "+item);
            }).bounds(x,height/2-48,210,20).build());
            addRenderableWidget(Button.builder(Component.literal("Pesquisar itens coletados"), b -> {
                queue = new ArrayList<>(prices.keySet());
                queue.sort(String::compareToIgnoreCase);
                autoIndex = queue.isEmpty() ? -1 : 0;
                nextAutoQuery = System.currentTimeMillis();
                status = queue.isEmpty() ? "Abra /shop e explore os itens primeiro." : "Pesquisa iniciada: ate 12 itens, 5s por consulta.";
                if (autoIndex >= 0) onClose();
            }).bounds(x,height/2-21,210,20).build());
            addRenderableWidget(Button.builder(Component.literal("Fechar"), b -> onClose()).bounds(x,height/2+123,210,20).build());
        }
        private void send(String command) {
            Minecraft mc = Minecraft.getInstance();
            if (command.equals("shop")) scanUntil = System.currentTimeMillis()+180000;
            if(mc.player != null && mc.player.connection != null) {
                mc.player.connection.sendCommand(command);
                status = "Comando /"+command+" enviado. Confira a resposta.";
            }
        }
        @Override public void render(GuiGraphics g, int mouseX, int mouseY, float delta) {
            super.render(g,mouseX,mouseY,delta);
            g.drawCenteredString(font, "ONIMARKET • ANALISADOR", width/2,height/2-132,0xFFFFFF);
            g.drawCenteredString(font,status,width/2,height/2+13,0xDDDDDD);
            g.drawCenteredString(font, "Itens registrados: "+prices.size()+" | "+serverName,width/2,height/2+23,0xBBBBBB);
            List<Map.Entry<String,Prices>> list = new ArrayList<>(prices.entrySet());
            list.sort((a,b) -> {
                double pa = (a.getValue().buy < 0 || a.getValue().sell < 0) ? -Double.MAX_VALUE : a.getValue().sell-a.getValue().buy;
                double pb = (b.getValue().buy < 0 || b.getValue().sell < 0) ? -Double.MAX_VALUE : b.getValue().sell-b.getValue().buy;
                return Double.compare(pb,pa);
            });
            int x = Math.max(6, width/2-155);
            g.drawString(font, "ITEM", x, height/2+38, 0xAAAAAA);
            g.drawString(font, "COMPRA", x+105, height/2+38, 0xAAAAAA);
            g.drawString(font, "VENDA", x+170, height/2+38, 0xAAAAAA);
            g.drawString(font, "LUCRO", x+235, height/2+38, 0xAAAAAA);
            int y = height/2+53;
            for(int i=0;i<Math.min(4,list.size());i++) {
                var e=list.get(i);
                Prices p=e.getValue();
                double profit=p.sell-p.buy;
                String item = e.getKey();
                while(item.length()>2 && font.width(item)>100) item=item.substring(0,item.length()-2)+"…";
                g.drawString(font,item,x,y,0xEEEEEE);
                g.drawString(font,fmt(p.buy),x+105,y,0xFFCB6B);
                g.drawString(font,fmt(p.sell),x+170,y,0x85D5FF);
                g.drawString(font,p.buy<0||p.sell<0?"--":fmt(profit),x+235,y,p.buy<0||p.sell<0?0x999999:profit>0?0x55FF88:0xFF7777);
                y+=14;
            }
            if (list.size()>4) g.drawCenteredString(font, "Mostrando 4 de "+list.size()+" itens",width/2,height/2+110,0xAAAAAA);
        }
    }
}
