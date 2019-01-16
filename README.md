## Plataformas
- Android
- iOS


## Modo de Usar
**Usando o Cordova Plugin do Docway Video**

1. Adicione ao projeto
    
	`ionic cordova plugin add cordova-plugin-docway-video`
    
	`npm install --save cordova-plugin-docway-video`
  
2. Implemente o seguinte código
	- Declare a variavel do cordova
	
	`declare var cordova;`

    - Gere o token e chame a API
	
    `cordova.docway.video.open(RoomName: string, Token: string, RemoteParticipantName: string);`


## Distribuição App Store (iOS)

1. Abra o projeto;
2. Vá na aba `Build Phases`;
3. Crie um novo `Run Script Phase`;
4. Nesse novo `Run Script Phase`, Adicione o script: `/bin/bash "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/TwilioVideo.framework/remove_archs"`

	
## Créditos
  Este plugin foi desenvolvido usando o plugin [cordova-plugin-twilio-video-v2preview] (https://github.com/Anvay666/cordova-plugin-twilio-video-v2preview)
