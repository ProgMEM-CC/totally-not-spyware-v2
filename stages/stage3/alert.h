#include <CoreFoundation/CoreFoundation.h>
CFOptionFlags popupTimeout(CFStringRef title, CFStringRef text, CFStringRef buttonOne, CFStringRef buttonTwo, CFStringRef buttonThree, CFTimeInterval timeout);
CFOptionFlags popup(CFStringRef title, CFStringRef text, CFStringRef buttonOne, CFStringRef buttonTwo, CFStringRef buttonThree);