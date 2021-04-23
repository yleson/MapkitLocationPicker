# MapkitLocationPicker
地图定位选择

```swift
let pickerVc = MapLocationPickerController()
pickerVc.complete = { result in
    print(result)
}
self.navigationController?.pushViewController(pickerVc, animated: true)
```
![image](https://user-images.githubusercontent.com/39610531/166881300-cfad2fd7-580f-4bc9-8ba3-c71ac031567f.png)
![image](https://user-images.githubusercontent.com/39610531/166881506-5e905378-0cee-40cf-b18e-f3a7b1a98533.png)

