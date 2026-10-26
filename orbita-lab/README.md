# Órbita OS 2.0

Protótipo de interface espacial para celular e desktop, inspirado em headsets VR. Projeto independente, sem vínculo com a Meta.

## Interface baseada nas referências

Biblioteca com menu lateral, busca, filtros, ordenação e cartões coloridos. Dock compacto, cenário futurista vetorial incluído e uma barra suspensa própria para cada janela.

- Aproximar, afastar, inclinar, fixar na visão, minimizar e restaurar painéis.
- Organizar janelas lado a lado no desktop; sobrepor no celular com seletor de janelas.
- Várias janelas de navegador independentes, com até 12 abas por janela.
- Grade livre opcional e galeria de fotos e vídeos locais.
- Atalhos web para YouTube, Spotify, Instagram, WhatsApp e Facebook (sem emular seus aplicativos nativos).

## Recursos

- Painéis móveis e redimensionáveis, com controle por toque ou mouse.
- Navegador flutuante com alternativa de abertura em outra aba.
- Notas salvas localmente e reprodução de vídeos do aparelho.
- Ambientes visuais e imagem da câmera como fundo.
- Rastreamento de até duas mãos com MediaPipe e seleção por pinça.
- Estimativa experimental de movimento da câmera sem giroscópio.
- Modo de tela dividida para visores de celular.

## Executar

Publique os arquivos desta pasta em uma hospedagem estática **HTTPS**. Não precisa de npm, backend ou chave de API.

Para testar no computador com Python:

```sh
python -m http.server 8080
```

Abra `http://localhost:8080`. Para acessar a câmera pelo celular, use **HTTPS**; HTTP da rede local geralmente não permite câmera.

## Limites

A IA de mãos baixa MediaPipe e os modelos do jsDelivr quando ativada e requer internet. As imagens são processadas localmente pelo aplicativo. O modelo não está incluído no ZIP.

O movimento visual compara blocos entre quadros e estima deslocamento 2D relativo. Não reconhece o cômodo, não implementa SLAM, profundidade, rastreamento 6DoF ou todos os recursos de um Meta Quest. Pode acumular erro; use Centralizar e o controle por toque quando necessário.

O modo visor usa duas vistas aproximadas, sem estereoscopia real ou calibração óptica. Sites externos podem bloquear a incorporação em iframe e não aceitam controle por gestos deste aplicativo.

Consulte [LEIA-ME.txt](LEIA-ME.txt) para instruções, privacidade, compatibilidade e verificações realizadas, e [LICENCAS.txt](LICENCAS.txt) para créditos.

## Verificação

JavaScript verificado com `node --check`; movimento validado com imagens sintéticas. Interface testada no Chromium em desktop e celular, incluindo busca, filtros, grade livre, múltiplas abas e janelas, distância, inclinação, fixação, minimização, organização, notas, URLs, câmera negada e modo visor. O efeito espacial é feito com perspectiva CSS; não é uma superfície 3D curva ou um sistema operacional de headset. Rastreamento de mãos e movimento precisam de validação em aparelho físico.
