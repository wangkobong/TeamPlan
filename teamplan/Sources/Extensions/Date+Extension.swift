//
//  Date+Extension.swift
//  teamplan
//
//  Created by sungyeon kim on 3/30/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import UIKit

extension TimeZone {
    static let korea = TimeZone(identifier: "Asia/Seoul")!
}

extension Locale {
    static let korea = Locale(identifier: "ko_KR")
}

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
//    formatter.timeZone = NSTimeZone.system
    formatter.timeZone = .korea
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    return formatter
}()

extension Date {
    // 일주일은 며칠?
    public var daysPerWeek: Int {
        get {
            return 7
        }
    }

    var yearMonth: String {
        return "\(self.year)년 \(self.month)월"
    }

    var yearMonthDay: String {
        formatter.dateFormat = "yyyy년 M월 d일"
        let string = formatter.string(from: self)
        return string
    }

    var monthDayNoLeadingZeros: String {
        formatter.dateFormat = "M월 d일"
        formatter.locale = .korea
        let string = formatter.string(from: self)
        return string
    }

    var checkDay: String {
        formatter.dateFormat = "MM월 dd일"
        formatter.locale = .korea
        let string = formatter.string(from: self)

        return string + "(\(week()))"
    }

    var checkDay2: String {
        formatter.dateFormat = "M월 dd일"
        formatter.locale = .korea
        let string = formatter.string(from: self)

        return string + "(\(week()))"
    }

    var checkDayNoLeadingZeros: String {
        return self.monthDayNoLeadingZeros + "(\(week()))"
    }

    var simpleCheckDay: String {
        formatter.dateFormat = "M.d"

        let string = formatter.string(from: self)

        return string + "(\(week()))"
    }

    var regularCheckDay: String {
        formatter.dateFormat = "MM.dd"

        let string = formatter.string(from: self)

        return string + "(\(week()))"
    }

    /// yy.MM.dd
    var fullCheckDay: String {
        formatter.dateFormat = "yy.MM.dd"
        formatter.locale = .korea
        let string = formatter.string(from: self)
        return string
    }
    
    /// yy.MM.dd
    var fullCheckDay2: String {
        formatter.dateFormat = "yy.MM.dd"
        formatter.locale = .korea
        let string = formatter.string(from: self)
        return string + " (\(week()))"
    }

    var recentlySearchDate: String {
        formatter.dateFormat = "yyyy.MM.dd"
        let string = formatter.string(from: self)
        return string + " " + "(\(week()))"
    }

    /// yyyy-MM-dd
    var hyphenCheckDay: String {
        formatter.dateFormat = "yyyy-MM-dd"
        let string = formatter.string(from: self)
        return string
    }

    /// yyyy-MM-dd HH:mm
    var reservationDay: String {
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let string = formatter.string(from: self)
        return string
    }

    /// yyyyMMddHHmmss
    var reservationReqDay: String {
        formatter.dateFormat = "yyyyMMddHHmmss"
        let string = formatter.string(from: self)
        return string
    }

    /// yyyyMMdd
    var reservationMakeDay: String {
        formatter.dateFormat = "yyyyMMdd"
        let string = formatter.string(from: self)
        return string
    }

    /// MMdd
    var normalMonthDay: String {
        formatter.dateFormat = "MM월 dd일"
        let string = formatter.string(from: self)
        return string
    }

    var dateFormatMakeDay: String {
        formatter.dateFormat = "yyyyMMddaa"
        let string = formatter.string(from: self)
        return string
    }

    var makeDayOfTheWeek: String {
        formatter.dateFormat = "yyyyMMddaa"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let string = formatter.string(from: self)
        return string
    }

    var cancelFeeDay: String {
        formatter.dateFormat = "dd.MM.yy.HH:mm:ss"
        let string = formatter.string(from: self)
        return string
    }

    var floatingButtonDay: String {
        formatter.dateFormat = "MM/dd(EEE) HH:mm"
        formatter.locale = .korea
        let string = formatter.string(from: self)
        return string
    }

    /// 오늘을 나타내는 Date 값입니다.
    var today: Date {
        return Calendar.current.date(byAdding: DateComponents(day: 0), to: self)!
    }

    /// 이전 날을 나타내는 Date 값입니다.
    var yesterday: Date {
        return Calendar.current.date(byAdding: DateComponents(day: -1), to: self)!
    }

    /// 다음 날을 나타내는 Date 값입니다.
    var tomorrow: Date {
        return Calendar.current.date(byAdding: DateComponents(day: 1), to: self)!
    }

    /// Date의 대한 요일 number를 가져온다,  1=일요일, 2=월요일, 3=화, 4=수, 5=목, 6=금, 7=토
    var weekday: Int {
        return Calendar.current.dateComponents([.weekday], from: self).weekday!
    }

    var isToday: Bool {
        return calendar.isDateInToday(self)
    }

    var year: Int {
        return calendar.component(.year, from: self)
    }

    var month: Int {
        return calendar.component(.month, from: self)
    }

    var day: Int {
        return calendar.component(.day, from: self)
    }

    var hour: Int {
        return calendar.component(.hour, from: self)
    }

    var minute: Int {
        return calendar.component(.minute, from: self)
    }

    var second: Int {
        return calendar.component(.second, from: self)
    }

    // Init
    init(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) {
        self.init(
            timeIntervalSince1970: Date().fixed(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
                ).timeIntervalSince1970
        )
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .korea
        calendar.locale   = .korea
        return calendar
    }

    /// 절대값지정
    ///
    /// - Parameters:
    ///   - year: 년
    ///   - month: 월
    ///   - day: 일
    ///   - hour: 시간
    ///   - minute: 분
    ///   - second: 초
    /// - Returns: Date
    func fixed(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) -> Date {
        let calendar = self.calendar

        var comp = DateComponents()
        comp.year = year ?? calendar.component(.year, from: self)
        comp.month = month ?? calendar.component(.month, from: self)
        comp.day = day ?? calendar.component(.day, from: self)
        comp.hour = hour ?? calendar.component(.hour, from: self)
        comp.minute = minute ?? calendar.component(.minute, from: self)
        comp.second = second ?? calendar.component(.second, from: self)

        return calendar.date(from: comp)!
    }

    /// 상대값지정
    ///
    /// - Parameters:
    ///   - year: 년
    ///   - month: 월
    ///   - day: 일
    ///   - hour: 시간
    ///   - minute: 분
    ///   - second: 초
    /// - Returns: Date
    func added(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) -> Date {
        let calendar = self.calendar

        var comp = DateComponents()
        comp.year = (year ?? 0) + calendar.component(.year, from: self)
        comp.month = (month ?? 0) + calendar.component(.month, from: self)
        comp.day = (day ?? 0) + calendar.component(.day, from: self)
        comp.hour = (hour ?? 0) + calendar.component(.hour, from: self)
        comp.minute = (minute ?? 0) + calendar.component(.minute, from: self)
        comp.second = (second ?? 0) + calendar.component(.second, from: self)

        return calendar.date(from: comp)!
    }

    /// 특정 개월수 만큼의 첫번째 날 배열
    func addMonth(monthCount count: Int) -> [Date] {
        let calendar = self.calendar

        return (0 ..< count).map { m in
            var comp = DateComponents()
            comp.month = m + calendar.component(.month, from: self)
            comp.year = self.year
            return calendar.date(from: comp)!.firstDateOfMonth
        }
    }

    /// 해당하는 달의 모든 일(이전달, 다음달 포함)
    /// ex) 1일이 수요일이라면 이전달의 일, 월, 화의 Date 포함
    /// ex) 31일이 목요일이라면 다음달의 금, 토 Date 포함
    func monthOfDate() -> [Date] {
        // 달의 첫번째 날의 위치 (일요일 - 1, 토요일 - 7)
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        let ordinalityOfFirstDay = calendar.ordinality(of: .day, in: .weekOfMonth, for: firstDateOfMonth)

        let dateRange = NSCalendar.current.range(of: .weekOfMonth, in: .month, for: self)
        let numberOfItems = dateRange!.count * 7

        return (0 ..< numberOfItems).map {
            var dateComponents = DateComponents()

            dateComponents.day = $0 - (ordinalityOfFirstDay! - 1)

            return Calendar.current.date(byAdding: dateComponents as DateComponents, to: firstDateOfMonth)!
        }
    }

    /// 달의 시작일
    public var firstDateOfMonth: Date {
        get {
            let calendar = NSCalendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: self)
            components.day = 1
            return calendar.date(from: components)!
        }
    }

    /// 자기 자신의 Date 시간값 초기화
    public var clearDate: Date {
        get {
            let calendar = NSCalendar.current
            var components = calendar.dateComponents([.year, .month, .day /* , .hour, .minute, .second */], from: self)
            components.hour = 0
            components.minute = 0
            components.second = 0

            return calendar.date(from: components)!
        }
    }

    /// 달의 주 수
    public var numberOfWeeksForMonth: Int {
        get {
            let rangeOfWeeks = NSCalendar.current.range(of: Calendar.Component.weekOfMonth,
                                                        in: Calendar.Component.month,
                                                        for: firstDateOfMonth)
            return (rangeOfWeeks?.count)!
        }
    }

    /// 달의 일 수
    public var numberOfDaysForMonth: Int {
        get {
            let rangeOfDays = NSCalendar.current.range(of: Calendar.Component.day,
                                                       in: Calendar.Component.month,
                                                       for: firstDateOfMonth)
            return (rangeOfDays?.count)!
        }
    }

    /// 달의 첫번째 날의 위치 (일요일 - 1, 토요일 - 7)
    public var ordinalityOfFirstDay: Int {
        get {
            Calendar.current.ordinality(of: .day, in: .weekOfMonth, for: firstDateOfMonth)!
        }
    }

    // *** 요일값 *** //

    enum SymbolType {
        case `default`
        case standalone
        case veryShort
        case short
        case shortStandalone
        case veryShortStandalone
        case custom(symbols: [String])
    }

    var weekIndex: Int {
        return calendar.component(.weekday, from: self) - 1
    }

    var isDayOfWeek: Bool {
        let index = self.weekday
        // 1=일요일, 2=월요일, 3 화, 4 수, 5 목, 6 금, 7 토
        // 숙박은 금요일만, 대실은 금요일, 일요일
        // 숙박은 토요일만 주말
        // 대실은 토, 일만 주말
        //if index != 6, index != 7 { // 문제
        if index != 7, index != 1 {   // 수정됨
            return true
        }
        return false
    }

    //  00~03시면 True, 아니면 False
    var isDayBreakTime: Bool {
        return self.hour >= 00 && self.hour < 03
    }

    func weeks(_ type: SymbolType = .short, locale: Locale? = nil) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = locale ?? calendar.locale

        switch type {
        case .`default`:           return formatter.weekdaySymbols
        case .standalone:          return formatter.standaloneWeekdaySymbols
        case .veryShort:           return formatter.veryShortWeekdaySymbols
        case .short:               return formatter.shortWeekdaySymbols
        case .shortStandalone:     return formatter.shortStandaloneWeekdaySymbols
        case .veryShortStandalone: return formatter.veryShortStandaloneWeekdaySymbols
        case let .custom(symbols): return symbols
        }
    }

    func week(_ type: SymbolType = .short, locale: Locale? = nil) -> String {
        return weeks(type, locale: locale)[weekIndex]
    }

    // Date→String
    func string(format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> String {
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// Date → time string
    func timeString(format: String = "HH00") -> String {
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func timeString2(format: String = "HH:00") -> String {
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func timeString3(format: String = "HH:mm") -> String {
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func hourString(format: String = "HH") -> String {
        formatter.timeZone = .korea
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func hourMinute(format: String = "HHmm") -> String {
        formatter.timeZone = .korea
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func dateStringRegularFormat() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KO")
        formatter.dateFormat = "yyyy.MM.dd"
        let dateString = formatter.string(from: self)
        return dateString
    }

    func dateStringWithSymbol() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KO")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
//        formatter.dateFormat = "yyyy-MM-dd a hh:mm"
//        formatter.amSymbol = "오전"
//        formatter.pmSymbol = "오후"

        let dateString = formatter.string(from: self)
        return dateString
    }

    func dateForReservationInfo() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KO")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"

        let dateString = formatter.string(from: self)
        return dateString
    }

    func dateStringOnlyFormat() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KO")
//        formatter.dateFormat = "HH:00"
        formatter.dateFormat = "a hh:00"
        formatter.amSymbol = "오전"
        formatter.pmSymbol = "오후"

        let dateString = formatter.string(from: self)
        return dateString
    }

    func dateStringReservationFormat() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KO")
        formatter.dateFormat = "HH:00"
        formatter.timeZone = .korea
//        formatter.dateFormat = "a hh:00"
//        formatter.amSymbol = "오전"
//        formatter.pmSymbol = "오후"

        let dateString = formatter.string(from: self)
        //let checkDay = self.checkDay + "(\(week())) " + dateString
        let checkDay = self.checkDayNoLeadingZeros + " " + dateString
        return checkDay
    }
    func dateStringCouponPeriod() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KO")
        formatter.dateFormat = "yyyy.MM.dd HH"
        formatter.timeZone = .korea
        //formatter.dateFormat = "yyyy.MM.dd a H"
        //formatter.amSymbol = "오전"
        //formatter.pmSymbol = "오후"

        let dateString = formatter.string(from: self)
        return dateString
    }

    func ignoreHourMinutesSeconds() -> Date {
        return self.added(hour: -self.hour, minute: -self.minute, second: -self.second)
    }

    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date) > 0 {
            return years(from: date) == 1 ? "작년" : "\(years(from: date))년 전"
        }
        if months(from: date) > 0 {
            return months(from: date) == 1 ? "한 달 전" : "\(months(from: date))개월 전"
        }
        if weeks(from: date) > 0 {
            return weeks(from: date) == 1 ? "일주일 전" : "\(weeks(from: date))주 전"
        }
        if days(from: date) > 0 {
            return days(from: date) == 1 ? "하루 전" : "\(days(from: date))일 전"
        }
        if hours(from: date) > 0 {
            return hours(from: date) == 1 ? "한 시간 전" : "\(hours(from: date))시간 전"
        }
        //  59초까지는 "방금 전", 1분부터는 "1분 전"
        if minutes(from: date) > 0 {
            return "\(minutes(from: date))분 전"
        }
        if seconds(from: date) > 0 {
            return "방금 전"
        }
        return ""
    }

    //  날짜와 날짜사이에 간격을 구하고 싶은데, offset()에는 없는 type을 구하고 싶을 때
    func dateAgo(from date: Date) -> (type: Calendar.Component, offset: Int)? {
        if years(from: date) > 0 {
            return (type: .year, offset: years(from: date))
        }
        if months(from: date) > 0 {
            return (type: .month, offset: months(from: date))
        }
        if weeks(from: date) > 0 {
            return (type: .weekOfMonth, offset: weeks(from: date))
        }
        if days(from: date) > 0 {
            return (type: .weekOfMonth, offset: weeks(from: date))
        }
        if hours(from: date) > 0 {
            return (type: .hour, offset: hours(from: date))
        }
        if minutes(from: date) > 0 {
            return (type: .minute, offset: minutes(from: date))
        }
        if seconds(from: date) > 0 {
            return (type: .second, offset: seconds(from: date))
        }
        return nil
    }

    func diffDay(with date: Date) -> Int {
        if days(from: date) > 0 {
            return days(from: date)
        }
        return 0
    }

    func regIn15Mins(with reg: Date) -> Bool {
        let regT = reg.added(second: -reg.second)
        if minutes(from: regT) < 15 {
            return true
        }
        return false
    }

    func regIn1Hours(with reg: Date) -> Bool {
        let regT = reg.added(second: -reg.second)
        if minutes(from: regT) < 60 {
            return true
        }
        return false
    }

    func startIn3Hours(with date: Date) -> Bool {
        if seconds(from: date) > 10_800 {
            return true
        }
        return false
    }

    func overEnteringTime(with date: Date) -> Bool {
        if minutes(from: date) < 0 {
            return true
        }
        return false
    }

    var isTodaysReservation: Bool {
        let currTime = Date()
        if currTime.isDayBreakTime {
            return self.reservationMakeDay == currTime.added(hour: -3).reservationMakeDay
        } else {
            return self.isToday
        }
    }

    func isEqual(_ compareDate: Date) -> Bool {
        return self.clearDate.day == compareDate.clearDate.day && self.clearDate.month == compareDate.clearDate.month && self.clearDate.year == compareDate.clearDate.year
    }
}

extension Date {
    /// 입력된 포맷으로 Date 타입을 문자열로 변환합니다.
    ///
    /// - Parameter format: 포맷
    /// - Returns: 문자열
    ///
    /// ```
    /// let string = Date().string(withFormat: "yyyyMMdd")
    /// ```
    ///
//    func string(withFormat format: String, locale: Locale = .korea) -> String {
//        return DateFormatter().then {
//            $0.dateFormat = format
//            $0.locale = locale
//        }.string(from: self)
//    }
//
//    func string(withFormat format: String, timeZone: TimeZone = .korea) -> String {
//        return DateFormatter().then {
//            $0.dateFormat = format
//            $0.locale = .korea
//            $0.timeZone = timeZone
//        }.string(from: self)
//    }
}

extension Date {
    /// 체크인 체크아웃 텍스트
    /// "yy.MM.dd (화)"
    func dateAndTimeText() -> String {
        let date = self.fullCheckDay
        let hour = self.timeString2()
        return "\(date) \(hour)"
    }

    /// 체크인 체크아웃 텍스트
    /// "M월 dd일 (화)"
    func dateAndTimeText2() -> String {
        let date = self.checkDay2
        let hour = self.timeString2()
        return "\(date)\n\(hour)"
    }

    /// 체크인 체크아웃 텍스트 (예약 상세)
    /// "MM월 dd일 (화)"
    func dateAndTimeText3() -> String {
        let date = self.checkDay
        let hour = self.timeString2()
        return "\(date)\n\(hour)"
    }

    /// 무료취소 텍스트
    func freeCancelTimeText() -> String {
        let date = self.recentlySearchDate
        let hour = self.timeString3()
        return "\(date)\(hour)"
    }
}
