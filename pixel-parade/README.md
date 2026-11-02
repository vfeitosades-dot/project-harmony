# PIXEL PARADE — O CIRCO DAS FAÍSCAS

Jogo **original** 2D em pixel art para navegador e Android, gênero boss-rush com inspirações gerais de jogos run-and-gun. Desenvolvido para este pacote. Nenhuma arte ou música do jogo comercial Cuphead foi copiada.

## O que já funciona no protótipo

- Jogo HTML5 offline (sem CDN), Canvas 480 x 270, 6 arenas e 6 chefes com 3 atos e padrões individuais.
- Solo ou cooperativo **LOCAL** para 2 jogadores compartilhando a mesma tela.
- Movimento, pulo, magia, dash, parry em esferas rosas, ataque especial EX ao acumular 3 pontos.
- Indicadores de vida, chefe, progresso salvo no navegador, derrota/recomeçar, desbloqueio progressivo, pausas.
- Suporte inicial a teclado, gamepads e controles touch para o jogador 1.
- PNGs originais dos personagens, dos seis chefes e duas pranchas de referência visual. O jogo atual desenha sprites proceduralmente; os PNGs são guias visuais para integração posterior.
- Projeto Android WebView e workflow de compilação via GitHub Actions **incluídos como fonte**, não como APK já compilado.

## O que NÃO está pronto

- **Não há APK compilado neste ZIP**, pois o ambiente atual não possui Android SDK/Gradle. GitHub Actions pode gerá-lo quando o projeto estiver publicado, com a integração apropriada.
- **Online entre aparelhos ainda não implementado.** O multiplayer jogável é cooperativo local no mesmo aparelho/computador.
- Três fases de plataforma corrida, loja, mapa de campanha, cenas animadas completas, trilha musical arranjada e exportação release assinada estão descritos no PROMPT_COMPLETO.txt para desenvolvimento futuro.
- Ainda necessita teste de execução em telefone Android físico.

## Jogar agora no computador/celular

Abrir `web/index.html` num navegador moderno. Se o navegador bloquear `file://`, inicie um servidor local na pasta `web/` com `python -m http.server 8000` e abra `http://localhost:8000`. Para usar no celular via rede local, hospede em um servidor HTTPS próprio. O APK é outra maneira de acessar offline.

No menu, toque em **1 JOGADOR** ou **2 JOGADORES**; selecione arena. As arenas destravam na sequência após vencer.

## Controles

| Ação | P1 (teclado) | P2 (teclado) | Touch |
|---|---|---|---|
| Mover | A, D | ←, → | ◀, ▶ (P1) |
| Pular | W ou Espaço | ↑ | PULO |
| Magia | J | Numpad 1 ou tecla 1 | ✦ |
| Dash | K | Numpad 2 ou tecla 2 | DASH |
| Parry | L | Numpad 3 ou tecla 3 | PARRY |
| Especial EX | E | Numpad 0 | no futuro |
| Pausar | P ou Esc | P ou Esc | Ⅱ |

No gamepad, A pula, X ou gatilho direito dispara magia, B dash, Y parry, ombro esquerdo usa EX. O menu é operado por toque ou teclado; uso de gamepad para navegar no menu está previsto para atualização. Para co-op mobile, preferir dois controles Bluetooth.

## Compilar APK no Android Studio

1. Instalar Android Studio com Android SDK Platform 35 e JDK 17.
2. Abrir a pasta `android/` como projeto Gradle (usar Gradle 8.7).
3. Manter a cópia de `web/index.html` atualizada em `android/app/src/main/assets/web/index.html`.
4. Executar **Build > Build Bundle(s) / APK(s) > Build APK(s)**. Ou executar `gradle :app:assembleDebug` na pasta `android/`.
5. Encontrar o APK de teste em `android/app/build/outputs/apk/debug/app-debug.apk`. Instalar no próprio telefone para testar.

## GitHub Actions (APK sem Android Studio local)

O workflow `.github/workflows/build-pixel-parade-apk.yml` assume que a pasta inteira do projeto está em `pixel-parade/` na raiz do repositório. Mover o workflow para `.github/workflows/build-pixel-parade-apk.yml` **na raiz**. Ao enviar, ir a `Actions` > `Build Pixel Parade APK` > `Run workflow`, e após o build concluído baixar `PixelParade-APK-debug` (ZIP contendo o APK). A existência do YAML não garante sucesso: conferir logs e artifact real.

O arquivo APK debug só deve ser distribuído para testes. Para distribuição pública, configurar assinatura release e acompanhar as políticas atuais do Google Play.

## Estrutura

```
PixelParade_Projeto/
├── PROMPT_COMPLETO.txt
├── README.md
├── web/index.html
├── android/ (projeto nativo Java + Gradle + HTML offline)
├── assets/
│   ├── sprites/ (2 spritesheets de heróis + 6 bosses)
│   ├── referencias/ (arte, HUD e captura real do protótipo)
│   └── gerar_arte.py
├── docs/REFERENCIAS.md
└── .github/workflows/build-pixel-parade-apk.yml
```

**Aviso de arte:** Os PNGs autorais são: `prancha_personagens_e_chefes.png`, `direcao_de_arte_e_ui.png`, `captura_jogo_real.png` e `sprites/`.
