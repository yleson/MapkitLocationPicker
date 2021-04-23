//
//  ViewController.swift
//  LocationPicker
//
//  Created by yleson on 2021/4/23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let pickerVc = MapLocationPickerController()
        pickerVc.complete = { result in
            print(result)
        }
        self.navigationController?.pushViewController(pickerVc, animated: true)
    }

}

