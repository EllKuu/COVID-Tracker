//
//  ViewController.swift
//  COVID Tracker
//
//  Created by elliott kung on 2021-06-13.
//

import Charts
import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /*
     - call APIS
     - view models
     - View: table view
     - Filter / Pick state
     - update main ui
     */
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.formatterBehavior = .default
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        return formatter
    }()

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        return table
    }()
    
    private var dayData: [DayData] = [] {
        didSet{
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.createGraph()
            }
        }
    }
    
    private var scope: APICaller.DataScope = .national
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Covid Cases"
        configureTable()
        createFilterButton()
        fetchData()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func createGraph(){
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.width/1.5))
        headerView.clipsToBounds = true
        
        let set = dayData.prefix(10)
        var entries: [BarChartDataEntry] = []
        for index in 0..<set.count{
            let data = set[index]
            entries.append(.init(x: Double(index), y: Double(data.count)))
            
        }
        
        let dataSet = BarChartDataSet(entries: entries )
        dataSet.colors = ChartColorTemplates.joyful()
        
        let data: BarChartData = BarChartData(dataSet: dataSet)
        
        
        let chart = BarChartView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.width/1.5))
        chart.data = data
        chart.rightAxis.enabled = false
        
        
        
        headerView.addSubview(chart)
        
        
        tableView.tableHeaderView = headerView
    }
    
    private func configureTable(){
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func fetchData(){
        APICaller.shared
            .getCovidData(for: scope) { [weak self] result in
                switch result {
                case .success(let dayData):
                    self?.dayData = dayData
                case .failure(let error):
                    print(error)
                }
            }
    }

    private func createFilterButton(){
        
        let buttonTitle: String = {
            switch scope {
            case .national:
                return "National"
            case .state(let state):
                createClearFilterButton()
                return state.name
            }
        }()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: buttonTitle, style: .done, target: self, action: #selector(didTapFilter))
    }
    
    private func createClearFilterButton(){
        let buttonTitle: String = "Clear Filter"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: buttonTitle, style: .done, target: self, action: #selector(clearFilter))
    }
    
    @objc private func clearFilter(){
        scope = .national
        fetchData()
        
        createFilterButton()
        navigationItem.leftBarButtonItem = nil
    }
    
    @objc private func didTapFilter(){
        let vc = FilterViewController()
        vc.completion = { [weak self] state in
            self?.scope = .state(state)
            self?.fetchData()
            self?.createFilterButton()
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    //MARK: Table
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = dayData[indexPath.row]
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = createText(with: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row")
       
        let vc = SingleDayViewController()
        vc.scope = scope
        vc.date = dayData[indexPath.row].date
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    private func createText(with data: DayData) -> String?{
        let dateString = DateFormatter.prettyFormatter.string(from: data.date)
        let total = Self.numberFormatter.string(from: NSNumber(value: data.count))
        return "\(dateString): \(total ?? "\(data.count)")"
    }

}

