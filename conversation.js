var conversations = {
  open: function(callTo, token, remoteParticipantName, connectionMessage, succ, fail) {
    cordova.exec(
      succ || function(){},
      fail || function(){},
      'VideoConversationPlugin',
      'open',
      [callTo, token, remoteParticipantName, connectionMessage]
    );
  }
};

module.exports = conversations;