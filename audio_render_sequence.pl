:GStreamer
:WebKitWebAudioSourceGStreamer
:AudioDestinationNix
"destination->m_inputFifo": AudioFIFO
"destination->m_fifo": AudioPullFIFO
wrapperBus: AudioBus
m_renderBus: AudioBus
:DefaultAudioDestinationNode
:"AudioDestinationNode::LocalAudioInputProvider"
:AudioNodeInput
:AudioNodeOutput
:MediaStreamAudioSourceNode

loop() {
  :GStreamer WebKitWebAudioSourceGStreamer.webKitWebAudioSrcLoop(src) {
    WebKitWebAudioSourceGStreamer>"buffer = allocateBufferForChannel"(i)
    WebKitWebAudioSourceGStreamer>mapBufferForChannel(i, buffer)
    
    AudioDestinationNix."priv->handler->render"(sourceData, audioData, nframes) {

      :AudioDestinationNix wrapperBus.create()
      :AudioDestinationNix wrapperBus.setChannelMemory(0, sourceData[0], nFrames)
      :AudioDestinationNix wrapperBus.setChannelMemory(1, sourceData[1], nFrames)
      :AudioDestinationNix "destination->m_inputFifo".push(wrapperBus) {
        "destination->m_inputFifo">memcpy(...)
        wrapperBus.destroy()
      }
      
      :AudioDestinationNix m_renderBus.setChannelMemory(0, audioData[0], nFrames)
      :AudioDestinationNix m_renderBus.setChannelMemory(1, audioData[1], nFrames)
      :AudioDestinationNix "destination->m_fifo".consume(m_renderBus) {
          "destination->m_fifo":AudioPullFIFO AudioDestinationNix."m_provider.provideInput"(m_tempBus) {
          :AudioDestinationNix "destination->m_inputFifo".consume(m_inputBus, nFrames) {
            "destination->m_inputFifo">memcpy(...)
          }
          :AudioDestinationNix DefaultAudioDestinationNode."m_callback.render"(sourceBus = m_inputBus, detinationBus = m_tempBus, nFrames) {
            AudioContext.pageConsentRequiredForAudioStart(...)
            AudioContext.handlePreRenderTasks(...)
            "AudioDestinationNode::LocalAudioInputProvider"."m_localAudioInputProvider.set"(sourceBus) {
              "AudioDestinationNode::LocalAudioInputProvider"."m_sourceBus->copyFrom"(sourceBus)
            }
            loop() {
              AudioNodeInput."input(0)->pull"(destinationBus, nFrames) {
                AudioNodeOutput."output.pull"(destinationBus, nFrames) {
                  MediaStreamAudioSourceNode."AudioNode::processIfNecessary"(nFrames) {
                    MediaStreamAudioSourceNode.process(nFrames) {
                      MediaStreamAudioSourceNode."AudioNode::pullInputs"(nFrames) {
                        loop() {
                          AudioNodeInput."input(i)->pull"(0, nFrames)
                        }
                      }
                      "AudioDestinationNode::LocalAudioInputProvider"."audioSourceProvider()->provideInput"(destinationBus = "output[0]->bus", nFrames) {
                      "AudioDestinationNode::LocalAudioInputProvider"."destinationBus->copyFrom"(m_sourceBus)
                      }
                    }
                  }
                }
              }
            }
            AudioContext.handlePosRenderTasks(...)
          }
        }
        "destination->m_fifo">memcpy(...)
      }
    }
    
    GStreamer.chain(pads)
  }
}
