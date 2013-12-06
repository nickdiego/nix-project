:JS
:AudioContext
:DefaultAudioDestinationNode
:AudioDestination
:"Nix::AudioDevice"
:MediaStreamAudioSourceNode
:WebKitWebAudioSource

:JS AudioContext.createMediaStreamSource(stream) {

  AudioContext.lazyInitialize() {

    DefaultAudioDestinationNode.startRendering() {
      AudioDestination.start() {
        "Nix::AudioDevice".start() {
          WebKitWebAudioSource.set_state(PLAYING) {
          }
        }
      }
    }
  }
      
  MediaStreamAudioSourceNode.create()
  loop(rendering loop) {
    DefaultAudioDestinationNode.render(...)
  }
}

