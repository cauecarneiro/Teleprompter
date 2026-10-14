# Teleprompter

App de iPhone para gravar lendo o roteiro: cola o texto do Notion, aperta gravar, e o vídeo cai na galeria.
Preto, branco e um vermelho só, o do botão de gravar. Sem conta, sem internet, sem assinatura.

## Como instalar no iPhone

1. Ligue o iPhone no Mac pelo cabo e desbloqueie.
2. Abra `Teleprompter.xcodeproj` no Xcode.
3. No alto da janela, escolha o seu iPhone como destino.
4. Aperte ▶ (Run). Na primeira vez o iPhone pede para confiar no desenvolvedor:
   Ajustes > Geral > VPN e Gerenciamento de Dispositivos > o seu nome > Confiar.
5. Se o Xcode reclamar de assinatura, abra o alvo Teleprompter > Signing & Capabilities e escolha a sua equipe.

Se mexer na lista de arquivos, gere o projeto de novo com `xcodegen generate`.

## Como usar

1. No Notion, copie o bloco "Teleprompter" do roteiro.
2. Abra o app e toque em **Colar e gravar**. A tela de gravação abre direto.
3. Aperte o botão vermelho. Conta 3, 2, 1, grava, e o texto começa a rolar.
4. Aperte de novo para parar. O vídeo vai para a galeria, no álbum "Teleprompter".

Dica: em Ajustes > Teleprompter > Colar de Outros Apps, escolha **Permitir**. Assim o iPhone para de perguntar a cada colagem.

## O que ele faz

**Roteiro**
- Linhas em CAIXA ALTA ("ABERTURA UM", "CORPO") viram seções, com atalho na tela de gravação.
- O que está entre parênteses ("olhe para a lente") aparece em cinza e itálico e não conta na leitura.
- O editor mostra o tempo de cada seção e acerta a velocidade para caber em 30, 45, 60 ou 90 s.
  A conta usa uma abertura e um fecho só, porque os outros são versões.
- Cada seção ganha um ✓ quando tem take gravado.

**Leitura**
- Três modos: **Automático** (velocidade fixa em palavras por minuto), **Voz** (o texto anda quando você fala
  e para quando você improvisa) e **Manual** (só o dedo). A voz segue texto palavra por palavra; no corpo em
  tópicos, onde você fala livre, use o Automático ou o Manual.
- O texto fica no alto, colado à câmera frontal, para o olhar não fugir da lente.
- O que já foi lido apaga; a linha de leitura tem um marcador.
- Toque no texto pausa e retoma. Arrastar reposiciona. Pinça muda o tamanho da letra.
- A velocidade fica guardada entre os takes. O tempo que falta aparece ao lado.

**Gravação**
- Vertical, 4K ou 1080p, 24, 30 ou 60 fps, HDR desligado, sem filtro: o que a cola de gravação pede.
- Toque na imagem foca; segure para travar foco e exposição.
- Botões de volume e Controle da Câmera gravam e param. Teclado ou controle Bluetooth também:
  espaço pausa, Enter grava, setas mexem a linha e a velocidade.
- Microfone externo (DJI pelo USB-C, Bluetooth) aparece nos ajustes.
- O arquivo vai original para a galeria, sem recompressão. Se sair sem áudio, o app avisa.
- **Refazer** depois de um take volta para o começo da seção.
- Grade de terços e zona segura do Reels, opcional.
- A tela não apaga enquanto grava. Se uma ligação interromper, o take é salvo.

## O que ficou de fora, de propósito

Editor de vídeo, legenda, IA, nuvem, conta e marca d'água. Tudo isso gera reclamação nos concorrentes
(`docs/benchmark.md`) e a edição já acontece no Motor.

Ficou para depois: velocidade diferente por seção.

## Estrutura

| Pasta | O que tem |
|---|---|
| `Core/` | Pacote Swift testável: leitura do roteiro, tempo de leitura e acompanhamento por voz (`swift test`) |
| `App/Camera/` | Câmera, gravação com AVAssetWriter e envio para a galeria |
| `App/Speech/` | Reconhecimento de voz em português |
| `App/Prompter/` | O texto que rola (UIKit, 120 Hz) |
| `App/Views/` | Telas: início, editor, gravação e ajustes |
| `docs/` | Benchmark de 10 apps e o livro-razão de engenharia reversa |
| `scripts/gerar-icone.swift` | Gera o ícone |

## Testes

- `cd Core && swift test`: 18 testes, todos passando em 14/10/2026. Um deles usa o bloco real do Vídeo 20.
- O app compila sem erro nem aviso para o simulador e para o iPhone (Release, assinado).
- Câmera, voz e galeria só dá para testar no iPhone.

Na versão de teste (Debug), os argumentos `-demo -demoRecorder -demoPlay` abrem um roteiro de exemplo já rolando,
para capturar telas no simulador. Isso não existe na versão final.
