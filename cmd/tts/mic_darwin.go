package main

/*
#cgo LDFLAGS: -framework CoreAudio
#include <CoreAudio/CoreAudio.h>

static int isMicActive() {
    AudioObjectID defaultDevice;
    UInt32 size = sizeof(AudioObjectID);
    AudioObjectPropertyAddress addr = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };

    OSStatus err = AudioObjectGetPropertyData(
        kAudioObjectSystemObject, &addr, 0, NULL, &size, &defaultDevice
    );
    if (err != 0 || defaultDevice == kAudioObjectUnknown) {
        return 0;
    }

    UInt32 isRunning = 0;
    addr.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    size = sizeof(UInt32);
    err = AudioObjectGetPropertyData(defaultDevice, &addr, 0, NULL, &size, &isRunning);
    if (err != 0) {
        return 0;
    }

    return isRunning > 0 ? 1 : 0;
}
*/
import "C"

// micActive returns true if the default input device (microphone) is currently in use.
var micActive = func() bool {
	return C.isMicActive() == 1
}
