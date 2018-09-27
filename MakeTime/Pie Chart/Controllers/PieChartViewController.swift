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
    @IBOutlet weak var segmentedControl: BetterSegmentedControl!
    
    let eventManager = EventManager.sharedManager() as! EventManager
    
    var pieChartCalendars = [PieChartCalendar]()
    
    var startDate = Date()
    var endDate: Date?
    
    var dateRange = DateRange.week {
        didSet {
            var comps = DateComponents()
            switch dateRange {
            case .week:
                comps.weekOfYear = 1
            case .month:
                comps.month = 1
            case .year:
                comps.year = 1
            }
            endDate = Calendar.current.date(byAdding: comps, to: startDate)
            
            clearAllData()
            loadPieChartData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarTitle()
        setupSegmentedControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPieChartData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearAllData()
    }
    
    private func clearAllData() {
        pieChartCalendars.removeAll()
        pieChartView.clear()
    }
    
    private func loadPieChartData() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.eventManager.loadCustomCalendars { [weak self] calendars in
                if let calendars = calendars {
                    self?.convertToPieChartCalendars(calendars)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                self.setupPieChart()
            }
        }
    }
    
    private func setupSegmentedControl() {
//        segmentedControl.layer.borderWidth = 2
//        let purpleColor = UIColor(red: 81/255.0, green: 2/255.0, blue: 161/255.0, alpha: 1.0)
//        segmentedControl.layer.borderColor = purpleColor.cgColor
        segmentedControl.segments = LabelSegment.segments(withTitles: ["Week", "Month", "Year"],
                                                          normalFont: UIFont(name: "AvenirNext-Medium", size: 15.0)!,
                                                          normalTextColor: .darkGray,
                                                          selectedFont: UIFont(name: "AvenirNext-DemiBold", size: 15.0)!,
                                                          selectedTextColor: .white)
//        segmentedControl.options = [.indicatorViewBorderWidth(2),
//        .indicatorViewBorderColor(purpleColor)]
        segmentedControl.addTarget(self, action: #selector(controlValueChanged(_:)), for: .valueChanged)
    }
    
    @objc func controlValueChanged(_ sender: BetterSegmentedControl) {
        switch sender.index {
        case 0:
            dateRange = .week
        case 1:
            dateRange = .month
        case 2:
            dateRange = .year
        default:
            break
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
        if endDate == nil {
            var comps = DateComponents()
            comps.weekOfYear = 1
            endDate = Calendar.current.date(byAdding: comps, to: startDate)
        }
        for calendar in calendars {
            let pieChartCalendar = PieChartCalendar(calendar: calendar)
            let events = pieChartCalendar.getEventsForCalendar(startDate: startDate, endDate: endDate!)
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
        textLayerSettings.viewRadius = pieChartView.frame.size.width / 6
        textLayerSettings.hideOnOverflow = true
        textLayerSettings.label.font = UIFont(name: "AvenirNext-Medium", size: 13)!
        
        
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
        lineTextLayerSettings.label.font = UIFont(name: "AvenirNext-Medium", size: 13) ?? UIFont.systemFont(ofSize: 12)
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

enum DateRange {
    case week
    case month
    case year
}













