#import <XCTest/XCTest.h>
#import "NSDate+TimeOfDayMath.h"


@interface TimeOfDayMathTests : XCTestCase @end

@implementation TimeOfDayMathTests

- (NSDate *)timeWithHour:(NSInteger)hour minute:(NSInteger)minute {
    NSDateComponents *components = NSDateComponents.new;
    
    components.calendar = NSCalendar.currentCalendar;
    
    components.hour = hour;
    components.minute = minute;
    
    return components.date;
}

- (void)testNonWrappingIntervals {
    NSDate *time0415 = [self timeWithHour:4 minute:15];
    NSDate *time0400 = [self timeWithHour:4 minute:0];
    NSDate *time0500 = [self timeWithHour:5 minute:0];
    XCTAssertTrue([time0415 isTimeOfDayBetweenDate:time0400 andDate:time0500]);
    XCTAssertFalse([time0400 isTimeOfDayBetweenDate:time0415 andDate:time0500]);
    XCTAssertFalse([time0500 isTimeOfDayBetweenDate:time0400 andDate:time0415]);
}

- (void)testWrappingIntervals {
    NSDate *time0715 = [self timeWithHour:7 minute:15];
    NSDate *time0245 = [self timeWithHour:2 minute:45];
    NSDate *time0700 = [self timeWithHour:7 minute:0];
    NSDate *time0300 = [self timeWithHour:3 minute:0];
    XCTAssertTrue([time0715 isTimeOfDayBetweenDate:time0700 andDate:time0300]);
    XCTAssertTrue([time0245 isTimeOfDayBetweenDate:time0700 andDate:time0300]);
    XCTAssertFalse([time0700 isTimeOfDayBetweenDate:time0715 andDate:time0300]);
    XCTAssertFalse([time0300 isTimeOfDayBetweenDate:time0700 andDate:time0245]);
}

- (void)testExactTimes {
    // Upper bound is considered "outside" of range
    NSDate *time0400 = [self timeWithHour:4 minute:0];
    NSDate *time0500 = [self timeWithHour:5 minute:0];
    XCTAssertTrue([time0400 isTimeOfDayBetweenDate:time0400 andDate:time0500]);
    XCTAssertFalse([time0500 isTimeOfDayBetweenDate:time0400 andDate:time0500]);
    
    NSDate *time0900 = [self timeWithHour:9 minute:0];
    NSDate *time0100 = [self timeWithHour:1 minute:0];
    XCTAssertTrue([time0900 isTimeOfDayBetweenDate:time0900 andDate:time0100]);
    XCTAssertFalse([time0100 isTimeOfDayBetweenDate:time0900 andDate:time0100]);
}

@end
