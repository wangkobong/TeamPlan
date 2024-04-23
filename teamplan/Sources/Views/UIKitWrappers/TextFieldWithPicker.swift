//
//  TextFieldWithPicker.swift
//  teamplan
//
//  Created by sungyeon kim on 4/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import UIKit
import SwiftUI

struct TextFieldWithInputView : UIViewRepresentable {
    
    var data : [String]
    var placeholder : String
    var textColor: UIColor
    var placeholderColor: UIColor
    
    @Binding var selectionIndex : Int
    @Binding var selectedText : String?
    
    private let textField = UITextField()
    private let picker = UIPickerView()
    
    func makeCoordinator() -> TextFieldWithInputView.Coordinator {
        Coordinator(textfield: self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<TextFieldWithInputView>) -> UITextField {
        if data.isEmpty {
             // data 배열이 비어 있으면 빈 UITextField를 반환
            textField.isUserInteractionEnabled = false
            textField.placeholder = "보유한 물방울이 없습니다."
             return textField
         } else {
             // data 배열이 비어 있지 않으면 픽커뷰를 생성하여 반환
             picker.delegate = context.coordinator
             picker.dataSource = context.coordinator
             picker.backgroundColor = .gray
             picker.tintColor = textColor
             textField.placeholder = placeholder
             textField.inputView = picker
             textField.delegate = context.coordinator
             textField.textColor = textColor
             let placeholderAttributes: [NSAttributedString.Key: Any] = [
                 .foregroundColor: placeholderColor,
             ]
             textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: placeholderAttributes)
             return textField
         }
    }
    
    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<TextFieldWithInputView>) {
        uiView.text = selectedText
    }
    
    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate , UITextFieldDelegate {
        
        private let parent : TextFieldWithInputView
        
        init(textfield : TextFieldWithInputView) {
            self.parent = textfield
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return self.parent.data.count
        }
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return self.parent.data[row]
        }
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            self.parent.$selectionIndex.wrappedValue = row
            self.parent.selectedText = self.parent.data[self.parent.selectionIndex]
            self.parent.textField.endEditing(true)
            
        }
        func textFieldDidEndEditing(_ textField: UITextField) {
            self.parent.textField.resignFirstResponder()
        }
    }
}
