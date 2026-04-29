import WidgetKit
import SwiftUI

@main
struct PapamooWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallDdayWidget()
        SmallTotalWidget()
        MediumUpcomingWidget()
    }
}
