# Correção do player Windows - See2Sound

Data: 24/10/2026. Backend e contratos HTTP não foram modificados.

## Resultado

O problema foi reproduzido com reprodução Windows real e corrigido na implementação nativa. Os três testes nativos passaram usando o vídeo original e o WAV gerado pelo backend, em um caminho com espaços, acentos, `#` e `%`. A suíte isolada teve 76 testes aprovados (3 testes HTTP reais optativos ignorados). O executável Windows Release foi gerado. A análise estática final também passou sem problemas. Os resultados estão registrados nas evidências desta auditoria.

## Diagnóstico comprovado

1. O WAV de teste foi obtido do job concluído `3e337c58bc354792aed1efdd344c0128`, sem reprocessar nem modificar o backend. Possui 2.600.180 bytes, PCM de 16 bits, estéreo, 44.100 Hz e duração de 14,740 segundos. SHA-256: `74c849ed21b406fc1c2064c5e19b271247d0d406df994ddfd8cd1c97bd65eed6`. O arquivo é legível e foi decodificado como WAV. A cópia para um diretório de fixture foi feita exclusivamente pelo teste; o aplicativo não copia ou renomeia arquivos para reproduzir.
2. Com `just_audio_windows 0.2.3`, o teste Windows real ficou pendente em `AudioPlayer.setFilePath()` até o timeout de 12 segundos. O código nativo antigo chama o event sink diretamente em callbacks WinRT e retorna de `load` antes da confirmação de abertura. Os avisos de thread são coerentes com essa implementação e com o relato público do pacote.
3. O substituto publicado `just_audio_windows_plus 0.5.5` resolveu a resposta pendente em caso de erro, mas ainda falhou com o caminho Unicode. O MESMO WAV foi reproduzido por ele em um caminho ASCII. Logo, nesse cenário o erro não era corrupção do WAV.
4. O diagnóstico nativo mostrou o caminho corrompido: `reproduÃ§Ã£o` em vez de `reprodução`. O parser de URI WinRT processava os escapes antes de uma conversão correta de UTF-8 para UTF-16. A decodificação precisa acontecer antes de construir a Uri nativa de um WAV local.
5. A correção foi validada em uma cópia isolada dos mesmos fontes porque o executável Debug do projeto estava em uso por uma instância aberta antes dos testes. Essa instância não foi encerrada. O executável Release foi compilado no projeto principal.

## Alterações realizadas

### Plugin e dependências

- Removido `just_audio_windows` do pubspec, lockfile e registro nativo gerado.
- Mantido um único plugin de áudio Windows: `just_audio_windows_plus`, baseado na versão 0.5.5, agora uma dependência de caminho em `third_party/just_audio_windows_plus`.
- Essa versão foi verificada no pub.dev e no código instalado. Declara compatibilidade com `just_audio 0.10.6`, usa C++20 e mantém o encaminhamento dos callbacks para a thread de plataforma via dispatcher Win32. É um projeto recente, portanto a mudança foi condicionada aos testes Windows reais; as alegações de documentação não foram tomadas como prova de funcionamento.
- O código MIT e a licença foram preservados. A correção é local, versionada e reproduzível; o cache global do Pub não foi alterado.
- `windows/local_wav_source.hpp` decodifica os escapes do URI Dart em bytes UTF-8 e converte uma única vez para UTF-16. O WAV original é aberto somente para leitura por `CreateRandomAccessStreamOnFile` e entregue ao `MediaSource` por `CreateFromStream`. A URI WinRT defeituosa não é usada para resolver o caminho local WAV. Sem proxy HTTP, nomes ASCII artificiais, arquivos temporários de reprodução ou simulação.
- `windows/player.hpp` utiliza essa abertura para WAVs locais; URLs remotas e outros tipos de fonte continuam com o fluxo upstream. Clipping e playlist continuam usando a mesma criação de item, contrato de canais, dispatcher e ciclo de vida.
- `windows/CMakeLists.txt` do plugin inclui o novo header e a biblioteca de sistema `shcore`. A configuração Windows do aplicativo que já existia foi preservada.
- `integration_test` foi acrescentado apenas às dependências de desenvolvimento para executar os plugins reais no Windows.

### Arquivos e inicialização

- `media_file_validation.dart`: resolve caminhos absolutos e links simbólicos, aceita uma URI de arquivo quando aplicável, abre para leitura e rejeita arquivos ausentes, vazios ou sem acesso. Valida RIFF/WAVE, limites dos chunks, formato, amostragem, canais, bloco e presença de dados sem carregar todo o WAV na memória. Chunks extras, incluindo padding, são aceitos. Arquivos truncados são recusados antes do plugin.
- `synchronized_media_controller.dart`: cria os players somente depois da validação; mantém uma única inicialização em andamento; informa a etapa corrente; limita a inicialização total a 30 segundos e cada carregamento a 12 segundos. Há tratamento independente de erro assíncrono do áudio, mesmo se o Future de load não terminar. Uma resposta tardia não reativa o controller depois de timeout ou descarte.
- Os erros são logados com etapa e causa para diagnóstico, mas o texto exibido é amigável. O cleanup de vídeo e áudio é idempotente, tratado e limitado por timeout. Comandos continuam serializados e limitados a 15 segundos.
- `player_page.dart`: mensagens por etapa, erro como região semântica viva, botão nativo acessível de tentar novamente, troca segura de controller se os arquivos mudarem e ausência de uso de resposta tardia de outro controller. O botão de tentar novamente recria os players reais.

### Sincronização e imagem

Play, pause, seek, reinício, velocidade e volume foram preservados. O vídeo permanece como relógio principal, com correção de drift acima de 250 ms. `play()` do áudio continua sem bloquear a fila, pois seu Future termina na pausa ou no fim. O retorno a partir do fim também considera `isCompleted`. O áudio original do vídeo é sempre silenciado, pois o WAV final contém a mixagem.

O `VideoViewport` externo continua fixo em 16:9, com fundo preto e BoxFit.contain. O estado de erro também usa esse viewport; vídeos verticais preservam a proporção e as barras laterais. Os controles ficam fora do redimensionamento do conteúdo.

## Testes executados

- Regressão nativa com plugin antigo: reprovada por timeout de 12 s em setFilePath.
- Substituto upstream, WAV em caminho Unicode: reprovado por caminho inexistente; o mesmo WAV em caminho ASCII passou.
- Plugin corrigido, Windows Debug: 3 testes aprovados. Carregamento e avanço do áudio real; vídeo/WAV sincronizados com play, pause, seek, volume, velocidade, reinício/fim/replay; drift introduzido deliberadamente e corrigido; descarte e abertura de novo controller; arquivo ausente e WAV incompatível retornando PlayerException sem pendência.
- Suíte isolada: 76 aprovados, 3 testes HTTP reais optativos ignorados. As novas regressões cobrem WAV inválido/truncado, caminhos especiais, inicialização pendente, erro assíncrono de load, descarte durante await, resposta tardia, inicialização compartilhada, controles e erro acessível com tentativa novamente.
- `flutter build windows`: aprovado, gerando `build/windows/x64/runner/Release/see2sound_app.exe`. Ferramenta NuGet já instalada foi acrescentada somente ao PATH do comando quando necessário; não houve mudança global.
- `flutter analyze`: aprovado, sem problemas.
- `dart format`: aplicado somente aos arquivos Dart envolvidos.
- Os testes isolados usam doubles exclusivamente em arquivos de teste para forçar timeout e concorrência. Os testes de integração nativa usam os plugins, o vídeo e o WAV reais. Não há reprodução simulada no aplicativo.

## Repetição dos testes nativos

```powershell
flutter pub get
flutter test integration_test/windows_player_test.dart -d windows --dart-define=SEE2SOUND_NATIVE_AUDIO="CAMINHO-ABSOLUTO-DO-WAV" --dart-define=SEE2SOUND_NATIVE_VIDEO="CAMINHO-ABSOLUTO-DO-VIDEO"
flutter analyze
flutter test
flutter build windows
```

Use um WAV real com mais de 14 segundos e um vídeo correspondente com duração maior que 6 segundos para os checks de posição da amostra atual. As variáveis são dart-defines de teste; não mudam o aplicativo normal. Feche a instância Debug antes de compilar sobre o mesmo executável, ou use um checkout de validação separado.

## Validações manuais pendentes e limites

- Executar o novo Release e selecionar pela interface vídeos reais horizontais, verticais e quadrados, alternando itens da biblioteca repetidamente. A geometria está coberta por widgets; o ensaio visual completo no Release ainda é necessário.
- Ouvir a mixagem em alto-falantes/fones e conferir a qualidade perceptiva da audiodescrição e sua sincronização. Avanço do relógio e drift medidos não substituem uma avaliação auditiva humana.
- Validar Narrador/NVDA, foco, teclas, mensagens de erro e tentativa novamente no aplicativo nativo. A semântica foi testada em widgets.
- Testar clipes longos, interrupções/dispositivos de áudio, suspensão e retomada, rede/UNC e arquivos bloqueados por outro programa. O parser contempla caminhos UNC, mas um compartilhamento de rede real não foi ensaiado.
- Revalidar o patch local ao atualizar o pacote upstream; a integração real com acentos e caracteres reservados deve continuar sendo obrigatória. Evitar registrar novamente o plugin antigo junto do novo.
- Outras plataformas não foram compiladas nesta tarefa. A API Dart e o backend foram preservados.

## Fontes e manutenção

- Versão avaliada: https://pub.dev/packages/just_audio_windows_plus/versions/0.5.5
- Código upstream: https://github.com/OmarAfifi-CSE/just_audio_windows_plus
- Relato de threading do plugin antigo: https://github.com/bdlukaa/just_audio_windows/issues/30
- APIs Windows: https://learn.microsoft.com/en-us/windows/desktop/api/shcore/nf-shcore-createrandomaccessstreamonfile e https://learn.microsoft.com/en-us/uwp/api/windows.media.core.mediasource.createfromstream
- Evidência resumida: `docs/validation/windows-player-fix.json`.
