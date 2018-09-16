//
//  PieChartViewController.swift
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/15/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

import UIKit

class PieChartViewController: UIViewController {
    
    @IBOutlet weak var pieChartView: PieChart!
    
    let eventManager = EventManager.sharedManager() as! EventManager
    
    var pieChartCalendars = [PieChartCalendar]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarTitle()
        DispatchQueue.global(qos: .userInitiated).async {
            self.eventManager.loadCustomCalendars { calendars in
                if let calendars = calendars {
                    self.convertToPieChartCalendars(calendars)
                }
            }
            DispatchQueue.main.async {
                self.setupPieChart()
            }
        }
    }
    
    private func setupNavBarTitle() {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = UIColor.clear
        if let font = UIFont(name: "AvenirNextCondensed-DemiBold", size: 20.0) {
            label.font = font
        }
        label.textAlignment = .center
        label.textColor = .black
        label.text = "Pie Chart"
        label.sizeToFit()
        navigationItem.titleView = label
    }

    
    private func convertToPieChartCalendars(_ calendars: [EKCalendar]) {
        let startDate = Date()
        var comps = DateComponents()
        comps.month = 1
        guard let endDate = Calendar.current.date(byAdding: comps, to: startDate) else { return }
        
        for calendar in calendars {
            let pieChartCalendar = PieChartCalendar(calendar: calendar)
            let events = pieChartCalendar.getEventsForCalendar(startDate: startDate, endDate: endDate)
            for event in events {
                pieChartCalendar.addDateInterval(DateInterval(start: event.startDate, end: event.endDate))
            }
            pieChartCalendars.append(pieChartCalendar)
        }
    }
    
    private func setupPieChart() {
        pieChartView.layers = [createPlainTextLayer()]
        
        pieChartView.models = createPieChartModels()
    }
            
    private func createPlainTextLayer() -> PiePlainTextLayer {
        let textLayerSettings = PiePlainTextLayerSettings()
        textLayerSettings.viewRadius = pieChartView.frame.size.width / 5
        textLayerSettings.hideOnOverflow = false
        textLayerSettings.label.font = UIFont(name: "AvenirNext-Medium", size: 14) ?? UIFont.systemFont(ofSize: 12)
        
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        textLayerSettings.label.textGenerator = { slice in
            return formatter.string(from: slice.data.percentage * 100 as NSNumber).map { "\($0)%" } ?? ""
        }
        
        let textLayer = PiePlainTextLayer()
        textLayer.animator = AlphaPieViewLayerAnimator()
        textLayer.settings = textLayerSettings
        
        return textLayer
    }
    
    private func createTextWithLinesLayer() -> PieLineTextLayer {
        let lineTextLayer = PieLineTextLayer()
        var lineTextLayerSettings = PieLineTextLayerSettings()
        lineTextLayerSettings.lineColor = UIColor.lightGray
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        lineTextLayerSettings.label.font = UIFont(name: "AvenirNext-Medium", size: 14) ?? UIFont.systemFont(ofSize: 12)
        lineTextLayerSettings.label.textGenerator = {slice in
            return formatter.string(from: slice.data.model.value as NSNumber).map { "\($0)" } ?? ""
        }
        
        lineTextLayer.settings = lineTextLayerSettings
        return lineTextLayer
    }
    
    private func createPieChartModels() -> [PieSliceModel] {
        var pieSliceModels = [PieSliceModel]()
        for pieChartCalendar in pieChartCalendars {
            let color = UIColor(cgColor: pieChartCalendar.calendar.cgColor)
            let value = pieChartCalendar.totalDurationOfEventsForCalendar
            if value > 0 {
                if let index = pieSliceModels.index(where: { $0.color == color }) {
                    let newValue = pieSliceModels[index].value + value
                    pieSliceModels[index] = PieSliceModel(value: newValue, color: color)
                } else {
                    pieSliceModels.append(PieSliceModel(value: value, color: color))
                }
            }
        }
        return pieSliceModels
    }

}

class PieChartCalendar {
    let calendar: EKCalendar
    var dateIntervals: [DateInterval]
    var totalDurationOfEventsForCalendar: TimeInterval
    
    init(calendar: EKCalendar) {
        self.calendar = calendar
        dateIntervals = [DateInterval]()
        totalDurationOfEventsForCalendar = 0
    }
    
    func addDateInterval(_ dateInterval: DateInterval) {
        dateIntervals.append(dateInterval)
        totalDurationOfEventsForCalendar += dateInterval.duration
    }
    
    func getEventsForCalendar(startDate: Date, endDate: Date) -> [EKEvent] {
        let eventManager = EventManager.sharedManager() as! EventManager
        let predicate = eventManager.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        return eventManager.eventStore.events(matching: predicate)
    }
}













