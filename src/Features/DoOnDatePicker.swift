import SwiftUI

struct DoOnDatePicker: View {
    @Binding var date: Date
    var preventsPast: Bool = false

    private var range: ClosedRange<Date> {
        preventsPast ? Date()...Date.distantFuture : Date.distantPast...Date.distantFuture
    }

    var body: some View {
        DatePicker("Do-on date", selection: $date, in: range, displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: 160)
            .help("Do-on date")
    }
}
