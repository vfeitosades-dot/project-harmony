package br.com.onicraft.onimarket.admin;

import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;
import java.util.Locale;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public final class OniMarketAdminPlugin extends JavaPlugin implements CommandExecutor {
    private final Map<UUID, Long> lastRequest = new HashMap<>();

    @Override public void onEnable() {
        if (getCommand("onimarketplayers") != null)
            getCommand("onimarketplayers").setExecutor(this);
        getLogger().info("OniMarket v1.4 ativado: /onimarketplayers liberado para todos os jogadores.");
    }

    @Override public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (!(sender instanceof Player viewer)) {
            sender.sendMessage("Este comando precisa ser usado por um jogador dentro do jogo.");
            return true;
        }
        long now = System.currentTimeMillis();
        long previous = lastRequest.getOrDefault(viewer.getUniqueId(), 0L);
        if (now-previous < 2000L) {
            viewer.sendMessage("Aguarde 2 segundos entre atualizacoes.");
            return true;
        }
        lastRequest.put(viewer.getUniqueId(),now);
        viewer.sendMessage("[ONIMARKET:BEGIN]");
        for (Player p : Bukkit.getOnlinePlayers()) {
            Location loc = p.getLocation();
            String world = loc.getWorld() == null ? "unknown" : loc.getWorld().getName().replace("|", "_");
            viewer.sendMessage("[ONIMARKET:POS]" + p.getName() + "|" + world + "|"
                + loc.getBlockX() + "|" + loc.getBlockY() + "|" + loc.getBlockZ());
        }
        viewer.sendMessage("[ONIMARKET:END]");
        return true;
    }
}
