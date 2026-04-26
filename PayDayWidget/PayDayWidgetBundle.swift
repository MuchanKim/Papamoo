import WidgetKit
import SwiftUI

@main
struct PayDayWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallDdayWidget()
        SmallTotalWidget()
        MediumUpcomingWidget()
    }
}
