# See2Sound — reprodução intermitente no Windows

Data: 26/10/2026. Backend e contratos da API preservados.

## Diagnóstico e evidências

1. **Alta — MP4 fragmentado com duração zero.** No teste anterior à correção, o plugin entregou vídeo inicializado com duração `00:00:00`, enquanto a posição nativa avançou para cerca de 904 ms. O Flutter passou a indicar conclusão e a audiodescrição foi pausada. Há evidência em `validation/windows-player-lifecycle-baseline.log`. Uma cópia estável de `11908139_1920_1080_25fps.mp4` também possui `mvhd` e `mdhd` com duração zero; os tempos dos fragmentos recuperam duração de **19,2 segundos**. Arquivos fragmentados não são necessariamente inválidos por terem esses campos zerados.
2. **Alta — vida útil da textura e dos recursos gráficos.** O plugin removia a textura de forma assíncrona e liberava o objeto/descritor antes de receber confirmação do rasterizador. O `TextureVariant` alocado também não tinha proprietário. A thread de quadros podia acessar recursos de mídia durante a liberação. O Windows registrou exceções `0xc0000005` e `0xc000041d` em `flutter_windows.dll` para instâncias anteriores do app. Essas evidências são compatíveis com acesso a recursos liberados; sem um dump não é possível atribuir cada encerramento a uma linha específica.
3. **Alta — callbacks e encerramento nativos.** A abertura respondia a canais Flutter a partir de callbacks Media Foundation, havia callback de carga chamado sem proteção contra CANPLAY repetido e caminho de erro que poderia reutilizar um `MethodResult` já movido. A liberação usava atraso fixo de 100 ms em vez da conclusão real.
4. **Média — erro de arquivo apresentado como inicialização.** Um vídeo inválido podia gerar evento `initialized` com duração nula, fazendo o controller parecer disponível sem conseguir reproduzir.

As mensagens “Este áudio também é usado por outro registro” do anexo pertencem à proteção da biblioteca contra apagar arquivos compartilhados. Não constituem evidência de falha do player e essa regra não foi removida.

## Correções

- `third_party/video_player_win/`: cópia local do **video_player_win 3.3.1**, com a mesma API, registro Windows e Media Foundation. Não foi editado o cache global do Pub nem adicionado um segundo plugin concorrente.
- Retenção de `TextureVariant`, descritor, player e textura D3D até o callback de `UnregisterTexture`. O Future de dispose termina após a confirmação real.
- Eventos Media Foundation enfileirados em janela própria da thread de plataforma, sem esperar pelo mutex de renderização dentro do callback do Media Foundation. Respostas de canais e limpeza de falhas são executadas na thread correta.
- Referência do worker reservada antes de iniciar a thread. Shutdown idempotente, referências COM encerradas explicitamente e proteção contra usar engine/textura já liberados. Não mantém Release manual sem referência correspondente.
- Duração: usa primeiro os dados do Windows; se permanecer zero em MP4 local fragmentado, `fragmented_mp4_duration.dart` lê `mdhd`, `tfdt`, `tfhd`, `trex` e `trun` para calcular o tempo dos fragmentos. Pula os blocos `mdat`, não carrega todo o vídeo na memória e não altera/transcodifica o arquivo.
- Metadados truncados, escalas zero e tamanhos inválidos são rejeitados. Não se atribui duração fictícia a um arquivo não interpretável.
- Arquivo inválido gera erro no stream do plugin, permitindo erro acessível e tentativa novamente.
- `lib/features/player/synchronized_media_controller.dart`: rejeita duração inválida, desabilita reprodução após falha, impede comandos tardios e oferece `close()` aguardável.
- `lib/features/player/player_page.dart`: ao substituir/tentar novamente, aguarda liberação do controller anterior antes de carregar o próximo.
- Preservados reprodução, pausa, seek, velocidade, volume, correção de drift, áudio original silenciado e o viewport externo 16:9 com barras pretas.

## Validação executada

| Verificação | Resultado |
| --- | --- |
| `dart format` nos arquivos alterados | Concluído |
| `flutter analyze` | Sem problemas |
| `flutter test --reporter expanded` | **84 aprovados; 3 de backend ignorados** por serem opt-in |
| `integration_test/windows_player_lifecycle_test.dart -d windows` | **4 aprovados** |
| Abrir/reproduzir/pausar/seek/fechar repetidamente com textura visível | **20 ciclos completos**, vídeo e áudio avançando |
| Fechar durante inicialização e abrir novamente | **5 cancelamentos** e reprodução posterior aprovados |
| Vídeo inválido seguido por vídeo válido | Erro tratado; processo preservado e próximo vídeo reproduzido |
| Vídeos adicionais reais 3840×2160 e 2160×3840 | Inicialização, reprodução, pausa, seek e descarte aprovados |
| `integration_test/windows_player_test.dart -d windows` | **3 aprovados** |
| WAV real em caminho com acentos, espaços, `#` e `%` | Carregado e reproduzido |
| Play/pause, seek, velocidade 1,25×, volume 0,4, correção de drift, fim/replay e troca | Aprovados com plugins reais; volume original do vídeo zero |
| `flutter build windows` | **Aprovado — Release gerado** |

Os testes Windows foram executados em checkout temporário isolado para não substituir o executável Debug de instâncias abertas pelo usuário. Usaram cópias de arquivos reais locais, sem modificar os originais, e os plugins nativos. Os arquivos UHD/retrato foram testados como vídeo; o par horizontal e WAV foi usado na repetição sincronizada. A suíte de controles usou o WAV real de 14,74 segundos já validado anteriormente. Não foi necessário acionar o backend novamente.

Arquivos de evidência: `validation/windows-player-lifecycle-native.log`, `validation/windows-player-lifecycle-controls.log`, `validation/windows-player-lifecycle-unit.log`, `validation/windows-player-lifecycle-analyze.log` e `validation/windows-player-lifecycle-build.log`.

Reexecução dos testes nativos:

```powershell
flutter test integration_test/windows_player_lifecycle_test.dart -d windows --dart-define=SEE2SOUND_NATIVE_VIDEO="CAMINHO_ABSOLUTO_VIDEO" --dart-define=SEE2SOUND_NATIVE_AUDIO="CAMINHO_ABSOLUTO_WAV" --dart-define=SEE2SOUND_NATIVE_EXTRA_VIDEOS="CAMINHO_UHD;CAMINHO_RETRATO"
flutter test integration_test/windows_player_test.dart -d windows --dart-define=SEE2SOUND_NATIVE_VIDEO="CAMINHO_VIDEO_14S" --dart-define=SEE2SOUND_NATIVE_AUDIO="CAMINHO_WAV_14S"
```

As definições precisam apontar para arquivos reais. O teste de controles espera WAV com mais de 14 segundos e um vídeo correspondente. Os testes não usam os textos acima como dados de reprodução.

## Limites e verificações manuais remanescentes

- O teste prolongado é finito; não comprova ausência absoluta de falhas em todos os drivers/GPU ou horas de uso. Revalidar uma sessão longa no computador da apresentação com o executável novo.
- Conferir perceptualmente o conteúdo narrado, alto-falantes/fones, leitores Narrador/NVDA e recuperação após suspensão/troca do dispositivo de áudio.
- O fallback de duração interpreta tempos de decodificação dos fragmentos, não é um demuxer completo e não resolve listas de edição complexas. Arquivos que não possam ser interpretados continuam apresentando erro amigável.
- Outros sistemas operacionais e codecs externos não foram compilados/testados nesta correção.
- O plugin contém patch local; atualizações futuras exigem reavaliar/aplicar as alterações e repetir os testes nativos. Licenças MIT e atribuições preservadas.
- Fechar a instância antiga e abrir o novo executável. Hot reload/hot restart não substitui uma DLL nativa já carregada.

## Referências técnicas

- [Código e documentação do plugin original](https://github.com/jakky1/video_player_win).
- [Microsoft: IMFMediaEngine::GetDuration](https://learn.microsoft.com/en-us/windows/win32/api/mfmediaengine/nf-mfmediaengine-imfmediaengine-getduration).
- [Microsoft: MF_PD_DURATION](https://learn.microsoft.com/en-us/windows/win32/medfound/mf-pd-duration-attribute).
- [W3C: estrutura de segmentos ISO BMFF](https://www.w3.org/TR/mse-byte-stream-format-isobmff/).
- Contrato `TextureRegistrar::UnregisterTexture(texture_id, callback)` do SDK Flutter instalado: o callback indica conclusão da remoção assíncrona.
