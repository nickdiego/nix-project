app       : "Javascript code"
          : NavigatorUserMediaSuccessCallback
navigator : NavigatorMediaStream
controller: UserMediaController
          : "WebCore::Page"
request   : UserMediaRequest
          : MediaStreamCenter
          : "Nix::MediaStreamSourcesQueryClient"
          : "Nix::MediaStreamCenter"
          : MediaStreamSource
          : "Nix::MediaStreamSource"
          : UserMediaClientNix
          : "Nix::UserMediaRequest"
          : "Nix::UserMediaClient"
          : "Nix::MediaStreamTrack"
          : "Nix::MediaStream"
          : LocalMediaStream
          : MediaStreamTrack
          # webaudio stuff
          : AudioContext
          : DefaultAudioDestinationNode
          : AudioDestination
          : "Nix::AudioDevice"
          : MediaStreamAudioSourceNode
          : WebKitWebAudioSource

navigator.getUserMedia(options = {audio: true}) {

  controller.create()
  controller."controller = UserMediaController::from"(page) {
    "WebCore::Page"."Supplement<Page>::from"(page, "UserMediaController")
  }

  request.create()
  request."UserMediaRequest::create"(doc, controller, options, successCallback, errorCallback) {
    # TODO
  }
  
  pause()
  request.start( ) {
    MediaStreamCenter."MediaStreamCenter::instance().queryMediaStreamSources"(queryClient = this) {
      "Nix::MediaStreamSourcesQueryClient".create()
      "Nix::MediaStreamSourcesQueryClient"."nixClient = Nix::MediaStreamSourcesQueryClient"(queryClient)         # nixClient is allocated as a local object here? investigate it.
  
      "Nix::MediaStreamCenter"."m_private->queryMediaStreamSources"(queryClient = nixClient) {
        "Nix::MediaStreamSource".create()
        "Nix::MediaStreamSource"."audioSources[0].initialize"("autoaudiosrc", Nix::MediaStreamSource::TypeAudio)
        "Nix::MediaStreamSource"."audioSources[0].setDeviceid"("autoaudiosrc;default")
        "Nix::MediaStreamSourcesQueryClient"."queryClient.didCompleteQuery"(audioSources, videoSources) {
          MediaStreamSource.create()
          MediaStreamSource."audioStreamSources"(audioSources)
          MediaStreamSource."videoStreamSources"(videoSources)
          UserMediaRequest."m_private->didCompleteQuery"(audioStreamSources, videoStreamSources) {
            controller."m_controller->requestUserMedia"(request = this, audioStreamSources, videoStreamSources) {
              UserMediaClientNix."m_client->requestUserMedia"(request, audioStreamSources, videoStreamSources) {
                "Nix::MediaStreamSource"."nixAudioSources"(audioStreamSources)
                "Nix::MediaStreamSource"."nixVideoSources"(videoStreamSources)
                "Nix::UserMediaRequest".create()
                "Nix::UserMediaRequest"."nixRequest"(request)
                pause()

                "Nix::UserMediaClient"."requestUserMedia"(nixRequest, nixAudioSources, nixVideoSources) {
                  "Nix::MediaStreamTrack".create()
                  "Nix::MediaStreamTrack"."nixAudioTracks[0].initialize"(nixAudioSources[0].id, nixAudioSources[0])
                  "Nix::MediaStream".create()
                  "Nix::MediaStream"."nixMediaStream.initialize"(nixAudioTracks, nixVideoTracks)
                  "Nix::UserMediaRequest"."nixRequest.requestSucceeded"(nixMediaStream) {
                    UserMediaRequest."m_private->succeed"(streamDescriptor = nixMediaStream) {
                      LocalMediaStream.create()
                      LocalMediaStream."stream = LocalMediaStream::create"(m_scriptExecution, streamDescriptor) {
                        # TODO ?
                      }
                      NavigatorUserMediaSuccessCallback."m_successCallback->handleEvent"(stream) {
                        app.successCallback(stream) { # suppose JS app invokes AudioContext.createMediaStreamSource(stream)
                        
                          # BEGIN webaudio mediastream source node creation
                          AudioContext.createMediaStreamSource(stream) {
                            AudioContext.lazyInitialize() {
                              DefaultAudioDestinationNode.initialize() {
                                AudioDestination."m_destination = AudioDestination::create"(*this, m_inputDeviceId, numInputChannels, numChannels, sampleRate) {
                                  "Nix::AudioDevice".create()
                                }
                              }
                              DefaultAudioDestinationNode.startRendering() {
                                AudioDestination.start() { # creates and starts Nix's audio device here (deviceId ??)
                                  "Nix::AudioDevice".start() {
                                    WebKitWebAudioSource.gst_pipeline_set_state(PLAYING)
                                  }
                                }
                              }
                            }
                            LocalMediaStream."audioTracks = stream->getAudioTracks"( )
                            MediaStreamTrack."source = audioTracks[0]->component()->source"( )
                            DefaultAudioDestinationNode."destination.enableInput"(inputDeviceId = source.deviceId) { # deviceId is set only here
                              DefaultAudioDestinationNode."m_inputDeviceId = inputDeviceId"()
                              AudioDestination."m_destination->stop"( ) {
                                "Nix::AudioDevice".stop( ) {
                                  WebKitWebAudioSource.gst_pipeline_set_statee(PAUSED)
                                }
                              }
                              AudioDestination."m_destination = AudioDestination::create"(*this, m_inputDeviceId, numInputChannels, numChannels, sampleRate) {
                                "Nix::AudioDevice".create()
                              }
                              AudioDestination."m_destination->start"( ) {
                                "Nix::AudioDevice".start( ) {
                                  WebKitWebAudioSource.gst_pipeline_set_state(PLAYING)
                                }
                              }
                            }
                            DefaultAudioDestinationNode."provider = destination->localAudioInputProvider"( )
                            MediaStreamAudioSourceNode.create()
                            MediaStreamAudioSourceNode.create(this, mediaStream, provider) {
                              # TODO
                            }
                            loop(rendering loop) {
                              DefaultAudioDestinationNode.render(...)
                            }
                          }
                          # END webaudio mediastream source node creation
                          
                        }
                      }
                    }
                  }
                } 
              }
            }  
          }
        }
      }
    }
  }
}

