# Correção do ciclo de vida do player Windows

Base: video_player_win 3.3.1, https://github.com/jakky1/video_player_win (licença MIT preservada em LICENSE).

Esta cópia local mantém a API Flutter e o Media Foundation. Não editar o cache global do Pub.

Alterações locais:
- A textura Flutter, seu descritor e o recurso D3D permanecem vivos até o callback de UnregisterTexture. O Future de dispose só termina após essa confirmação; não usa atraso fixo.
- Eventos Media Foundation são encaminhados para uma janela de mensagens da thread de plataforma. O callback nativo não espera pelo mutex de renderização nem envia respostas Flutter de outra thread.
- Shutdown interrompe produção de quadros e rompe referências COM explicitamente, sem Release extra. O worker recebe sua referência antes de iniciar. O recurso gráfico não é liberado enquanto o rasterizador ainda o usa.
- A resposta de abertura é enviada uma única vez; CANPLAY repetido não chama callback vazio. Vídeo inválido gera erro no stream em vez de inicialização com duração nula.
- Duração nativa ausente: tenta metadados de apresentação/intervalos de busca. Para MP4 local fragmentado ainda com duração zero, fragmented_mp4_duration.dart calcula o tempo a partir de mdhd/tfdt/tfhd/trex/trun. Lê somente metadados e pula mdat. Não transcodifica nem modifica o vídeo. Metadados truncados/fora dos limites não recebem duração inventada.

platform_thread.hpp foi adaptado do dispatcher MIT de just_audio_windows_plus (PLATFORM_DISPATCHER_LICENSE). A classe e a janela têm nomes próprios para não colidir com o plugin de áudio.

Validação automatizada no app: test/fragmented_mp4_duration_test.dart, test/media_initialization_test.dart e integration_test/windows_player_lifecycle_test.dart. A atualização deste pacote exige reaplicar/reavaliar o patch e executar os testes nativos. O fallback de duração é limitado aos tempos de decodificação dos fragmentos; não é um demuxer completo e não interpreta listas de edição complexas.
