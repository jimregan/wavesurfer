
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


void requestMicAccess() {
  NSLog(@"doRequest");

  [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
      if (granted) {
	FILE *ff = fopen("/tmp/ff.txt","w");
	fprintf(ff,"Granted!");
	fclose(ff);
	NSLog(@"granted");
      } else {
	FILE *ff = fopen("/tmp/ff.txt","w");
	fprintf(ff,"NOT granted!");
	fclose(ff);
	NSLog(@"not granted");
      }
    }];

}
