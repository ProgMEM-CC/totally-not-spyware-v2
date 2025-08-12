#include "alert.h"

extern SInt32 CFUserNotificationDisplayAlert(
    CFTimeInterval timeout,
    CFOptionFlags flags,
    CFURLRef iconURL,
    CFURLRef soundURL,
    CFURLRef localizationURL,
    CFStringRef alertHeader,
    CFStringRef alertMessage,
    CFStringRef defaultButtonTitle,
    CFStringRef alternateButtonTitle,
    CFStringRef otherButtonTitle,
    CFOptionFlags *responseFlags);

CFOptionFlags popupTimeout(CFStringRef title, CFStringRef text, CFStringRef buttonOne, CFStringRef buttonTwo, CFStringRef buttonThree, CFTimeInterval timeout)
{
    CFOptionFlags flags;
    CFUserNotificationDisplayAlert(timeout, 0, NULL, NULL, NULL, title, text, buttonOne, buttonTwo, buttonThree, &flags);
    return flags & 0x3;
}

CFOptionFlags popup(CFStringRef title, CFStringRef text, CFStringRef buttonOne, CFStringRef buttonTwo, CFStringRef buttonThree)
{
    return popupTimeout(title, text, buttonOne, buttonTwo, buttonThree, 0);
}