//
//  MapLocationPoiCell.swift
//  LocationPicker
//
//  Created by yleson on 2021/4/23.
//

import UIKit

class MapLocationPoiCell: UITableViewCell {

    lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.black
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        return nameLabel
    }()
    lazy var contentLabel: UILabel = {
        let contentLabel = UILabel()
        contentLabel.textColor = UIColor.lightGray
        contentLabel.font = UIFont.systemFont(ofSize: 12)
        return contentLabel
    }()
    lazy var stateView: UIButton = {
        let stateView = UIButton()
        stateView.isUserInteractionEnabled = false
        stateView.setImage(UIImage(named: "common_checkbox_circle_black_normal"), for: .normal)
        stateView.setImage(UIImage(named: "common_checkbox_circle_black_selected"), for: .selected)
        return stateView
    }()
    lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        return lineView
    }()
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = UIView()
        
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.contentLabel)
        self.contentView.addSubview(self.stateView)
        self.contentView.addSubview(self.lineView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.nameLabel.frame = CGRect(x: 20, y: 16, width: self.bounds.width - 76, height: 22)
        self.contentLabel.frame = CGRect(x: 20, y: 48, width: self.bounds.width - 76, height: 17)
        self.stateView.frame = CGRect(x: self.bounds.width - 38, y: 32, width: 18, height: 18)
        self.lineView.frame = CGRect(x: 20, y: 81, width: self.bounds.width - 40, height: 1)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        self.stateView.isSelected = selected
    }

}
