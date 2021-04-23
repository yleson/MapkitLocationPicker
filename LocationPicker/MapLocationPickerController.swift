//
//  MapLocationPickerController.swift
//  LocationPicker
//
//  Created by yleson on 2021/4/23.
//  地图选择定位

import UIKit
import MapKit

class MapLocationPickerController: UIViewController, UITextFieldDelegate {
    
    /// 是否开启用户定位点
    public var isShowUserLocation: Bool = false
    /// 是否回到用户定位点
    private var isReturnUserLocation: Bool = true
    /// 选择回调
    public var complete: (([String: Any]) -> Void)?
    
    /// 用户定位
    private lazy var location: CLLocationManager = {
        let location = CLLocationManager()
        location.delegate = self
        location.requestAlwaysAuthorization()
        location.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        location.distanceFilter = kCLLocationAccuracyNearestTenMeters
        return location
    }()
    /// 地图
    private lazy var mainMapView: MKMapView = {
        let mainMapView = MKMapView()
        mainMapView.delegate = self
        mainMapView.isRotateEnabled = false
        return mainMapView
    }()
    
    /// 记录经纬度
    private var longitude: Double = 0
    private var latitude: Double = 0
    
    /// 是否跳过当前检索
    private var isSkipPoi: Bool = true
    /// POI
    private lazy var poiRequest: MKLocalSearch.Request = {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "生活服务"
        return request
    }()
    private var poiResult: [CLPlacemark] = [] {
        didSet {
            self.poiTableView.isHidden = self.poiResult.isEmpty
            self.poiTableView.reloadData()
        }
    }
    /// 位置解析
    private lazy var geoCoder: CLGeocoder = {
        let geoCoder = CLGeocoder()
        return geoCoder
    }()
    /// 列表
    private lazy var poiTableView: UITableView = {
        let poiTableView = UITableView()
        poiTableView.isHidden = true
        poiTableView.backgroundColor = UIColor.white
        poiTableView.separatorStyle = .none
        poiTableView.rowHeight = 82
        poiTableView.register(MapLocationPoiCell.self, forCellReuseIdentifier: String(describing: MapLocationPoiCell.self))
        poiTableView.delegate = self
        poiTableView.dataSource = self
        poiTableView.layer.cornerRadius = 10
        poiTableView.layer.masksToBounds = true
        return poiTableView
    }()
    /// 确定按钮
    private lazy var confirmButton: UIButton = {
        let confirmButton = UIButton()
        confirmButton.isEnabled = false
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(UIColor.black, for: .normal)
        confirmButton.setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .disabled)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        confirmButton.addTarget(self, action: #selector(confirmDidClick), for: .touchUpInside)
        return confirmButton
    }()
    /// 回到定位按钮
    private lazy var returnLocationButton: UIButton = {
        let returnLocationButton = UIButton()
        returnLocationButton.backgroundColor = UIColor.white
        returnLocationButton.setImage(UIImage(named: "location_picker_return"), for: .normal)
        returnLocationButton.addTarget(self, action: #selector(returnUserLocationDidClick), for: .touchUpInside)
        returnLocationButton.layer.cornerRadius = 27
        returnLocationButton.layer.masksToBounds = true
        return returnLocationButton
    }()
    /// 搜索框
    private lazy var searchField: UITextField = {
        let searchField = UITextField()
        searchField.placeholder = "请输入您的定位"
        searchField.textColor = UIColor.black
        searchField.font = UIFont.systemFont(ofSize: 13)
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .whileEditing
        searchField.delegate = self
        return searchField
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "定位选择"
        // 开始定位
        self.location.startUpdatingLocation()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.confirmButton)
        
        let kNavigateHeight = UIApplication.shared.statusBarFrame.size.height + 44
        self.mainMapView.frame = CGRect(x: 0, y: -kNavigateHeight, width: self.view.bounds.width, height: UIScreen.main.bounds.height + kNavigateHeight)
        self.view.addSubview(self.mainMapView)
        
        let contentView = UIView(frame: CGRect(x: 0, y: kNavigateHeight, width: self.view.bounds.width, height: 52))
        contentView.backgroundColor = .white
        self.view.addSubview(contentView)
        let searchContentView = UIView(frame: CGRect(x: 16, y: 8, width: contentView.bounds.width - 32, height: contentView.bounds.height - 16))
        searchContentView.backgroundColor = .black.withAlphaComponent(0.04)
        searchContentView.layer.cornerRadius = 2
        searchContentView.layer.masksToBounds = true
        contentView.addSubview(searchContentView)
        let iconView = UIImageView(image: UIImage(named: "common_search_lightgray"))
        iconView.frame = CGRect(x: 10, y: 9, width: 18, height: 18)
        searchContentView.addSubview(iconView)
        self.searchField.frame = CGRect(x: 36, y: 0, width: searchContentView.bounds.width - 52, height: searchContentView.bounds.height)
        searchContentView.addSubview(self.searchField)
        
        let height: CGFloat = (UIScreen.main.bounds.height - kNavigateHeight) * 0.44
        self.poiTableView.frame = CGRect(x: 10, y: UIScreen.main.bounds.height - height, width: self.view.bounds.width - 20, height: height)
        self.view.addSubview(self.poiTableView)
        
        let annotationView = UIImageView(image: UIImage(named: "map_annotation_pin"))
        annotationView.frame = CGRect(x: self.mainMapView.frame.midX - 20, y: self.mainMapView.frame.midY - 20, width: 40, height: 40)
        self.view.addSubview(annotationView)
        
        self.returnLocationButton.frame = CGRect(x: self.view.bounds.width - 70, y: self.poiTableView.frame.minY - 78, width: 54, height: 54)
        self.view.addSubview(self.returnLocationButton)
    }
    
    
    // 点击确定
    @objc func confirmDidClick() {
        guard let indexPath = self.poiTableView.indexPathForSelectedRow else {return}
        let place = self.poiResult[indexPath.row]
        complete?(["title": place.name, "thoroughfare": place.thoroughfare, "longitude": place.location?.coordinate.longitude, "latitude": place.location?.coordinate.latitude])
        self.navigationController?.popViewController(animated: true)
    }
    
    // 返回用户定位点
    @objc func returnUserLocationDidClick() {
        // 获取不到位置返回
        guard let currentCoordinate = self.location.location?.coordinate else {return}
        
        self.isReturnUserLocation = true
        self.mainMapView.setCenter(self.transform(coordinate: currentCoordinate, isSave: false), animated: true)
    }
    
    
    // POI检索
    func poiSearch() {
        // 如果需要跳过搜索
        guard !self.isSkipPoi else {
            self.isSkipPoi = false
            return
        }
        
        // 当前位置
        let currentLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        // 记录搜索结果
        var currentResult: [CLPlacemark] = []
        
        let workingGroup = DispatchGroup()
        let workingQueue = DispatchQueue.global()
        
        workingGroup.enter()
        workingQueue.async {
            // 1.poi检索周边
            let region = MKCoordinateRegion(center: currentLocation.coordinate, span: self.mainMapView.region.span)
            self.poiRequest.region = region
            let poi = MKLocalSearch(request: self.poiRequest)
            poi.start { response, error in
                if error == nil, let response = response, !response.mapItems.isEmpty {
                    currentResult.append(contentsOf: response.mapItems.compactMap({ $0.placemark }))
                }
                workingGroup.leave()
                
            }
        }
        
        workingGroup.enter()
        workingQueue.async {
            // 2.当前经纬度逆解析，放在第一个
            self.geoCoder.reverseGeocodeLocation(currentLocation) { result, error in
                if error == nil, let current = result?.first {
                    currentResult.insert(current, at: 0)
                }
                workingGroup.leave()
            }
        }
        
        workingGroup.notify(queue: workingQueue) {
            DispatchQueue.main.async {
                self.poiResult = currentResult
                // 自动选中第一个
                self.poiTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            }
        }
    }
    
    // 坐标转换处理偏移
    func transform(isTransform: Bool = true, coordinate: CLLocationCoordinate2D, isSave: Bool = true) -> CLLocationCoordinate2D {
        let gcj = isTransform ? CoordinateTransform.transformWGSToGCJ(wgsLocation: coordinate) : coordinate
        if isSave {
            self.longitude = gcj.longitude
            self.latitude = gcj.latitude
        }
        return gcj
    }
    
    // 获取地图范围
    func getRegion(coordinate: CLLocationCoordinate2D, delta: Double = 0.005) -> MKCoordinateRegion {
        return MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta))
    }
    
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let keyword = textField.text, !keyword.isEmpty {
            // 通过关键字搜索地址，不主动移动到搜索点
            self.geoCoder.geocodeAddressString(keyword) { result, error in
                if error == nil, let result = result {
                    self.poiResult = result.compactMap({ $0 })
                    self.view.endEditing(true)
                }
            }
        }
        return true
    }
}


extension MapLocationPickerController: CLLocationManagerDelegate {
    
    /// 更新定位
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let first = locations.first else {return}
        self.longitude = first.coordinate.longitude
        self.latitude = first.coordinate.latitude
        let region = MKCoordinateRegion(center: first.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        self.mainMapView.setRegion(region, animated: true)
    }
}


extension MapLocationPickerController: MKMapViewDelegate {
    
    /// 更新地图定位
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard self.isReturnUserLocation else {return}
        self.isReturnUserLocation = false
        self.mainMapView.setRegion(self.getRegion(coordinate: self.transform(isTransform: false, coordinate: userLocation.coordinate)), animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.poiSearch()
        }
    }
    
    /// 改变显示位置
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let _ = self.transform(isTransform: false, coordinate: mapView.centerCoordinate)
        self.poiSearch()
    }
}


extension MapLocationPickerController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.poiResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MapLocationPoiCell.self)) as? MapLocationPoiCell ?? MapLocationPoiCell()
        if indexPath.row < self.poiResult.count {
            if let thoroughfare = self.poiResult[indexPath.row].thoroughfare {
                cell.nameLabel.text = self.poiResult[indexPath.row].name
                cell.contentLabel.text = thoroughfare
            } else {
                cell.nameLabel.text = "[位置]"
                cell.contentLabel.text = self.poiResult[indexPath.row].name
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < self.poiResult.count, let coordinate = self.poiResult[indexPath.row].location?.coordinate else {return}
        self.confirmButton.isEnabled = true
        self.isSkipPoi = true
        let region = MKCoordinateRegion(center: coordinate, span: self.mainMapView.region.span)
        self.mainMapView.setRegion(region, animated: true)
    }
}
