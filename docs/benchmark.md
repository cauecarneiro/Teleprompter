# Benchmark de apps de teleprompter

Leitura feita em 14/10/2026. Método: observação documentada de fonte pública (página da App Store pela API oficial do iTunes, site e ajuda do fabricante, README e código no GitHub, feed RSS de avaliações da App Store). Não instalei nenhum app. Nada aqui é suposição de como o app funciona por dentro: quando algo vem de terceiro ou de concorrente, está marcado; o que não achei está como **n/e** (não encontrado).

Legenda: n/e = não encontrado na fonte lida · (T) = fonte de terceiro · (C) = fonte de concorrente · (V) = afirmação do próprio fabricante, sem medição independente.

Notas de leitura que mudam a interpretação:

- **"Teleprompter Premium (Joeallen)"** é hoje o **Teleprompter Pro**: a própria página diz "Teleprompter Pro (formerly known as Teleprompter Premium)... renamed ... from Late 2023" e os termos apontam para `joeallenpro.com`. A mesma editora (Teleprompter Apps Ltd) publica também **Teleprompter** (grátis, id941620509) e **Video Teleprompter** (id1444106389). Existe outro app com o nome "Teleprompter Premium" (Martinho Medeiros, 0 avaliações nos EUA, 2 no Brasil): entra como referência de design mínimo, não é o do Joeallen.
- **"Elegant Teleprompter"** não existe como app com esse nome exato. Achei dois anúncios: "Elegant Teleprompter Captions", hoje **OnTake Teleprompter & Captions** (Dasas Dijital, 4,77 com 559 notas), e "Elegant Teleprompter for Video" (Appiverse Studio, 1 nota de 1 estrela; o texto do anúncio chama o app de "ScriptCam"). Uso o OnTake como o representante.
- **"Teleprompter for Video"** é da Norton Five Ltd (id1139307843); **"Video Teleprompter"** é da Teleprompter Apps Ltd. São apps diferentes.
- Número de avaliações e notas: API do iTunes (loja dos EUA), 14/10/2026. Citações de avaliação: feed RSS `https://itunes.apple.com/us/rss/customerreviews/page=N/id=<ID>/sortby=mostrecent/json` (as 500 mais recentes por app, ou menos quando o app tem menos). Cada citação traz estrelas, data e título para achar na página `https://apps.apple.com/us/app/id<ID>?see-all=reviews`.

---

## 1. Tabela comparativa

### 1.1 Texto, rolagem e controle

| App | Onde fica o texto em relação à lente | Modos de rolagem | Controle (voz / remoto / teclado / pedal) | Contagem | Marcadores e seções | Ajustes de texto |
|---|---|---|---|---|---|---|
| **BIGVU** | n/e na página oficial. Avaliação (T) de 16/09/2023 sobre outro app diz que o BIGVU tem "text running all the way into the camera" | Velocidade ajustável com + e − durante a gravação; "pausar no silêncio" e "parar no fim do roteiro" (só em resultado de busca do suporte, artigo não lido) | Voz: n/e (só pausa no silêncio). Remoto: n/e | n/e | n/e (modo "Read & Record" com retomar de um ponto: avaliações reclamam que o ponto de retomada erra) | Tamanho da caixa, fonte, velocidade, posição de rolagem |
| **PromptSmart Pro** | "Selfie Mode: fix text next to the camera" (ao lado ou abaixo da câmera frontal, no PromptSmart+) | **VoiceTrack** (segue a voz); velocidade fixa de 70 a 400 palavras por minuto; manual | Botões de volume dão play e pause; Remote Control (assinatura Extended); sala de controle web | n/e | "Notecards" (máx. recomendado 200); texto marcado com tag é pulado ("headers or directions") | Margens laterais mais estreitas, inverter para vidro; fonte máxima 10 reclamada |
| **Teleprompter Pro** (ex-Premium, Joeallen) e **Teleprompter** | Margens laterais ajustáveis; não achei como mover o texto para perto da lente. Avaliações pedem isso (2021, 2023, 2026) | Contínuo ou paginado; **Timed Scrolling** (percorre o roteiro numa duração definida) | Teclado, controle de mídia, pedal, gamepad, Apple Watch, outro iOS por Bluetooth, navegador no mesmo Wi-Fi. Voz: n/e | Sim ("countdown timer before scrolling begins") | **Cue points** para pular a trechos | Fonte, cor, fundo, margens; guia de leitura (seta ou linha); tempo decorrido e restante |
| **Video Teleprompter** (Teleprompter Apps) | "automatically scrolls your scripts on the side of display closest to the front-facing camera" | Contínuo ou paginado | Teclado, mídia, gamepad, pedal, Apple Watch. Voz: n/e (avaliação 01/06/2025: "no voice sync") | Sim | n/e | "Adjustable text window" |
| **Teleprompter for Video** (Norton Five) | "scrolls next to the camera lens"; modo flutuante sobre a câmera nativa | "Voice-assisted scrolling"; velocidade | Bluetooth, teclado, pedal, Apple Watch (também liga e desliga a gravação) | Sim, no início e para encerrar a gravação no fim do roteiro | n/e | Fonte, velocidade, "many other settings"; rich text |
| **OnTake** (ex-Elegant Teleprompter Captions) | "Adjustable font size, color, opacity & placement" | Velocidade natural ajustável no meio da gravação | n/e | Sim, personalizável | n/e | Fonte, cor, opacidade, posição; espelho/inverter |
| **Captions** | n/e | **Contínuo ou cena a cena**; slider de velocidade (ajuda oficial); "ajuste automático ao seu ritmo" é (V) | n/e | Timer de 15, 30, 60 ou 90 (a unidade não aparece no trecho lido) | Cena a cena; "undo the last segment" | n/e |
| **CapCut** | n/e | Velocidade manual (ícone de configurações). Sem voz (C: teleprompter.com) | n/e | n/e | n/e | Tamanho e cor da fonte; limite de 5.000 caracteres |
| **Edits (Instagram)** | Janela **arrastável** para qualquer ponto; o texto aparece "just below the front-facing camera" (T: Social Media Today, 31/05/2026) | Sliders de velocidade e tamanho | n/e | n/e | n/e | Tamanho e velocidade |
| **QPrompt** (desktop) | Faixa de leitura ("read region") com posição e altura ajustáveis; barras pretas semitransparentes em cima e embaixo para "continuar olhando a câmera" | Passos de velocidade com curva de aceleração; no fim: parar, sair ou repetir | Teclado, roda do mouse; há telas de controle remoto (`RemotePage.qml`, `Remote.qml`: arquivos vistos, não lidos) | Sim (`Countdown.qml`, iterações configuráveis) | **Marcadores** comuns e nomeados, com ação (cena do OBS, comando) | Fonte, espaçamentos, ponteiros, espelho |
| **Imaginary Teleprompter** (web/desktop) | Áreas de foco ("focus areas") para webcam, tablet ou equipamento profissional | Passos de velocidade com curva | Teclado, roda do mouse | n/e (tem cronômetro) | Tecla qualquer vira marcador; marcadores sem nome com Home e End | Fonte, estilos; duas instâncias (uma para o monitor) |

### 1.2 Gravação, saída e preço

| App | Gravação (resolução, fps, lente, microfone) | Como salva | Legenda | Preço e paywall (EUA, 14/10/2026) | Nota e avaliações |
|---|---|---|---|---|---|
| **BIGVU** | Frente e traseira, retrato ou paisagem, exposição manual, monitor de áudio; 4K só no Pro (busca de suporte, não li o artigo) | Rolo da câmera ou nuvem BIGVU; edição em outra tela | Automática (tarja, tema) | App grátis. Compras: Starter mensal $24,99; Starter 6 meses $79,99; Pro 6 meses $99,99; Pro anual $139,99; anual $89,99. Grátis corta em 9 min e com marca (T: PulseSignal; um usuário confirma o corte, 03/05/2026) | 4,73 · 35.924 |
| **PromptSmart Pro** | Vídeo HD no app (Selfie Mode); toque para focar, travar exposição e foco. Resolução: avaliação de 02/01/2026 diz "zero control over camera resolution" | n/e | n/e | **App $29,99** + assinatura Extended ($3,99 e $34,99 nas compras). Conflito não resolvido: o anúncio do Pro põe o VoiceTrack no app e só remoto, sincronia e Scroll Assist na assinatura; avaliações de 2025 e 2026 dizem que a voz também ficou atrás da assinatura. No PromptSmart+ (app grátis, 7 dias de teste) tudo exige assinatura | 4,61 · 11.885 |
| **Teleprompter Pro / Teleprompter** | Grava com a câmera frontal; efeitos em tempo real (fundo virtual, retrato); 120 Hz em ProMotion | "Save recorded videos directly to Photos or share" | Legenda `.srt` automática (Pro) | **Grátis**; Pro $59,99 (assinatura anual) ou compra única; um item "Teleprompter $159,99" aparece nas compras. Espelhar o texto virou Pro em 2025 (ver dores) | Teleprompter 4,82 · 33.774; Pro 4,74 · 15.639 |
| **Video Teleprompter** | 4K, toque para focar, travar AE/AF, obturador e ISO, microfone externo, monitor de áudio, tela verde | n/e | `.srt` (assinatura) | Grátis; Pro por compra única ou assinatura (valores n/e na página); avaliações citam $59,99 | 4,75 · 6.599 |
| **Teleprompter for Video** | 720p, 1080p, 4K; 24, 25, 30, 60 fps; frontal e traseira; microfone interno e externo; travar AE/AF; zoom por pinça; grade 3x3 | Vídeos ficam no app para editar; "export to camera roll" | Automática e `.srt` (paga) | Grátis até **750 caracteres** (~1 min); Premium anual $29,99 a $59,99 e mensal $8,99 a $9,99 (vários itens iguais na página) | 4,87 · 15.002 |
| **OnTake** | Proporções 1:1, 4:5, 16:9, 9:16; HD, Full HD, 4K; microfone interno ou externo; pausar e retomar; "star takes" | n/e | n/e | Grátis; preço das compras n/e | 4,77 · 559 |
| **Captions** | HD ou 4K; 30 ou 60 fps; flash; virar câmera com toque duplo | Edita na mesma sessão | Sim (é o produto) | Plano Basic **$9,99/mês** inclui "Camera & Teleprompter"; Lite (Android) $4,99; Free tem câmera, teleprompter não é citado | 4,74 · 38.491 |
| **CapCut** | Gravação dentro do app com duração de 15 s, 60 s, 3 min ou "one shot"; resolução n/e | Projeto no editor | Sim (é o produto) | Teleprompter: preço n/e; app grátis | 4,61 · 1.123.793 |
| **Edits** | "camera settings for resolution, frame rate and dynamic range" (App Store); lente n/e | Projeto no Edits; botão Exportar | Sim | Grátis | 4,79 · 93.563 |
| **QPrompt** | Não grava vídeo | Não se aplica | Não se aplica | Grátis, GPL-3. Builds novas pelo Patreon | n/e |
| **Imaginary** | Não grava vídeo | Não se aplica | Não se aplica | Grátis, GPL-3. Último commit 02/01/2021 | n/e |

---

## 2. Fichas curtas

**BIGVU Teleprompter Captions AI** · leitura 14/10/2026 · [App Store](https://apps.apple.com/us/app/bigvu-teleprompter-captions-ai/id1124958568) · [tutorial](https://bigvu.tv/tutorials/pt/teleprompter/)
Teleprompter mais editor com IA (legenda, tema, tela verde, correção de olhar, avatar). Fluxo "Read & Record": cola o roteiro, ajusta o visor do prompter, grava, depois edita. Versão 2.86.0 de 11/10/2026, release notes só falam de "Autoshorts Agent" e avatares (o foco virou IA). Preço alto e confuso (cinco assinaturas). Na amostra de 500 avaliações recentes, 57% são de 1 ou 2 estrelas. Dor dominante: cobrança, travamento, vídeos e roteiros que somem.

**PromptSmart Pro (VoiceTrack)** · 14/10/2026 · [App Store Pro](https://apps.apple.com/us/app/promptsmart-pro-teleprompter/id894811756) · [PromptSmart+](https://apps.apple.com/us/app/promptsmart/id1526733375) · [como funciona](https://www.promptsmart.com/how-it-works.html)
O único com rolagem pela voz como produto central, processada no aparelho. Pro: só inglês, até 5.000 palavras, uso contínuo recomendado de ~30 min, microfone com fio recomendado. PromptSmart+ amplia VoiceTrack para 15 idiomas (inclui português, segundo o texto do fabricante, (V)). Pago duas vezes (app $29,99 mais assinatura) e a mais mal avaliada em recência: 67% de 1 ou 2 estrelas na amostra, com 125 de 335 citando voz. Quem gosta, gosta da voz ("It tracks my voice and follows perfectly", 18/08/2026).

**Teleprompter Pro (ex-Teleprompter Premium, Joeallen) e Teleprompter** · 14/10/2026 · [Pro](https://apps.apple.com/us/app/teleprompter-pro/id941070561) · [Teleprompter](https://apps.apple.com/us/app/teleprompter/id941620509) · [site](https://teleprompterpro.com)
Teleprompter de estúdio (a editora diz usar na Netflix, BBC e outros, (V)) com a gravação como acessório. Muito controle: Timed Scrolling, cue points, paginação, teclado, pedal, Apple Watch, guia de leitura. Em 2025 moveu o espelhamento para o plano Pro, o que gerou onda de 1 estrela. Pouca reclamação de voz porque não tem voz. Só 23% de avaliações ruins na amostra, a melhor taxa entre os apps de mercado de massa.

**Video Teleprompter** (Teleprompter Apps) · 14/10/2026 · [App Store](https://apps.apple.com/us/app/video-teleprompter/id1444106389)
O "original" que coloca o texto no lado da tela mais perto da câmera frontal. 4K, ISO, obturador, tela verde. Última versão 3.9.19 de 16/07/2022 (parado). Reclamações: "can't do 60 fps, no auto speech recognition" (10/05/2026), áudio com DJI, preço de $59,99.

**Teleprompter for Video** (Norton Five) · 14/10/2026 · [App Store](https://apps.apple.com/us/app/teleprompter-for-video/id1139307843)
Mais recursos de captura (24 a 60 fps, 4K, zoom, grade, travar exposição) e rolagem por voz, mais edição pós-gravação com IA. Grátis só até 750 caracteres. Reclamações de teste "grátis" que cobra na hora, áudio fora de sincronia e travar no meio de entrevista.

**OnTake** (ex-Elegant Teleprompter Captions) · 14/10/2026 · [App Store](https://apps.apple.com/us/app/ontake-teleprompter-captions/id1626361311) · [Elegant Teleprompter for Video](https://apps.apple.com/us/app/elegant-teleprompter-for-video/id6759238471)
Proporções de Reels (9:16, 4:5), pausar e retomar sem perder o take, "star takes". Pouca base de avaliação (27 no feed). O anúncio "Elegant Teleprompter for Video" parece cópia de texto de outro app (cita "ScriptCam", 1 nota): não usar como referência.

**Captions** · 14/10/2026 · [ajuda: câmera](https://captions.ai/help/docs/project/camera) · [planos](https://captions.ai/help/docs/subscriptions) · [página do teleprompter](https://captions.ai/features/ai-teleprompter)
Teleprompter é um módulo dentro de um editor de IA. Cena a cena ou contínuo, roteiro colado ou gerado, resolução HD/4K e 30/60 fps, desfazer o último segmento. Nenhuma avaliação das 500 lidas é sobre o teleprompter (2 citam, as duas elogiam); as queixas são do editor. Promessa de velocidade automática é só marketing (V), sem método nem medição.

**CapCut** · 14/10/2026 · [CapCut](https://www.capcut.com/resource/iphone-teleprompter-app)
"All tools" > "Quick actions" > Teleprompter. Limite de 5.000 caracteres, velocidade manual no ícone de configurações, grava 15 s, 60 s, 3 min ou "one shot" e rola sozinho ao gravar. Zero das 500 avaliações recentes mencionam teleprompter. O detalhe "não existe no desktop nem na web" vem de concorrente (C).

**Edits (Instagram/Meta)** · 14/10/2026 · [tutorial oficial](https://edits.instagram.com/tutorials/teleprompter/) · [App Store](https://apps.apple.com/us/app/edits-video-editor/id6738967378)
Câmera do Edits, ícone de roteiro, cola ou escreve, sliders de tamanho e velocidade, janela arrastável. Lançado em junho de 2025 ([Social Media Today](https://www.socialmediatoday.com/news/instagram-edits-video-app-teleprompter-overlays-update/750386)) e levado para a câmera principal do Instagram em maio de 2026 ([Social Media Today](https://www.socialmediatoday.com/news/instagram-introduces-teleprompter-tool/821564/)). Sem voz, contagem ou espelho nas fontes lidas. Nota 4,79 com 93.563 avaliações; o teleprompter em si tem 1 reclamação (editor de texto) e 1 elogio na amostra.

**QPrompt** · 14/10/2026 · [GitHub](https://github.com/Cuperino/QPrompt) (commit `5fd7eb2`, 14/10/2026)
Teleprompter de desktop e Android em C++/QML, GPL-3, mantido por uma pessoa. O README é só institucional; o que vale está no código (seção 5). Prioriza controle fino de velocidade e marcadores com ação.

**Imaginary Teleprompter** · 14/10/2026 · [GitHub](https://github.com/ImaginarySense/Imaginary-Teleprompter) (último commit `890316b`, 02/01/2021)
Versão web/Electron do mesmo autor do QPrompt (Javier Cordero). Mesma fórmula de velocidade. "Voice control" aparece só como item de TODO. Parado desde 2021: serve de leitura de algoritmo, não de produto.

---

## 3. Dores recorrentes dos usuários

Base: avaliações de 1 e 2 estrelas do feed RSS (as 500 mais recentes por app; janelas: BIGVU 30/04/2022 a 12/10/2026, PromptSmart 25/06/2020 a 08/10/2026, Teleprompter 20/03/2025 a 12/10/2026, Teleprompter Pro 08/06/2020 a 10/10/2026, Teleprompter for Video 02/01/2017 a 08/10/2026, Video Teleprompter 30/11/2018 a 01/10/2026). Contagens são por palavra-chave: servem de ordem de grandeza, não de pesquisa fechada. "Ruins" = 1 ou 2 estrelas: BIGVU 285, PromptSmart 335, Teleprompter 115, Teleprompter Pro 98, Teleprompter for Video 75, Video Teleprompter 40.

**1. Cobrança, paywall e assinatura (a dor número 1 em todos).** Citações em 112 das 285 ruins do BIGVU, 157 das 335 do PromptSmart, 35 das 115 do Teleprompter.
- Recurso básico virou pago: "Charging a $60 subscription for features that use to be free ... I can't mirror my text" (Teleprompter, 1★, 22/09/2026). "Mirror text is a pro feature? A teleprompter is useless without being able to mirror the text" (Teleprompter, 1★, 06/09/2026).
- Pagar o app e a assinatura: "First it charges you $30 for the app, then you have to pay another monthly fee on top to actually use it" (PromptSmart, 1★, 22/10/2025). "Doesnt include voice scrolling: Bought this for the voice scrolling function but that is a seperate subscription" (PromptSmart, 1★, 15/07/2026).
- Sem teste: "Let me try it a week and see if I like it. I immediately deleted it when I could get no further without paying $59" (Teleprompter, 2★, 09/10/2026).
- "Teste grátis" que cobra na hora: "It said I could get a free 3 day trial but I was charged as soon as I accepted" (Teleprompter for Video, 1★, 09/03/2026).
- Upsell em loop: "I can't even open the app without a loop of marketing trying to push me to upgrade to AI" (BIGVU, 1★, 13/04/2026).

**2. A voz perde o lugar, para ou pula (só PromptSmart e Teleprompter for Video).** 125 das 335 ruins do PromptSmart citam voz.
- "It will move then just stop whenever it pleases" (PromptSmart, 1★, 15/10/2025). "It stops following my voice the vast majority of the time. Especially on longer scripts (which is when you need it the most)" (PromptSmart, 1★, 09/08/2025).
- Pulo: "It either completely stops or jumps ahead and skips part of the script" (PromptSmart, 1★, 08/12/2020).
- "It has always just stopped randomly as if its suddenly stopped listening and then scrolls up super fast" (Teleprompter for Video, 2★, 02/09/2025).
- Em produção: "the voice scroll option did not work. We switched to the remote and it was super buggy" (PromptSmart, 2★, 13/11/2025).
- Hardware: DJI e Bluetooth derrubam o app ou o reconhecimento (BIGVU 17/09/2026; PromptSmart 16/04/2023; Teleprompter for Video 17/10/2024).

**3. Texto longe da lente, olhar errado.**
- "The text is centered on your phone with no ability to align it to the left side of the screen so as you read the script your eyes are on the camera. So, in your video you look like you're looking away" (Teleprompter, 1★, 03/10/2026).
- "It centers the copy rather than putting it close to the camera" (Teleprompter Pro, 1★, 02/02/2023). "Margins need to be adjusted independently ... text as close to the camera on one end" (Teleprompter Pro, 3★, 31/01/2023).
- "Needs option to shift text higher on screen, especially the lines being read during voice scroll ... The only advantage Bigvu has on this is having the text running all the way into the camera" (Teleprompter for Video, 3★, 16/09/2023).

**4. Travamentos e queda no meio da gravação.**
- "Anytime you try to hit play the app just crashes. 100% of the time" (PromptSmart, 1★, 14/08/2026).
- "Teleprompter freezes. Wasted 3 hours troubleshooting trying to record a 12 min video" (BIGVU, 1★, 28/07/2026). "terrible teleprompter system for presentations above 5 minutes" (BIGVU, 1★, 07/05/2026).
- "Whenever I use this app it over burdens my phone ... the phone gets hot and the video freezes while I'm recording" (Teleprompter, 1★, 15/07/2026).
- A própria editora corrigiu em 06/10/2026 um erro de "backgrounding the app whilst recording" que dessincroniza o botão de gravar.

**5. Rolagem engasgada, pula ou muda de velocidade.**
- "THE SCROLLING LAGS: Eight out of 10 times, the scrolling will lag forcing me to stop recording ... I'm only recording one to three minute scripts for reels" (PromptSmart, 1★, 30/10/2025).
- "Words jumping doing the scrolling like they having a seizure ... the output of the video is doing the same thing" (Teleprompter Pro, 1★, 24/06/2026).
- "I set the speed it works. I record and it works fine. I go for another record and all of a sudden it's a high speed, but still showing the slow speed" (BIGVU, 1★, 24/06/2026).
- "When trying to record videos and start at a new point within the script, the script jumps way far ahead and you can't back up" (BIGVU, 2★, 01/05/2026).
- "[the speed] doesn't remember ... when you tap the turtle icon" (Teleprompter Pro, 2★, 03/05/2026).

**6. Perda de roteiros e vídeos.**
- "I was in the middle of editing a video ... every one of my recordings are deleted ... My scripts are also gone" (BIGVU, 1★, 09/09/2026). "Randomly deletes projects" (Edits, 1★, 06/06/2026).
- "Open it up for an important event, and like magic, your words have dissolved into thin air" (Teleprompter, 1★, 31/07/2026).
- Vídeo preso dentro do app: "I recorded about half an hour of video ... this app doesn't let you save the video to your phone" (BIGVU, 1★, 26/03/2026).

**7. Áudio que some, abafa ou sai fora de sincronia.**
- "AUDIO MUTES: recorded a bunch of content using this app ... every video had no audio" (BIGVU, 1★, 19/03/2026). "No audio after I recorded a video" (Teleprompter for Video, 1★, 09/02/2026).
- "Video and sound out of sync" (Teleprompter for Video, 1★, 03/09/2026). "The sound quality through this app is really bad ... static and muffled" (Teleprompter for Video, 1★, 25/07/2025).

**8. Conta, login e internet obrigatórios.**
- "Why on Earth do you need to sign up for an account with these snakes to use the app" (Teleprompter, 1★, 13/09/2026).
- "Why I can't save and download scripts without internet?? It is crazy" (Teleprompter for Video, 2★, 24/04/2026).
- "Paid for onetime purchase but no longer can log in to use" (PromptSmart, 1★, 29/06/2026).

**9. Colar roteiro: formatação quebrada e importação ruim.**
- "PromptSmart only accepts cut and paste from iCloud ... I just want to cut, paste, read, and record" (PromptSmart, 1★, 06/09/2026).
- "Even when I copy format-less text ... the app screws up basic paragraph spacing, always resets the cursor to the end of the script when editing copy" (Edits, 1★, 17/07/2026).
- "My app kept crashing. It took me a while to realize that it couldn't handle a question mark in the title of my script" (PromptSmart, 1★, 03/06/2025).

**10. IA e recurso demais onde só se queria prompter.**
- "Last time I used this app it was a simple teleprompter, now it's full of a bunch of AI slop options ... training some AI somewhere with footage of your face" (BIGVU, 1★, 23/03/2026).
- Correção de olhar estraga: "it gave me a totally different eye color ... I looked like an alien" (Teleprompter for Video, 2★, 15/01/2026); "You can see the new eyes superimposed" (BIGVU, 1★, 24/10/2024); "auto eye contact ... more blurry than your original" (BIGVU, 1★, 14/03/2025).
- Reprocessar piora o vídeo: "videos started showing up pixelated and unusable after they were edited by the app" (BIGVU, 1★, 25/06/2026).

**11. Interface de gravação ambígua e texto ilegível.**
- "It's not clear whether the app is recording or not ... it should be screaming RECORDING" (Teleprompter, 2★, 17/07/2026).
- "Can't read words well on white background, and can't change font color" (Teleprompter, 3★, 12/08/2026).
- "Wish we could turn off HDR, looks washed out after editing" (Teleprompter, 3★, 16/10/2025). "Mirror Front Camera ... When I record a video it looks dift to what is being previewed" (Teleprompter, 3★, 24/09/2026).

**12. Lente frontal sem zoom ou grande-angular.**
- "In other apps, I'm able to switch from close to wide angle on the front camera. With this app I'm not able to" (Teleprompter for Video, 1★, 24/07/2026). "No zoom? ... Without pinch to zoom I can't frame myself right" (Video Teleprompter, 3★, 31/05/2021).
- Edits em iPhone novo: "The front facing camera of the app doesn't work ... it's tilted 90 degrees" (Edits, 1★, 22/09/2026).

---

## 4. O que um app minimalista para esse criador precisa ter

Perfil: câmera frontal, vertical, sozinho, roteiro do Notion em seções de CAIXA ALTA (ABERTURA UM, PONTE, CORPO, FECHO UM), vídeo vai direto para a galeria, visual limpo quase sem cor, custo zero. O guia dele já pede 4K, 30 fps, exposição travada, sem filtro e HDR desligado.

### Essencial

| # | Item | Quem prova que funciona / dor que evita |
|---|---|---|
| E1 | **Colar e gravar, sem conta, sem login, sem internet**; roteiro guardado só no aparelho com salvamento automático | Dor 8 (Teleprompter 13/09/2026; Teleprompter for Video 24/04/2026) e dor 9. Teleprompter Premium do Martinho promete tudo local ("processed and stored locally") |
| E2 | **Texto colado à lente**: bloco de leitura no topo, junto à câmera frontal, com altura e largura ajustáveis e o texto à esquerda ou à direita da lente | Video Teleprompter ("side of display closest to the front-facing camera"), PromptSmart Selfie Mode, Edits (janela arrastável). Dor 3 |
| E3 | **Rolagem suave a velocidade fixa**, ajustável durante a gravação, com a velocidade **lembrada** entre takes e mostrada em palavras por minuto | PromptSmart tem velocidade fixa de 70 a 400 wpm; QPrompt e Imaginary mostram a conta (seção 5). Dor 5: BIGVU muda sozinho (24/06/2026), Teleprompter Pro não lembra (03/05/2026). PromptSmart padrão em 70 foi reclamado como rápido demais (27/08/2026) |
| E4 | **Contagem regressiva** antes de gravar e antes de rolar | Teleprompter, Teleprompter for Video, OnTake, Captions (timer) |
| E5 | **Seções do roteiro como marcadores**: ler a linha em CAIXA ALTA como título (não falada, esmaecida ou pulada), pular para a seção, voltar ao início da seção para refazer o take | Teleprompter Pro: cue points. QPrompt: marcadores. PromptSmart: texto marcado é pulado. Captions: cena a cena e desfazer o último segmento. Dor 5 (BIGVU pula ao retomar de um ponto, 01/05/2026) |
| E6 | **Gravar em formato fixo**: 4K 30 fps, frontal, HDR desligado, trava de exposição e foco por toque longo | Teleprompter for Video, Video Teleprompter, PromptSmart (AE/AF lock). Dor 11 (HDR "washed out"). Guia do Cauê |
| E7 | **Salvar o arquivo original na galeria ao parar**, sem reprocessar | Teleprompter ("Save recorded videos directly to Photos"). Dor 6 (BIGVU 26/03/2026) e dor 10 (BIGVU 25/06/2026 ficou pixelado após edição do app) |
| E8 | **Áudio garantido**: verificar que o arquivo tem áudio antes de dizer "salvo"; aceitar microfone externo e Bluetooth (DJI) | Dor 7 (BIGVU 19/03/2026 sem áudio; Teleprompter for Video 09/02/2026) e dor 2 (DJI) |
| E9 | **Indicador de gravação inconfundível** (vermelho, tempo grande) e botão de pausa gigante por toque | Dor 11 (Teleprompter 17/07/2026) |
| E10 | **Tela sempre acesa** e retomada limpa se o app for interrompido (ligação, notificação) | Martinho (release: "the screen no longer goes dark while you read"); Teleprompter corrigiu erro de segundo plano em 06/10/2026 |
| E11 | **Texto legível**: contraste alto, fonte e tamanho livres, fundo sólido | Dor 11 (Teleprompter 12/08/2026) |

### Diferencial

| # | Item | Evidência |
|---|---|---|
| D1 | **Seções detectadas automaticamente** a partir das linhas em CAIXA ALTA ao colar, sem digitar marcador | Nenhum app lido faz isso (n/e); QPrompt exige marcador manual (Ctrl+M). Próximo: Captions (cena a cena) e PromptSmart (tags) |
| D2 | **Duração-alvo por peça**: "este Reel tem 45 s", e o app calcula a velocidade; mostra tempo estimado por seção | Teleprompter Pro: Timed Scrolling e tempo restante. Serve para o formato 30 a 60 s dele |
| D3 | **Velocidade por seção** (ABERTURA mais rápida, FECHO mais lento) | Pedido em avaliação: "setting rate of speed at different points" (Teleprompter, 3★, 31/07/2026) |
| D4 | **Take por seção**: gravar, errar e refazer só a seção, mantendo o que deu certo | OnTake (pausar e retomar, "star takes"); Captions (desfazer último segmento). Cuidado com a dor 5 (retomar tem que cair no lugar certo) |
| D5 | **Voz como modo opcional, conservador**: nunca avança sozinho além do que ouviu; em dúvida, para e espera. O toque reposiciona | PromptSmart prova a demanda (elogios de 05/2026 e 08/2026) e a patente (seção 5) descreve "para até a próxima hipótese". Mas 125 de 335 ruins reclamam. Só entrar depois do modo manual estável |
| D6 | Grade de terços e zoom/largura da câmera frontal | Teleprompter for Video (grade 3x3, pinça); Martinho (grade). Dor 12 |
| D7 | Botão de volume para iniciar e pausar (mãos ocupadas, apoio de mesa) | PromptSmart (volume play e pause), Edits (pedido de gatilho Bluetooth, 13/09/2026) |
| D8 | Linha-guia de leitura e esmaecer o que já foi lido | Teleprompter (guia de leitura em seta ou linha); QPrompt (read region com barras) |
| D9 | Escolha explícita de **espelhar ou não** o arquivo salvo da câmera frontal | Dor 11 (Teleprompter 24/09/2026: preview diferente do arquivo) |

Nota de segurança sobre "às vezes no carro": nenhum app lido trata de gravar dirigindo. Recomendo o app assumir uso **estacionado** (por exemplo, bloquear a gravação com o carro em movimento é decisão de produto a tomar, n/e na concorrência).

### Não fazer

| # | Item | Dor ou fonte |
|---|---|---|
| N1 | Assinatura, paywall, conta, limite de tempo ou de caracteres, marca d'água | Dor 1; Teleprompter for Video (750 caracteres; logo na gravação, 17/08/2026); BIGVU (corte em 9 min); Martinho (grátis só 10 s) |
| N2 | Pop-up de upgrade, tela de marketing, IA no meio do fluxo | Dor 1 (Teleprompter 17/08/2026 "Popup"; BIGVU 13/04/2026) e dor 10 |
| N3 | Editor de vídeo, legenda, avatar, tela verde, correção de olhar | Dor 10. Ele edita no Motor; a legenda do guia dele é outra |
| N4 | Reprocessar ou recomprimir o vídeo | Dor 10 (BIGVU pixelado) |
| N5 | Nuvem própria como casa dos vídeos ou projetos | Dor 6 (BIGVU) |
| N6 | Voz como único modo, ou voz que pula adiante | Dor 2 |
| N7 | Layout que muda sozinho entre versões | BIGVU 09/09/2026 ("suddenly the app layout looks completely different and every single one of my recordings are deleted"); Teleprompter for Video 15/04/2025 ("forces a zoom-out just to start the scroll") |
| N8 | Recursos de estúdio: espelho para vidro, HDMI e AirPlay, Apple Watch, pedal, gamepad, controle por navegador | Servem à concorrência de rig profissional (Teleprompter Pro); ele grava no celular. Espelho vira só opção escondida, se algum dia precisar |
| N9 | Cor e decoração (a identidade dele é quase sem cor) | Martinho usa "Obsidian Neon" (neon sobre preto): é o oposto do que ele pediu |

---

## 5. Detalhes técnicos úteis

### 5.1 QPrompt: como calcula a velocidade

Fonte: `src/prompter/Prompter.qml` e `src/kirigami_ui/EditorToolbar.qml` do commit `5fd7eb2` (14/10/2026). Os nomes abaixo são os do código.

- A velocidade é uma função de um número inteiro de **passos** `__i` (padrão 3, `__iDefault`; seta para cima e para baixo soma ou subtrai 1; as teclas 0 a 9 definem o passo direto):
  `__speed = __baseSpeed * |__i| ^ __curvature`.
- `__baseSpeed` é o slider dividido por 100: de 0,10 a 5,00, passo 0,05, **padrão 1,00**. `__curvature` é o slider da aceleração dividido por 100: de 0,50 a 2,00, **padrão 1,15**. Com curva acima de 1, cada passo extra acelera mais que o anterior.
- Velocidade relativa à tela e à fonte (comentário do código: "Adjust relative to viewport widths and font size"):
  `__relativeSpeed = __speed * fontSize/2 * ((__vw - __evw/2) / __vw)`, onde `__vw` é um centésimo da largura do prompter e `__evw` um centésimo da largura do editor.
- **Não rola quadro a quadro.** Calcula o tempo para chegar ao fim e dispara **uma animação linear única**:
  `__timeToEnd (s) = 2 * (editor.height + fontSize - __travelDistance) / __relativeSpeed`, e `timeToArival = timeToEnd * 1000` ms. A posição (`contentY`) tem um `Behavior` com `NumberAnimation { duration: timeToArival; easing: Linear }` rumo ao destino (fim, ou topo se a velocidade for negativa). Mudar o passo recalcula o tempo e reinicia a animação do ponto onde está.
- Limite: `__speedLimit = __vw * 100`. Há uma "margem de tremor" (`__jitterMargin`) para o fim e o início não oscilarem.
- No fim: três ações, `Stop`, `Exit` ou `Loop` (com espera de 3 s, `atEndLoopDelay`). Ao terminar a animação, o passo volta a 0.
- **Marcadores** (`marker.hpp`, `markersmodel.*`): cada marcador guarda posição e comprimento no texto, texto, tecla, URL e tipo de pedido. Há marcador comum (Ctrl+M) e nomeado (Ctrl+Shift+M); Ctrl+PageUp e Ctrl+PageDown pulam entre eles. Quando o marcador passa pela faixa de leitura, uma URL `obs://scene/...` troca de cena no OBS por websocket e `sys://` roda um comando.
- **Leitura minha, não documentada pelo autor:** como a distância percorrida cresce com o tamanho da fonte e a velocidade também é multiplicada por ele, o tempo de leitura fica quase independente do tamanho da fonte. Ou seja, o parâmetro é "linhas por segundo", não pixels.

Para o app (sugestão minha): medir a altura do conteúdo `H` e contar as palavras `W`; velocidade em pixels por segundo = `H * wpm / (W * 60)`. Assim a velocidade em palavras por minuto vale para qualquer tamanho de fonte, e "duração alvo" vira `H / segundos`. Usar relógio de quadro (`CADisplayLink` ou `TimelineView`) com delta de tempo, para pausar e mudar a velocidade sem salto.

### 5.2 Imaginary Teleprompter

Fonte: `js/teleprompter.js`, `index.html` (commit `890316b`, 02/01/2021), mesmo autor do QPrompt.

- `velocity = speed * |x| ^ acceleration * (x>=0 ? 1 : -1)`, com `x` o passo inteiro. Sliders: velocidade de 1 a 20 (padrão 4,0 no HTML) e aceleração de 0,5 a 1,8 (padrão 1,45 no HTML). No `editor.js` há também um JSON de padrão com 13 e 1,2; não resolvi qual vale.
- Unidade relativa: `unit = focusHeight/80`; o tempo em milissegundos para chegar ao destino é `|dest - curr| * 1000 / (velocity * unit)`; o movimento é uma `transition: transform ...ms linear` em CSS. O texto afirma que "speed and contents remain consistent from your smallest screen up to 4k". Limite interno `limit = 2600`.
- Mesma ideia do QPrompt: um único movimento linear até o fim, recalculado a cada mudança de passo.

### 5.3 PromptSmart VoiceTrack: improviso e pulo de frase

O que está documentado:

- **Fala fora do roteiro.** App Store: "If you go off-script, VoiceTrack knows and will hold your place, waiting for you to return." PromptSmart+: "stops when you pause or improvise. PromptSmart will wait for you to begin speaking the script again before it continues moving." Site (promptsmart.com): "stops when you pause or improvise, and seamlessly resumes when you return to your script."
- **Pular frase.** n/e no material do fabricante. A patente do mesmo titular ([US 9.953.646](https://patents.google.com/patent/US9953646B2/en), Belleau Technologies; li só os primeiros 100 mil de 307 mil caracteres e não confirmei se é exatamente o que roda hoje) descreve: o reconhecedor gera hipóteses sobrepostas; cada hipótese perde as palavras já casadas; o casador procura numa **janela das próximas 20 palavras** do roteiro; pontua por distância de cosseno (limite "at least 3.0") e, com vários candidatos, manda os **3 melhores** a uma checagem por N-grama (ordem das palavras); ignora "the 70 of the most common articles"; hipótese mínima de 3 ou 4 palavras (o texto diz as duas coisas). **Sem casamento, "processing stops until the next hypothesis is received"**, ou seja, o texto fica parado. O que o usuário disser que não corresponde ao texto é descartado. Inferência minha, não escrita na patente: um pulo maior que a janela de 20 palavras não casaria e o texto ficaria parado; o que a patente descreve para pular é o gesto de arrastar a tela, e o rastreio recomeça dali.
- **Velocidade com voz.** Na patente, o ponto casado deve ficar no centro da tela: se o centro está atrás do falante, acelera, e quanto mais atrás, mais acelera; se está à frente, desacelera até parar. O que isso mostra: a rolagem é uma correção contínua, não um salto.
- **Modo sem voz.** Velocidade fixa de 70 a 400 wpm, "continuous, pre-set speed" (promptsmart.com/how-it-works). Texto marcado com tag ("headers or directions") é pulado.
- **Limites publicados (Pro):** só inglês; até 5.000 palavras; uso contínuo de ~30 min "not a strict cap"; microfone com fio recomendado. PromptSmart+ lista 15 idiomas, incluindo português (V). Tudo no aparelho, sem internet.
- **O que as avaliações descrevem do comportamento real:** parar no meio da frase e não voltar (22/05/2025); avançar rápido demais e perder trecho (08/12/2020); degradar em roteiro longo (09/08/2025). Dica de usuário de 2020: remover formatação, modo avião, microfone externo.
- Outros projetos abertos citados em busca: [autocue](https://github.com/EdNutting/autocue) (MIT) usa Vosk ou Sherpa-ONNX com blocos de 100 ms e `rapidfuzz` para tolerar erro de reconhecimento, e detecta retorno ao início da frase (backtrack). Nenhum limiar documentado.

### 5.4 O que o Edits faz de diferente

Fontes: [tutorial oficial](https://edits.instagram.com/tutorials/teleprompter/), Social Media Today ([jun/2025](https://www.socialmediatoday.com/news/instagram-edits-video-app-teleprompter-overlays-update/750386) e [maio/2026](https://www.socialmediatoday.com/news/instagram-introduces-teleprompter-tool/821564/)), [ALM Corp (T)](https://almcorp.com/?p=81013).

- **O roteiro nasce no mesmo app que edita.** Ele não é só prompter: a nota adesiva da aba Ideas vira roteiro ("Stickies-to-Teleprompter", via menu). Hoje o mesmo prompter está na câmera de Reels do Instagram, onde o vídeo cai direto no rascunho do Reel (T).
- **A janela é arrastável** e some do enquadramento; o app não impõe onde o texto fica. O texto nasce logo abaixo da câmera frontal (Social Media Today).
- **Controles mínimos:** tamanho e velocidade; sem voz, contagem ou espelho nas fontes lidas. Ajustar durante a gravação: n/e; a fonte de terceiro diz que só pausado.
- **Saída:** projeto do Edits com botão Exportar; no Reels, o rascunho. Não é "cai na galeria".
- **Fraquezas medidas pelas avaliações:** editor de texto do roteiro ruim (parágrafo desfeito, cursor pula, 17/07/2026); câmera frontal quebrada em iPhone novo (19/09 e 22/09/2026); projetos que somem (06/06/2026); gatilho remoto que passa a mexer no volume (15/06/2026); falta de alinhamento (24/07/2026).
- **O que copiar:** janela solta e leve, sem configuração obrigatória. **O que não copiar:** o roteiro preso a um projeto de edição.

### 5.5 Outros achados técnicos

- **Teleprompter (Teleprompter Apps):** "Scroll up to 120Hz on ProMotion devices"; tempo decorrido e restante calculado "based on scroll speed"; versão 3.85.0 de 06/10/2026 corrigiu gravação com o app em segundo plano.
- **Captions:** timer 15, 30, 60 ou 90, HD/4K, 30/60 fps, "undo the last segment" ([ajuda](https://captions.ai/help/docs/project/camera)).
- **BIGVU:** fluxo em 9 passos ("Read & Record": definir câmera e microfone, ajustar o visor do prompter, filtros de beleza, gravar, parar/refazer/revisar) no [tutorial](https://bigvu.tv/tutorials/pt/teleprompter/); o detalhe de cada ajuste não está nessa página (n/e).
- **Lacunas desta pesquisa:** não instalei os apps; BIGVU, PromptSmart e Captions têm preços que mudam por região e por SKU; a Central de Ajuda do BIGVU redireciona para o tutorial e perdi os artigos de configuração; o preço do CapCut e do OnTake não está nas fontes lidas; a patente foi lida só em parte.
