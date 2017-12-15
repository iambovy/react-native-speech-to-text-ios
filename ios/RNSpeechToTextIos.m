
#import "RNSpeechToTextIos.h"
#import <UIKit/UIKit.h>
#import <React/RCTUtils.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

@interface RNSpeechToTextIos () <SFSpeechRecognizerDelegate>

@property (nonatomic) SFSpeechRecognizer* speechRecognizer;
@property (nonatomic) SFSpeechAudioBufferRecognitionRequest* recognitionRequest;
@property (nonatomic) SFSpeechRecognitionTask* recognitionTask;
@property (nonatomic) SFSpeechURLRecognitionRequest* urlRequest;
@property (nonatomic) AVAudioEngine* audioEngine;
@property (nonatomic) AVAudioInputNode* inputNode;

@property (nonatomic) AVAudioSession* audioSession;


@property (nonatomic, weak, readwrite) RCTBridge *bridge;
@property (nonatomic, strong) NSMutableDictionary *result;

@end

@implementation RNSpeechToTextIos
{
}



- (void) sendResult:(NSDictionary*)error :(NSDictionary*)bestTranscription :(NSArray*)transcriptions :(NSNumber*)isFinal {
//    NSString *eventName = notification.userInfo[@"name"];
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    if (error.allValues.count > 0) {
        result[@"error"] = error;
    }
    if (bestTranscription != nil) {
        result[@"bestTranscription"] = bestTranscription;
    }
    if (transcriptions != nil) {
        result[@"transcriptions"] = transcriptions;
    }
    if (isFinal != nil) {
        result[@"isFinal"] = isFinal;
    }

    [self.bridge.eventDispatcher sendAppEventWithName:@"SpeechToText"
                                                 body:result];
}

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    if (available == false) {
        [self sendResult:RCTMakeError(@"Speech recognition is not available now", nil, nil) :nil :nil :nil];
    }
}

RCT_EXPORT_METHOD(finishRecognition)
{
    // lets finish it
    [self.recognitionTask finish];
    [self.recognitionRequest endAudio];

}


RCT_EXPORT_METHOD(stopRecognition)
{
  [self.inputNode removeTapOnBus:0];
  [self.audioEngine stop];
  [self.recognitionRequest endAudio];
}

RCT_EXPORT_METHOD(startRecognition:(NSString*)localeStr)
{
    self.audioEngine = [[AVAudioEngine alloc] init];

    NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:localeStr];
    self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:local];

    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusAuthorized: {
                    break;
                }
                case SFSpeechRecognizerAuthorizationStatusDenied: {
                    [self sendResult:RCTMakeError(@"User denied access to speech recognition", nil, nil) :nil :nil :nil];
                }
                case SFSpeechRecognizerAuthorizationStatusRestricted: {
                    [self sendResult:RCTMakeError(@"User denied access to speech recognition", nil, nil) :nil :nil :nil];
                }
                case SFSpeechRecognizerAuthorizationStatusNotDetermined: {
                    [self sendResult:RCTMakeError(@"User denied access to speech recognition", nil, nil) :nil :nil :nil];
                }
            }
        });

    }];


  if (self.recognitionTask) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }

    self.audioSession = [AVAudioSession sharedInstance];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [self.audioSession setActive:TRUE withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

    self.inputNode = self.audioEngine.inputNode;

    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    self.recognitionRequest.shouldReportPartialResults = NO;

    AVAudioFormat *format = [self.inputNode outputFormatForBus:0];

    [self.inputNode installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    [self.audioEngine prepare];
    NSError *error1;
    [self.audioEngine startAndReturnError:&error1];
    NSLog(@"%@", error1.description);

    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {

        if (result != nil) {
            NSMutableDictionary *result_dic = [NSMutableDictionary dictionary];
            [result_dic setObject:result.bestTranscription.formattedString forKey:@"formattedString"];
            [self sendResult:nil :result_dic :nil :[NSNumber numberWithInt:1]];

        } else {

            [self.audioEngine stop];
            self.recognitionTask = nil;
            self.recognitionRequest = nil;
            NSMutableDictionary *error_dic = [NSMutableDictionary dictionary];
           [error_dic setObject:@"result is null" forKey:@"message"];
           [self sendResult:error_dic :nil :nil :[NSNumber numberWithInt:0]];
        }
    }];
}




- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

//- (NSDictionary *)constantsToExport {
//    return @{@"greeting": @"Welcome to the DevDactic\n React Native Tutorial!"};
//}


@end
