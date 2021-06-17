//
//  SingleDayViewController.swift
//  COVID Tracker
//
//  Created by elliott kung on 2021-06-15.
//

import UIKit



class SingleDayViewController: UIViewController {
    
   
    var scope: APICaller.DataScope?
    var date: Date?

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        return table
    }()

    private var singleDayData: SingleDayData?{
        didSet{
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Single Day Data"
        fetchSingleDayData()
        setupTableView()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapClose))
        
        
    }
    
    private func fetchSingleDayData(){
        
        guard let scope = scope, let date = date else { return }
        APICaller.shared.getSingleDayData(for: scope, for: date) { [weak self] result in
            switch result {
            case .success(let singleDayData):
                self?.singleDayData = singleDayData
                //print(self?.singleDayData)
            case .failure(let error):
                print(error)
            }
        }
        
    }
    
    func setupTableView(){
        view.addSubview(tableView)
        tableView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    @objc private func didTapClose(){
        dismiss(animated: true, completion: nil)
    }
    
}

extension SingleDayViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        switch indexPath.row {
        case 0:
            if let date = date{
                let dateString = dateFormatter(date: date)
                cell.textLabel?.text = "Date: \(dateString)"
            }
            
        case 1:
            cell.textLabel?.text = "Total Cases: \(singleDayData?.total ?? 0)"
        case 2:
            cell.textLabel?.text = "Total in ICU: \(singleDayData?.icu ?? 0)"
        case 3:
            cell.textLabel?.text = "Total on Ventilator: \(singleDayData?.ventilator ?? 0)"
        case 4:
            cell.textLabel?.text = "Total Deaths: \(singleDayData?.deaths ?? 0)"
        default:
            print("unexpected case")
        }
        
        return cell
    
    }
    
    func dateFormatter(date: Date) -> String{
        let dateString = DateFormatter()
        dateString.dateFormat = "YYYY-MM-dd"
        let formatDate = dateString.string(from: date)
        
        return formatDate
    }
    
    
}
