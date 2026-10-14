# Engenharia reversa: o que cada concorrente faz, e o que o app copiou

Método da skill REA (Reverse Engineer Anything, github.com/morluto/rea): cada afirmação diz se é
**observação** (vi na fonte), **inferência** (deduzi) ou **lacuna** (não consegui ver). Montado em 14/10/2026.

## Onde o REA coube e onde não coube

- **Concorrentes:** nenhum binário de concorrente estava no Mac. Apps da App Store chegam criptografados ao
  iPhone e não ficam no Mac, então o REA não teve alvo. Para os apps fechados usei o que é público (App Store,
  sites, avaliações, patente). Para os de código aberto (QPrompt, Imaginary Teleprompter) a regra da própria
  skill é ler o repositório com ferramentas normais, sem REA. A pesquisa completa está em `benchmark.md`.
- **O nosso app:** o REA auditou o binário final que vai para o iPhone (Release, arm64). Resultado abaixo.

## Livro-razão dos concorrentes

| # | Afirmação | Tipo | Fonte | O que o app fez |
|---|---|---|---|---|
| 1 | QPrompt rola com uma animação linear até o fim e recalcula ao mudar a velocidade; a velocidade escala com o tamanho da letra | Observação | `src/prompter/Prompter.qml`, commit 5fd7eb2 | Velocidade em palavras por minuto: pontos por segundo = altura do texto × ppm ÷ (palavras × 60). Muda a letra, o tempo de leitura não muda |
| 2 | O "tempo de leitura quase independente da letra" no QPrompt | Inferência | mesma fonte | Fizemos isso de propósito, com a conta explícita |
| 3 | QPrompt marca seções à mão (Ctrl+M) | Observação | `marker.hpp` | Seções saem sozinhas das linhas em CAIXA ALTA do Notion. Nenhum app lido faz isso |
| 4 | PromptSmart: "se você improvisa, o texto espera" | Observação | App Store e promptsmart.com | O acompanhamento por voz não anda quando o que foi dito não bate com o roteiro |
| 5 | A patente do PromptSmart (US 9.953.646) casa a fala numa janela de 20 palavras e para se nada casar | Observação parcial | patente, lida até 100 mil de 307 mil caracteres | Janela de 30 palavras para trás e 60 para a frente, com alinhamento local (Smith-Waterman). Voltar exige 3 palavras batendo; andar exige 2 |
| 6 | Que o VoiceTrack atual siga a patente | Lacuna | o fabricante não publica | Não depende disso |
| 7 | Na patente, a rolagem por voz é uma correção contínua, não um salto | Observação | patente | A linha lida é puxada com amortecimento, sem pulo |
| 8 | 125 de 335 avaliações ruins do PromptSmart reclamam da voz | Observação, contagem por palavra-chave | App Store | Voz é opcional; o padrão é o Automático |
| 9 | Texto longe da lente é queixa recorrente | Observação | avaliações de 3 apps | Painel de leitura no alto, colado à câmera frontal, com altura e largura ajustáveis |
| 10 | BIGVU e outros: vídeo sem áudio ou recomprimido | Observação | avaliações de 19/03 e 25/06/2026 | O arquivo original vai para a galeria, sem recompressão; o app confere se há áudio antes de dizer "salvo" |
| 11 | Teleprompter Pro tem duração-alvo (Timed Scrolling) | Observação | App Store | "Caber em 30, 45, 60 ou 90 s" no editor, contando uma abertura só |
| 12 | Edits: janela solta, só tamanho e velocidade | Observação | tutorial oficial e Social Media Today | Copiado o "sem configuração obrigatória". Não copiado: roteiro preso a um projeto de edição |
| 13 | Espelhar texto é recurso pago em concorrentes | Observação | App Store | Grátis, como tudo: sem conta, sem assinatura |
| 14 | PromptSmart usa volume para tocar e pausar | Observação | App Store | Volume e Controle da Câmera gravam e param |

## Auditoria do nosso binário com o REA (14/10/2026)

Alvo: `Teleprompter.app` (Release, arm64), SHA-256 `e1cdefe8…7e283f`.

| Pergunta | Resposta | Tipo | Evidência |
|---|---|---|---|
| As cinco permissões têm texto em português? | Sim: câmera, microfone, fotos (adicionar e ler) e reconhecimento de fala | Observação | `ev_2c0fcf60…` (inspect_plist) |
| Funciona em qual iOS? | iOS 18 ou mais novo, só iPhone, só em pé | Observação | `ev_c6863146…` (inspect_macho) e `ev_2c0fcf60…` |
| Está assinado? | Sim, equipe 8B7F7G3Y2U, certificado de desenvolvimento do Cauê | Observação | `ev_d352333c…` (inspect_signature) |
| O modo de demonstração ficou fora da versão final? | Sim: o texto da demo não aparece no binário | Observação (busca de texto, 0 ocorrências) | `strings` no executável |
| O app fala com a internet? | Nenhum endereço http no binário; não usa framework de rede | Observação limitada: ausência de texto não prova ausência de rede | `strings` e lista de frameworks |
| Frameworks ligados | AVFoundation, AVFAudio, CoreMedia, Photos, Speech, SwiftData, SwiftUI, UIKit, _AVKit_SwiftUI | Observação | `ev_c6863146…` e `otool -L` |

## Lacunas que só o iPhone fecha

- Câmera, gravação 4K, áudio e galeria: o simulador não tem câmera de verdade. Nada disso foi testado gravando.
- Reconhecimento de voz em português no aparelho: depende do iPhone e do idioma baixado.
- Botões de volume e Controle da Câmera: só no aparelho.
