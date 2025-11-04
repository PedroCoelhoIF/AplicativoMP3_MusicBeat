# Music Beat 🎵
Music Beat é um player de música para Android e iOS desenvolvido em Flutter. O aplicativo carrega uma playlist de músicas a partir de uma API, permitindo ao usuário ouvi-las com um sistema de streaming progressivo e cache local.

![Demonstração APP MusicBeat](https://github.com/PedroCoelhoIF/AplicativoMP3_MusicBeat/blob/main/assets/demo/demo-app-appmp3-musicbeat.gif?raw=true)

## Sobre o Projeto:
O projeto foi construído com foco em eficiência e uma experiência de usuário fluida, implementando as seguintes funcionalidades:
  - Carregamento de Playlist via API: Busca uma lista de músicas de um endpoint JSON remoto (api_service.dart).
  - Streaming Progressivo de Áudio: O player não espera o download completo. Ele começa a tocar a música assim que um buffer inicial (15%) é baixado, continuando o download em segundo plano (download_service.dart, music_viewmodel.dart).
  - Cache Local (Offline): As músicas baixadas são salvas no armazenamento local do dispositivo. Em acessos futuros, o app toca o arquivo local instantaneamente, economizando dados e tempo de carregamento.
  - Gerenciamento de Estado: Utiliza o Provider para um gerenciamento de estado reativo, atualizando a UI (lista de músicas, mini-player, ícones de play/pause) em tempo real conforme o estado da música (tocando, pausada, baixando, bufferizando, erro).
  - Controles de Reprodução Avançados: Inclui controles de Shuffle (aleatório), Repeat One (repetir uma) e Repeat All (repetir todas).
  - Easter Egg de Geolocalização: Uma funcionalidade especial e secreta! O app verifica a localização do usuário e, se ele estiver dentro de um raio de 50 metros de coordenadas específicas (Campus), uma música bônus ("Os Bilias") é desbloqueada e adicionada ao topo da         playlist (location_service.dart).
  - Tratamento de Permissões: O app solicita proativamente as permissões necessárias (Armazenamento, Localização, Notificação, Áudio) em uma tela de inicialização (main.dart).

## 👥 Equipe:
  - Pedro
  - [Marcos] (https://github.com/dipardi) - Parte do Easter Egg
  - [Bruno] (https://github.com/andrestads) - Parte da UI

## 🛠️ Como Executar o Projeto:
Para baixar e executar este projeto localmente, siga os passos abaixo.
  1. Clone o repositório ou baixe.
  2. Instale as dependências (flutter pub get)
  3. Escolha o emulador, rode o arquivo main.dart(F5 ou flutter run no terminal)

## 🤝 Contribuindo:
Contribuições são bem-vindas! Sinta-se à vontade para:
 - Fazer um fork do projeto
 - Criar uma branch para sua feature (git checkout -b feature/NovaFeature)
 - Commitar suas mudanças (git commit -m 'Nova Funcionalidade')
 - Push para a branch (git push origin feature/NovaFeature)
 - Abrir um Pull Request
