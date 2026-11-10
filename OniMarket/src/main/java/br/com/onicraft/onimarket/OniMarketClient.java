package br.com.onicraft.onimarket;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.message.v1.ClientReceiveMessageEvents;
import net.minecraft.client.Minecraft;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
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
    private static final Pattern MONEY = Pattern.compile("(?:R\\$|\\$)?\\s*([0-9][0-9.,]*)");
    private static class Prices { double buy = -1, sell = -1; }
    @Override public void onInitializeClient() {
        ClientTickEvents.END_CLIENT_TICK.register(client -> { while (KEY.consumeClick()) client.setScreen(new MarketScreen()); });
        ClientReceiveMessageEvents.GAME.register((message, overlay) -> scan(message.getString()));
    }
    private static void scan(String raw) {
        String s = raw.toLowerCase(Locale.ROOT);
        if (!s.contains("preço") && !s.contains("preco") && !s.contains("compr") && !s.contains("vend")) return;
        String item = lastItem;
        Matcher named = Pattern.compile("(?:item|produto)\\s*[:=-]\\s*([\\p{L}0-9_ -]{2,35})",Pattern.CASE_INSENSITIVE).matcher(raw);
        if(named.find()) item = named.group(1).trim();
        if(item.isBlank()) return;
        Matcher m = MONEY.matcher(raw);
        double val = -1;
        while(m.find()) { try { val = parseMoney(m.group(1)); } catch(Exception ignored) {} }
        if(val < 0) return;
        Prices p = prices.computeIfAbsent(item, k -> new Prices());
        if(s.contains("compr")) p.buy = val;
        if(s.contains("vend")) p.sell = val;
    }
    private static double parseMoney(String n) {
        int comma = n.lastIndexOf(','), dot = n.lastIndexOf('.');
        int sep = Math.max(comma,dot);
        if(sep >= 0 && n.length()-sep-1 <= 2) return Double.parseDouble(n.substring(0,sep).replaceAll("[.,]","") + "." + n.substring(sep+1));
        return Double.parseDouble(n.replaceAll("[.,]",""));
    }
    private static class MarketScreen extends Screen {
        private String status = "Use /shop ou /preco no servidor.";
        MarketScreen() { super(Component.literal("OniMarket")); }
        @Override protected void init() {
            int x = width/2-105;
            addRenderableWidget(Button.builder(Component.literal("Abrir /shop"), b -> send("shop")).bounds(x, height/2-75,210,20).build());
            addRenderableWidget(Button.builder(Component.literal("Consultar /preco"), b -> send("preco")).bounds(x,height/2-48,210,20).build());
            addRenderableWidget(Button.builder(Component.literal("Atualizar análise"), b -> status = "Preços capturados: " + prices.size()).bounds(x,height/2-21,210,20).build());
            addRenderableWidget(Button.builder(Component.literal("Fechar"), b -> onClose()).bounds(x,height/2+100,210,20).build());
        }
        private void send(String command) {
            Minecraft mc = Minecraft.getInstance();
            if(mc.player != null && mc.player.connection != null) {
                mc.player.connection.sendCommand(command);
                status = "Comando /"+command+" enviado. Confira a resposta.";
            }
        }
        @Override public void render(GuiGraphics g, int mouseX, int mouseY, float delta) {
            super.render(g,mouseX,mouseY,delta);
            g.drawCenteredString(font, "ONIMARKET • ANALISADOR", width/2,height/2-102,0xFFFFFF);
            g.drawCenteredString(font,status,width/2,height/2+13,0xDDDDDD);
            List<Map.Entry<String,Prices>> list = new ArrayList<>(prices.entrySet());
            list.removeIf(e -> e.getValue().buy < 0 || e.getValue().sell < 0);
            list.sort((a,b)-> Double.compare((b.getValue().sell-b.getValue().buy),(a.getValue().sell-a.getValue().buy)));
            int y = height/2+30;
            for(int i=0;i<Math.min(4,list.size());i++) {
                var e=list.get(i);
                double profit=e.getValue().sell-e.getValue().buy;
                g.drawCenteredString(font,e.getKey()+" | lucro: "+String.format(Locale.US,"%.2f",profit),width/2,y,profit>0?0x55FF88:0xFF7777);
                y+=14;
            }
        }
    }
}
