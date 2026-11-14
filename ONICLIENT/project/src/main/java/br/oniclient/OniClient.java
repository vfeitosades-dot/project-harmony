package br.oniclient;

import com.mojang.blaze3d.platform.InputConstants;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.screen.v1.ScreenEvents;
import net.fabricmc.fabric.api.client.screen.v1.ScreenKeyboardEvents;
import net.fabricmc.fabric.api.client.screen.v1.Screens;
import net.fabricmc.fabric.api.client.rendering.v1.hud.HudElementRegistry;
import net.fabricmc.fabric.api.client.rendering.v1.hud.VanillaHudElements;
import net.fabricmc.loader.api.FabricLoader;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.core.BlockPos;
import net.minecraft.core.component.DataComponents;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.Identifier;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.item.component.ItemLore;
import net.minecraft.world.item.Items;
import org.lwjgl.glfw.GLFW;
import java.io.*;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;

public final class OniClient implements ClientModInitializer {
    public static boolean XRAY=false;
    public static boolean NIGHT=false;
    public static boolean HUD=true;
    public static boolean RADAR=false;
    public static boolean AUTO_SCAN=true;
    public static final Map<String,Quote> PRICES=new HashMap<>();
    private static final Gson GSON=new GsonBuilder().setPrettyPrinting().create();
    private static final Pattern BUY=Pattern.compile("(?iu)(?:pre[cç]o\\s+(?:de\\s+)?compra|comprar|compra|buy)[^0-9\\r\\n]{0,35}([0-9][0-9.,]*)");
    private static final Pattern SELL=Pattern.compile("(?iu)(?:pre[cç]o\\s+(?:de\\s+)?venda|vender|venda|sell)[^0-9\\r\\n]{0,35}([0-9][0-9.,]*)");
    private static final Pattern SHOP=Pattern.compile("(?i)shop|loja|market|mercado|categoria|comprar|vender");
    private static final KeyMapping.Category CATEGORY=KeyMapping.Category.register(Identifier.fromNamespaceAndPath("oniclient","main"));
    private KeyMapping menu, night, xray, scan;
    private int ticks;
    public static String lastShop="Nenhuma loja";
    public static int lastFound=0;
    public static String lastDiagnostic="Sem diagnostico";
    public static int lastSlots=0;
    public static int lastLores=0;
    public static String oreResult="";
    private static String serverName="";
    public static final class Quote {
        public String id, name;
        public double buy=Double.NaN, sell=Double.NaN;
        public long updated;
        public Quote(){}
    }
    public record Deal(String id, String name, double buy,double sell,double profit){}
    @Override public void onInitializeClient(){
        menu=bind("open",GLFW.GLFW_KEY_RIGHT_SHIFT);
        night=bind("night",GLFW.GLFW_KEY_N);
        xray=bind("xray",GLFW.GLFW_KEY_X);
        scan=bind("scan",GLFW.GLFW_KEY_P);
        ClientTickEvents.END_CLIENT_TICK.register(this::tick);
        // A tecla normal do Minecraft nao chega ao mod durante menus de bau.
        // Registramos os eventos de teclado do proprio menu e um botao acessivel.
        ScreenEvents.AFTER_INIT.register((client, screen, scaledWidth, scaledHeight) -> {
            if (!(screen instanceof AbstractContainerScreen<?>)) return;
            Screens.getButtons(screen).add(
                Button.builder(Component.literal("ONI: ESCANEAR (P)"), b -> {
                    scanOpenShop(client);
                    b.setMessage(Component.literal("ONI: "+lastFound+" / "+lastSlots));
                }).bounds(Math.max(4,scaledWidth-155),4,151,20).build());
            ScreenKeyboardEvents.beforeKeyPress(screen).register((s,key) -> {
                if (key.key()==GLFW.GLFW_KEY_P) scanOpenShop(client);
            });
        });
        HudElementRegistry.attachElementBefore(VanillaHudElements.CHAT,
          Identifier.fromNamespaceAndPath("oniclient","hud"),(g,t)->{
            Minecraft mc=Minecraft.getInstance();
            if(!HUD||mc.player==null||mc.options.hideGui)return;
            g.fill(4,4,216,46,Rgba.PANEL);
            g.drawString(mc.font,"ONICLIENT 1.21.11",9,9,0xFF75FFE0);
            g.drawString(mc.font,"Shop: "+PRICES.size()+" itens | Lucros: "+deals().size(),9,21,0xFFDFE9FF);
            g.drawString(mc.font,"NV "+(NIGHT?"ON":"OFF")+" | Xray "+(XRAY?"ON":"OFF")+" | RSHIFT",9,33,0xFFB6C9DC);
            if(RADAR&&!oreResult.isEmpty())g.drawString(mc.font,oreResult,9,52,0xFFFFDB83);
          });
    }
    private KeyMapping bind(String id,int key){
        return KeyBindingHelper.registerKeyBinding(new KeyMapping("key.oniclient."+id, InputConstants.Type.KEYSYM,key,CATEGORY));
    }
    private void tick(Minecraft mc){
        ticks++;
        if(mc.player==null){
            if(ticks%200==0)save();
            return;
        }
        if(ticks%50==0)selectServer(mc);
        while(menu.consumeClick())mc.setScreen(new Panel(0));
        while(night.consumeClick())NIGHT=!NIGHT;
        while(xray.consumeClick())toggleXray(mc);
        while(scan.consumeClick())scanOpenShop(mc);
        if(NIGHT&&ticks%40==0){
            var effect=mc.player.getEffect(MobEffects.NIGHT_VISION);
            if(effect==null||effect.getDuration()<100)mc.player.addEffect(new MobEffectInstance(MobEffects.NIGHT_VISION,240,0,true,false,false));
        }
        if(AUTO_SCAN&&ticks%25==0)capture(mc,false);
        if(RADAR&&ticks%100==0)radar(mc);
        if(ticks%180==0)save();
    }
    public static void toggleXray(Minecraft mc){
        XRAY=!XRAY;
        if(mc.level!=null)mc.levelRenderer.allChanged();
    }
    private static Path pricePath(){
        return FabricLoader.getInstance().getConfigDir().resolve("oniclient-market-"+serverName.replaceAll("[^a-zA-Z0-9_.-]","_")+".json");
    }
    private static void selectServer(Minecraft mc){
        String next=mc.getCurrentServer()==null?"singleplayer":mc.getCurrentServer().ip;
        if(next.equals(serverName))return;
        save();PRICES.clear();serverName=next;
        try(Reader r=Files.newBufferedReader(pricePath(),StandardCharsets.UTF_8)){
            Type type=new TypeToken<Map<String,Quote>>(){}.getType();
            Map<String,Quote> old=GSON.fromJson(r,type);
            if(old!=null)PRICES.putAll(old);
        }catch(Exception ignored){}
    }
    public static void save(){
        if(serverName.isEmpty())return;
        try{
            Path p=pricePath();Files.createDirectories(p.getParent());
            try(Writer w=Files.newBufferedWriter(p,StandardCharsets.UTF_8)){GSON.toJson(PRICES,w);}
        }catch(Exception ignored){}
    }
    public static int capture(Minecraft mc,boolean forced){
        if(mc.player==null||!(mc.screen instanceof AbstractContainerScreen<?> screen))return 0;
        String title=screen.getTitle().getString();
        if(!forced&&!SHOP.matcher(title).find())return 0;
        lastShop=title;
        int count=0, slots=0, lores=0;
        for(Slot slot:screen.getMenu().slots){
            if(slot.container==mc.player.getInventory())continue;
            var stack=slot.getItem();
            if(stack.isEmpty())continue;
            slots++;
            ItemLore lore=stack.get(DataComponents.LORE);
            if(lore==null)continue;
            lores++;
            double buy=Double.NaN,sell=Double.NaN;
            for(Component line:lore.lines()){
                String text=line.getString();
                double b=price(BUY,text),s=price(SELL,text);
                if(Double.isFinite(b))buy=b;
                if(Double.isFinite(s))sell=s;
            }
            if(!Double.isFinite(buy)&&!Double.isFinite(sell))continue;
            String id=BuiltInRegistries.ITEM.getKey(stack.getItem()).toString();
            Quote q=PRICES.computeIfAbsent(id,k->new Quote());
            q.id=id;q.name=stack.getHoverName().getString();
            if(Double.isFinite(buy))q.buy=buy;
            if(Double.isFinite(sell))q.sell=sell;
            q.updated=System.currentTimeMillis();count++;
        }
        lastFound=count;
        lastSlots=slots;
        lastLores=lores;
        lastDiagnostic="Itens: "+slots+" | descricoes: "+lores+" | precos: "+count;
        return count;
    }
    private static void scanOpenShop(Minecraft mc) {
        if(mc.player==null)return;
        if(!(mc.screen instanceof AbstractContainerScreen<?>)){
            mc.player.displayClientMessage(Component.literal("[ONI] Abra /shop e mantenha a loja aberta para escanear."),false);
            return;
        }
        int count=capture(mc,true);
        if(count>0){
            mc.player.displayClientMessage(Component.literal("[ONI] "+count+" itens com preco detectados nesta pagina. Abra outras categorias para completar."),false);
            save();
        }else{
            String file=writeDiagnostic(mc);
            mc.player.displayClientMessage(Component.literal("[ONI] Nenhum preco encontrado. "+lastDiagnostic+". Diagnostico: "+file),false);
        }
    }
    private static String writeDiagnostic(Minecraft mc){
        if(!(mc.screen instanceof AbstractContainerScreen<?> screen))return "Abra uma loja";
        Path path=FabricLoader.getInstance().getConfigDir().resolve("oniclient-shop-diagnostico.txt");
        try{
            Files.createDirectories(path.getParent());
            try(Writer w=Files.newBufferedWriter(path,StandardCharsets.UTF_8)){
                w.write("ONICLIENT DIAGNOSTICO - Fabric 1.21.11\n");
                w.write("Tela: "+screen.getTitle().getString()+"\n");
                w.write("Slots com itens: "+lastSlots+"; com lore: "+lastLores+"; precos detectados: "+lastFound+"\n");
                for(Slot slot:screen.getMenu().slots){
                    if(slot.container==mc.player.getInventory())continue;
                    var stack=slot.getItem();
                    if(stack.isEmpty())continue;
                    w.write("\nItem: "+BuiltInRegistries.ITEM.getKey(stack.getItem())+" | "+stack.getHoverName().getString()+" | tamanho "+stack.getCount()+"\n");
                    ItemLore lore=stack.get(DataComponents.LORE);
                    if(lore!=null)for(Component line:lore.lines())w.write("  "+line.getString()+"\n");
                }
            }
            return path.toString();
        }catch(IOException ex){return "Falha ao salvar: "+ex.getMessage();}
    }
    private static double price(Pattern p,String text){
        Matcher m=p.matcher(text);
        if(!m.find())return Double.NaN;
        String value=m.group(1);
        int comma=value.lastIndexOf(','),dot=value.lastIndexOf('.');
        if(comma>=0&&dot>=0)value=comma>dot?value.replace(".","").replace(",","."):value.replace(",","");
        else if(comma>=0)value=value.replace(",",".");
        try{return Double.parseDouble(value);}catch(Exception ex){return Double.NaN;}
    }
    public static List<Deal> deals(){
        List<Deal> result=new ArrayList<>();
        for(Quote q:PRICES.values()){
            if(q==null||!Double.isFinite(q.buy)||!Double.isFinite(q.sell)||q.buy<=0)continue;
            if(q.sell>q.buy)result.add(new Deal(q.id,q.name,q.buy,q.sell,q.sell-q.buy));
        }
        result.sort(Comparator.comparingDouble(Deal::profit).reversed());
        return result;
    }
    private static void radar(Minecraft mc){
        oreResult="";
        if(mc.level==null||mc.player==null)return;
        BlockPos center=mc.player.blockPosition();double best=Double.MAX_VALUE;
        for(int dx=-8;dx<=8;dx++)for(int dy=-8;dy<=8;dy++)for(int dz=-8;dz<=8;dz++){
            BlockPos pos=center.offset(dx,dy,dz);
            if(!mc.level.hasChunkAt(pos))continue;
            String id=BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(pos).getBlock()).getPath();
            if(!(id.endsWith("_ore")||id.equals("ancient_debris")))continue;
            double d=center.distSqr(pos);
            if(d<best){best=d;oreResult="Minerio: "+id+" @ "+pos.getX()+","+pos.getY()+","+pos.getZ();}
        }
    }
    public static String help(Minecraft mc){
        if(mc.player==null)return "Entre em um servidor.";
        if(mc.player.getHealth()<mc.player.getMaxHealth()*0.5f)return "ALERTA: vida baixa. Cure-se e procure abrigo.";
        if(mc.player.getFoodData().getFoodLevel()<9)return "ALERTA: fome baixa. Procure comida.";
        if(mc.player.getOffhandItem().getItem()!=Items.TOTEM_OF_UNDYING)return "Dica: equipe um totem na mao secundaria.";
        List<Deal> d=deals();
        if(d.isEmpty())return "Abra /shop, percorra categorias e use P para capturar preco.";
        Deal x=d.getFirst();
        return "Maior lucro: "+x.name()+" | Compra "+fmt(x.buy())+" | Venda "+fmt(x.sell())+" | +"+fmt(x.profit());
    }
    private static String fmt(double v){return String.format(Locale.ROOT,"%.2f",v);}
    private static final class Rgba {static final int PANEL=0xCC101B2D;}

    public static final class Panel extends Screen {
        private final int page;
        public Panel(int page){super(Component.literal("ONICLIENT"));this.page=page;}
        @Override protected void init(){
            int x=width/2-197,y=height/2-112;
            String[] tabs={"INICIO","ECONOMIA","ASSISTENTE","VISUAL"};
            for(int i=0;i<tabs.length;i++){
                final int p=i;
                addRenderableWidget(Button.builder(Component.literal(tabs[i]),b->minecraft.setScreen(new Panel(p)))
                    .bounds(x+i*100,y+27,96,20).build());
            }
            if(page==3){
                addRenderableWidget(Button.builder(Component.literal("Night Vision: "+NIGHT),b->{NIGHT=!NIGHT;reload();}).bounds(x+15,y+71,220,20).build());
                addRenderableWidget(Button.builder(Component.literal("X-Ray: "+XRAY),b->{toggleXray(minecraft);reload();}).bounds(x+15,y+97,220,20).build());
                addRenderableWidget(Button.builder(Component.literal("Radar de minerios: "+RADAR),b->{RADAR=!RADAR;reload();}).bounds(x+15,y+123,220,20).build());
                addRenderableWidget(Button.builder(Component.literal("HUD: "+HUD),b->{HUD=!HUD;reload();}).bounds(x+15,y+149,220,20).build());
            }
            if(page==1)addRenderableWidget(Button.builder(Component.literal("Abrir /shop e escanear com P"),b->{onClose();minecraft.player.displayClientMessage(Component.literal("[ONI] Abra o /shop e clique no botao ONI no canto superior direito."),false);}).bounds(x+15,y+174,235,20).build());
            addRenderableWidget(Button.builder(Component.literal("FECHAR"),b->onClose()).bounds(x+302,y+201,90,19).build());
        }
        private void reload(){minecraft.setScreen(new Panel(page));}
        @Override public void render(GuiGraphics g,int mx,int my,float delta){
            g.fill(0,0,width,height,0xB9040810);
            int x=width/2-204,y=height/2-120;
            g.fill(x,y,x+408,y+244,0xFF111A2B);
            g.fill(x,y,x+408,y+32,0xFF163E49);
            g.drawString(font,"ONICLIENT  |  FABRIC 1.21.11",x+13,y+12,0xFF83FFE2,true);
            int t=y+66;
            if(page==0){
                line(g,"ASSISTENTE DE SEMI-ANARQUIA",x+15,t,0xFF6CFFD7);
                line(g,"Itens cadastrados: "+PRICES.size()+" | Negocios lucrativos: "+deals().size(),x+15,t+23,0xFFE6F0FA);
                line(g,"Ultima tela: "+lastShop+" | Itens reconhecidos: "+lastFound,x+15,t+43,0xFFC1CFDF);
                line(g,"RSHIFT Menu | P Escanear | N Visao noturna | X X-Ray",x+15,t+72,0xFFC1CFDF);
                line(g,"Abra /shop e use ONI: ESCANEAR (P) no canto superior.",x+15,t+92,0xFFF2D78B);
            } else if(page==1){
                line(g,"LUCROS (compra / venda por item)",x+15,t,0xFF6CFFD7);
                List<Deal> list=deals();
                if(list.isEmpty())line(g,"Nenhum lucro ainda. Navegue pelo /shop.",x+15,t+22,0xFFE6F0FA);
                for(int i=0;i<Math.min(7,list.size());i++){
                    Deal d=list.get(i);
                    line(g,(i+1)+". "+d.name()+" | "+fmt(d.buy())+" -> "+fmt(d.sell())+" | +"+fmt(d.profit()),x+15,t+22+i*18,0xFFE6F0FA);
                }
            } else if(page==2){
                line(g,"ONI ASSISTANT - REGRAS LOCAIS",x+15,t,0xFF6CFFD7);
                line(g,help(minecraft),x+15,t+28,0xFFE5EFFF);
                line(g,"Nao usa servidor de IA nem acessa precos ocultos.",x+15,t+57,0xFFF2D78B);
                line(g,"Para melhores dicas, abra mais categorias do /shop.",x+15,t+78,0xFFC1CFDF);
            } else {
                line(g,"VISUAIS / EXPLORACAO",x+15,t-8,0xFF6CFFD7);
            }
            super.render(g,mx,my,delta);
        }
        private void line(GuiGraphics g,String s,int x,int y,int color){
            if(s.length()>69)s=s.substring(0,66)+"...";
            g.drawString(font,s,x,y,color,false);
        }
    }
}