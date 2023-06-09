import Foundation


extension Date {
  private var hourAndMinute: (hour: Int, minute: Int) {
    let components = NSCalendar.current.dateComponents([.hour, .minute], from: self)
    return (components.hour!, components.minute!)
  }
  
  func isTimeOfDayBetween(startTimeOfDay from: Date, endTimeOfDay to: Date) -> Bool {
    // Get minutes and hours from each date
    let (hour, minute) = hourAndMinute
    let (fromHour, fromMinute) = from.hourAndMinute
    let (toHour, toMinute) = to.hourAndMinute
    
    let timeRangeCrossesMidnight = fromHour > toHour || (fromHour == toHour && fromMinute > toMinute)
    
    if timeRangeCrossesMidnight {
      // Time range crosses midnight (e.g. 11 PM to 3 AM)
      if (hour > toHour && hour < fromHour) ||
        (hour == toHour && minute >= toMinute) ||
        (hour == fromHour && minute < fromMinute) {
        // We are outside of allowed time range
        return false
      }
    } else {
      // Time range doesn't cross midnight (e.g. 4 AM to 5 PM)
      if (hour > toHour || hour < fromHour) ||
        (hour == toHour && minute >= toMinute) ||
        (hour == fromHour && minute < fromMinute) {
        // We are outside of allowed time range
        return false
      }
    }
    
    return true
  }
}
