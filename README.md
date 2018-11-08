## Plataformas
- Android
- iOS


## Modo de Usar
**Usando o Cordova Plugin do Docway Video**

1. Adicione ao projeto
    - `ionic cordova plugin add cordova-plugin-docway-video`
    - `npm install --save cordova-plugin-docway-video`
  
2. Implemente o seguinte código
	- Declare a variavel do cordova
	declare var cordova;

    - Gere o token e chame a API
    `cordova.docway.video.open(RoomName: string, Token: string, RemoteParticipantName: string);`

	
## Créditos
  Este plugin foi desenvolvido usando o plugin [cordova-plugin-twilio-video-v2preview] (https://github.com/Anvay666/cordova-plugin-twilio-video-v2preview)
