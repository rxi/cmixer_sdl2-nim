import sdl2
import sdl2.audio
import cmixer
export cmixer except init


var
  device: AudioDeviceId


{.push stackTrace: off.}
proc audioCallback(userdata: pointer, stream: ptr uint8, len: cint) {.cdecl.} =
  process(cast[ptr cshort](stream), len div 2)
{.pop.}


{.push stackTrace: off.}
proc lockHandler(e: ptr cmixer.Event) {.cdecl.} =
  case e.kind:
  of EVENT_LOCK: device.lockAudioDevice()
  of EVENT_UNLOCK: device.unlockAudioDevice()
  else: discard
{.pop.}


proc init*(samplerate=44100, buffersize=1024) =
  sdl2.init(INIT_AUDIO)

  var fmt, got: AudioSpec
  fmt.freq = cint(samplerate)
  fmt.format = AudioFormat(AUDIO_S16)
  fmt.channels = uint8(2)
  fmt.samples = uint16(buffersize)
  fmt.callback = audioCallback

  device = openAudioDevice(
    nil, 0, addr fmt, addr got,
    SDL_AUDIO_ALLOW_FREQUENCY_CHANGE)

  if device == 0:
    raise newException(Exception, $sdl2.getError())

  cmixer.init(got.freq)
  setLock(lockHandler)

  device.pauseAudioDevice(0)


proc deinit* =
  closeAudioDevice(device)


when isMainModule:
  init(44100)

  # The "test.ogg" file is not included, your must provide your own
  var src = newSourceFromFile("test.ogg")
  src.setLoop(true)
  src.play()

  echo "Press [return] to exit"
  discard stdin.readLine()

  deinit()
