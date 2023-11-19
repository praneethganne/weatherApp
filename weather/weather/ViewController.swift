//
//  ViewController.swift
//  weather
//
//  Created by Praneeth Ganne on 2023-11-17.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var locationSearch: UITextField!
    @IBOutlet weak var weatherLocation: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var toggleTitle: UIButton!
    
    var result: apiResponse?
    
    var isFahrenheit: Bool = false
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationSearch.delegate = self
        // Do any additional setup after loading the view.
    }
    
    @IBAction func toggleSwitch(_ sender: UIButton) {
        isFahrenheit.toggle()
        updateTemperatureUnitButtonTitle()
        updateTemperatureLabel()
    }
    
    func updateTemperatureLabel() {
        if let temperature = isFahrenheit ? result?.current.temp_f : result?.current.temp_c {
            temperatureLabel.text = "\(temperature)°" + (isFahrenheit ? "F" : "C")
        }
    }
    
    func updateTemperatureUnitButtonTitle() {
        let unitTitle = isFahrenheit ? "To Celsius" : "To Fahrenheit"
        toggleTitle.setTitle(unitTitle, for: .normal)
    }
    
    @IBAction func arrowLocation(_ sender: UIButton) {
        locationManager.stopUpdatingLocation()
        
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestAlwaysAuthorization()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationValue = manager.location?.coordinate else { return }
        getWeather(search: "\(locationValue.latitude),\(locationValue.longitude)")
        
    }
    
    @IBAction func searchBar(_ sender: UIButton) {
        getWeather(search: locationSearch.text)
    }
    
    func getWeather(search: String?) {
        guard let search = search, let url = getUrl(query: search) else {
            return
        }
        
        let urlSession = URLSession.shared
        
        let dataTask = urlSession.dataTask(with: url) { data, response, error in
            guard let data = data else {
                return
            }
            
            if let apiResponse = self.parseJson(data: data) {
                self.result = apiResponse
                self.setWeatherImageFor(code: apiResponse.current.condition.code, on: self.weatherImage)
                
                DispatchQueue.main.async {
                    
                    self.weatherLocation.text = apiResponse.location.name
                    self.temperatureLabel.text = "\(apiResponse.current.temp_c)°C"
                }
            }
        }
        
        dataTask.resume()
        
    }
    
    func getWeatherImageFor(code: Int) -> UIImage? {
        let config = UIImage.SymbolConfiguration.preferringMulticolor()
        
        switch code {
        case 1000: return UIImage(systemName: "sun.max.fill", withConfiguration: config)
        case 1003: return UIImage(systemName: "cloud.sun.fill", withConfiguration: config)
        case 1006, 1030: return UIImage(systemName: "cloud.fill")
        case 1009, 1135: return UIImage(systemName: "smoke.fill", withConfiguration: config)
        case 1063, 1087, 1150...1276: return UIImage(systemName: "cloud.bolt.rain.fill", withConfiguration: config)
        case 1066, 1072, 1147, 1168, 1171, 1210...1282: return UIImage(systemName: "snowflake")
        default: return UIImage(systemName: "cloud.bolt.rain.fill", withConfiguration: config)
        }
    }
    
    func setWeatherImageFor(code: Int, on imageView: UIImageView) {
        guard let weatherImage = getWeatherImageFor(code: code) else { return }
        
        DispatchQueue.main.async {
            imageView.image = weatherImage
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        getWeather(search: locationSearch.text)
        textField.endEditing(true)
        return true
    }
    
    private func getUrl(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/current.json?key=13c1c685a3a74754bab182229232003"
        guard let url = "\(baseUrl)&q=\(query)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: url)
    }
    
    func parseJson(data: Data) -> apiResponse? {
        let decoder = JSONDecoder()
        var weather: apiResponse?
        do {
            weather = try decoder.decode(apiResponse.self, from: data)
        } catch {
            print("Error decoding api response: \(error)")
        }
        return weather
    }
}

struct apiResponse: Decodable {
    let location: Location
    let current: Weather
}

struct weatherConditions: Decodable {
    let code: Int
    let text: String
    let icon: String
}

struct Location: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let condition: weatherConditions
}
