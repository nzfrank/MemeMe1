//
//  ViewController.swift
//  MemeMe1
//
//  Created by Frank Feng on 22/01/20.
//  Copyright © 2020 vend. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

extension Notification.Name {
    public static var RelocateTextfield = Notification.Name.init("RelocateTextfield")
}

class ViewController: UIViewController, UINavigationControllerDelegate {

    // MARK: TopToolBarItems
    private var topToolBar = UIToolbar()
    let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    private lazy var shareButton: UIBarButtonItem = {
        let b = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareMemedImage))
        b.style = .plain
        return b
    }()
    private lazy var cancelButton: UIBarButtonItem = {
        let b = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelEdit))
        b.style = .plain
        return b
    }()
    
    // MARK: BottomToolBarItems
    private var bottomToolBar = UIToolbar()
    private lazy var pickButtom: UIBarButtonItem = {
        let b = UIButton(frame: .zero)
        b.setTitle("Album", for: .normal)
        b.setTitleColor(.blue, for: .normal)
        b.addTarget(self, action: #selector(pickAnImageFromAlbum), for: .touchUpInside)
        let bi = UIBarButtonItem(customView: b)
        bi.style = .plain
        return bi
    }()
    
    private var cameraButton: UIBarButtonItem = {
        let b = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(pickAnImageFromCamera))
        b.style = .plain
        return b
    }()
    
    // MARK: ImageViewItems
    private var imageView: UIImageView = {
        let i = UIImageView(frame: .zero)
        i.backgroundColor = .black
        return i
    }()
    private lazy var textStackView: UIStackView = {
      let stack = UIStackView(frame: .zero)
      stack.alignment = .center
        stack.axis = .vertical
      stack.spacing = 5
      stack.distribution = .equalSpacing
      return stack
    }()
    private var topTextField = UITextField()
    private var bottomTextField = UITextField()
    private let topTextFieldPlaceHolder = "TOP"
    private let bottomTextFieldPlaceHolder = "BOTTOM"
    
    // MARK: ToolBarConstraints
    private var topToolBarHeightConstraint: Constraint?
    private var bottomToolBarHeightConstraint: Constraint?
    
    private var keyboardHeight: CGFloat = 0
    
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor: UIColor.white,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key.strokeWidth: 5
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTextField(topTextField)
        setTextField(bottomTextField)
        setToolBar(toolBar: topToolBar, items: [shareButton, flexibleSpace, cancelButton])
        setToolBar(toolBar: bottomToolBar, items: [flexibleSpace, cameraButton, flexibleSpace, pickButtom, flexibleSpace])
        updateShareButton()
        view.backgroundColor = .white
        
        view.addSubview(topToolBar)
        view.addSubview(imageView)
        view.addSubview(bottomToolBar)
        view.addSubview(textStackView)
        
        textStackView.addArrangedSubview(topTextField)
        textStackView.addArrangedSubview(bottomTextField)
        
        topToolBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            topToolBarHeightConstraint = make.height.equalTo(0).constraint
        }
        
        bottomToolBar.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            bottomToolBarHeightConstraint = make.height.equalTo(0).constraint
        }
        
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(topToolBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomToolBar.snp.top)
        }
        
        textStackView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(imageView)
        }
        
        showToolBars()
    }

    override func viewWillAppear(_ animated: Bool) {
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        subscribeToTextfieldNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    private func setToolBar(toolBar: UIToolbar, items: [UIBarButtonItem]) {
        toolBar.setItems(items, animated: false)
        toolBar.sizeToFit()
        toolBar.center = CGPoint(x: view.frame.width/2, y: 0)
        toolBar.backgroundColor = .darkGray
    }
    
    func subscribeToTextfieldNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(relocateTextfield), name: .RelocateTextfield, object: nil)
    }
    
    func subscribeToKeyboardNotifications() {

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func unsubscribeFromAllNotifications() {
        /// Remove all the observers
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        self.keyboardHeight = getKeyboardHeight(notification)
    }
    
    @objc func relocateTextfield() {
        if view.frame.origin.y >= 0 {
            view.frame.origin.y -= self.keyboardHeight
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        view.frame.origin.y = 0
    }

    func getKeyboardHeight(_ notification:Notification) -> CGFloat {

        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }

    private func setTextField(_ textField: UITextField) {
        if textField == topTextField {
            textField.text = topTextFieldPlaceHolder
        } else {
            textField.text = bottomTextFieldPlaceHolder
        }
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .center
        textField.delegate = self
        textField.autocapitalizationType = .allCharacters
        textField.borderStyle = .none
    }
    
    @objc func pickAnImageFromAlbum(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true, completion: nil)
    }
    
    @objc func pickAnImageFromCamera(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .camera
        pickerController.showsCameraControls = true
        present(pickerController, animated: true, completion: nil)
    }
    
    func generateMemedImage() -> UIImage {

        // Hide toolbars
        hideToolBars()

        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        // Show toolbars
        showToolBars()

        return memedImage
    }
    
    func showToolBars() {
        self.topToolBar.isHidden = false
        self.bottomToolBar.isHidden = false
        topToolBarHeightConstraint?.deactivate()
        bottomToolBarHeightConstraint?.deactivate()
    }
    
    func hideToolBars() {
        self.topToolBar.isHidden = true
        self.bottomToolBar.isHidden = true
        topToolBarHeightConstraint?.activate()
        bottomToolBarHeightConstraint?.activate()
    }
    
    func save(_ memedImage: UIImage) {
        // Create the meme
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imageView.image!, memedImage: memedImage)
    }
    
    @objc func shareMemedImage() {
        let memedImage = generateMemedImage()
        let v = UIActivityViewController.init(activityItems: [memedImage], applicationActivities: nil)
        v.completionWithItemsHandler = { [weak self]
            (activity, success, items, error) in
            guard let this = self else { return }
            if success == true, let image = items?[0] as? UIImage{
                this.save(image)
            }
        }
        present(v, animated: true)
    }
    
    func updateShareButton() {
        if let _ = imageView.image {
            shareButton.isEnabled = true
        } else {
            shareButton.isEnabled = false
        }
    }
    
    @objc func cancelEdit() {
        /// Reset everything
        imageView.image = nil
        topTextField.text = topTextFieldPlaceHolder
        bottomTextField.text = bottomTextFieldPlaceHolder
        updateShareButton()
    }
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == topTextFieldPlaceHolder || textField.text == bottomTextFieldPlaceHolder {
            textField.text = ""
        }
        if textField == bottomTextField {
            NotificationCenter.default.post(.init(name: .RelocateTextfield))
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text == "" {
            if textField == topTextField {
                textField.text = topTextFieldPlaceHolder
            } else {
                textField.text = bottomTextFieldPlaceHolder
            }
        }
        return view.endEditing(true)
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
        }
        updateShareButton()
        picker.dismiss(animated: true, completion: nil)
    }
}
