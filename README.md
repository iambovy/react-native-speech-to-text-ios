
# react-native-speech-to-text-ios 

React Native speech recognition component for iOS 10+

## Getting started


## IMPORTANT xCode plist settings

Also, you need open the React Native xCode project and add two new keys into `Info.plist`
Just right click on `Info.plist` -> `Open As` -> `Source Code` and paste these strings somewhere into root `<dict>` tag

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>Your usage description here</string>
```

Application will crash if you don't do this.

## Usage

```js

import {
  ...
  NativeAppEventEmitter,
  ...
} from 'react-native';

var SpeechToText = require('react-native-speech-to-text-ios');

...

this.subscription = NativeAppEventEmitter.addListener(
  'SpeechToText',
  (result) => {

    if (result.error) {
      alert(JSON.stringify(result.error));
    } else {
      console.log(result.bestTranscription.formattedString);
    }

  }
);

SpeechToText.startRecognition("en-US");

...

componentWillUnmount() {
  if (this.subscription != null) {
    this.subscription.remove();
    this.subscription = null;
  }
}

```

To stop recording call `SpeechToText.finishRecognition()` but after that you can continue to receive event with final recognition results. The events will not arrive after `result.isFinal == true`.
Call `SpeechToText.stopRecognition()` to cancel current recognition task.
The `result` objects reflects Apple `SFSpeechRecognitionResult` class.
