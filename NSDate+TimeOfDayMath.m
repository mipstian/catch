#import "NSDate+TimeOfDayMath.h"


@implementation NSDate (TimeOfDayMath)

- (BOOL)isTimeOfDayBetweenDate:(NSDate *)from andDate:(NSDate *)to {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    
    // Get minutes and hours from each date
    NSDateComponents *dateComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
                                            fromDate:self];
    NSDateComponents *fromComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
                                             fromDate:from];
    NSDateComponents *toComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
                                           fromDate:to];
    
    BOOL timeRangeCrossesMidnight = fromComp.hour > toComp.hour || (fromComp.hour == toComp.hour && fromComp.minute > toComp.minute);
    
    if (timeRangeCrossesMidnight) {
        // Time range crosses midnight (e.g. 11 PM to 3 AM)
        if ((dateComp.hour > toComp.hour && dateComp.hour < fromComp.hour) ||
            (dateComp.hour == toComp.hour && dateComp.minute >= toComp.minute) ||
            (dateComp.hour == fromComp.hour && dateComp.minute < fromComp.minute)) {
            // We are outside of allowed time range
            return NO;
        }
    }
    else {
        // Time range doesn't cross midnight (e.g. 4 AM to 5 PM)
        if ((dateComp.hour > toComp.hour || dateComp.hour < fromComp.hour) ||
            (dateComp.hour == toComp.hour && dateComp.minute >= toComp.minute) ||
            (dateComp.hour == fromComp.hour && dateComp.minute < fromComp.minute)) {
            // We are outside of allowed time range
            return NO;
        }
    }
    
    return YES;
}

@end
