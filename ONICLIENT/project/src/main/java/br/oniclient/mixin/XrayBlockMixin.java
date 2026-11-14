package br.oniclient.mixin;
import br.oniclient.OniClient;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.RenderShape;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
@Mixin(BlockBehaviour.BlockStateBase.class)
public abstract class XrayBlockMixin {
    @Inject(method="getRenderShape", at=@At("HEAD"), cancellable=true)
    private void oni$shape(CallbackInfoReturnable<RenderShape> cir) {
        if(!OniClient.XRAY) return;
        BlockState s=(BlockState)(Object)this;
        if(s.isAir()) return;
        String id=BuiltInRegistries.BLOCK.getKey(s.getBlock()).getPath();
        if(!(id.endsWith("_ore") || id.equals("ancient_debris") || id.equals("bedrock") ||
             id.contains("chest") || id.contains("spawner") || id.contains("portal") ||
             id.contains("lava") || id.contains("water"))) cir.setReturnValue(RenderShape.INVISIBLE);
    }
}