

import UIKit
import BSImagePicker
import Photos
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI


class ViewController: UIViewController, UITextFieldDelegate {
    
    var SelectedAsssets = [PHAsset]()
    var ref: DatabaseReference!
    var messages: [DataSnapshot]! = []
    var msglength: NSNumber = 1000
    var storageRef: StorageReference!
    var remoteConfig: RemoteConfig!
    let imageCache = NSCache<NSString, UIImage>()
    var keyboardOnScreen = false
    var placeholderImage = UIImage(named: "ic_account_circle")
    fileprivate var _refHandle: DatabaseHandle!
    fileprivate var _authHandle: AuthStateDidChangeListenerHandle!
    var user: User?
    var displayName = "Anonymous"
    
    
    
    //Outlets
    
    @IBOutlet weak var fullNameLabel: UILabel!

    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var fullNameText: UITextField!
    
        @IBOutlet weak var cancelButton: UIButton!
    
   
    
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var addImageButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var mobileLabel: UILabel!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var pinLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var addressTextTwo: UITextField!
    @IBOutlet weak var addressLabeltwo: UILabel!
    @IBOutlet weak var addressTextOne: UITextField!
    @IBOutlet weak var addressLabelOne: UILabel!
    
    
    override func viewDidLoad() {
        
        configureAuth()
        myNewFunction(isVisible: true)
       
        
    }
    
    
    func configureAuth() {
        let provider: [FUIAuthProvider] = [FUIGoogleAuth()]
        FUIAuth.defaultAuthUI()?.providers = provider
        
        
        
        _authHandle = Auth.auth().addStateDidChangeListener { (auth: Auth, user: User?) in
           
            
            if let activeUser = user {
                
                
                if self.user != activeUser {
                    self.user = activeUser
                    self.signedInStatus(isSignedIn: true)
                    let name = user!.email!.components(separatedBy: "@")[0]
                    self.displayName = name
                   
                }
            } else {
                
                self.signedInStatus(isSignedIn: false)
                self.loginSession()
                
            }
        }
    }
    func configureDatabase() {
        ref = Database.database().reference()
        
        
    }
    
    
    
    func configureStorage() {
        storageRef = Storage.storage().reference()
    }
    
    func myNewFunction(isVisible: Bool){
        
        fullNameLabel.isHidden = isVisible
        fullNameText.isHidden = isVisible
        addressLabelOne.isHidden = isVisible
        addressTextOne.isHidden = isVisible
        addressLabeltwo.isHidden = isVisible
        addressTextTwo.isHidden = isVisible
        cityLabel.isHidden = isVisible
        cityTextField.isHidden = isVisible
        pinLabel.isHidden = isVisible
        pinTextField.isHidden = isVisible
        mobileLabel.isHidden = isVisible
        mobileTextField.isHidden = isVisible
        emailLabel.isHidden = isVisible
        emailTextField.isHidden = isVisible
        saveButton.isHidden = isVisible
        cancelButton.isHidden = isVisible

        
    }
    
    deinit {
        
        Auth.auth().removeStateDidChangeListener(_authHandle)
    }
    
    
    
    func configureRemoteConfig() {
        
        let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
        remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.configSettings = remoteConfigSettings!
    }
    
    func fetchConfig() {
        var expirationDuration: Double = 3600
       
        
        if remoteConfig.configSettings.isDeveloperModeEnabled {
            expirationDuration = 0
        }
        
       
        remoteConfig.fetch(withExpirationDuration: expirationDuration) { (status, error) in
            if status == .success {
                print("Config fetched!")
                self.remoteConfig.activateFetched()
                let friendlyMsgLength = self.remoteConfig["friendly_msg_length"]
                if friendlyMsgLength.source != .static {
                    self.msglength = friendlyMsgLength.numberValue!
                    print("Friendly msg length config: \(self.msglength)")
                }
            } else {
                print("Config not fetched")
                print("Error \(String(describing: error))")
            }
        }
    }

    
    func loginSession() {
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        present(authViewController, animated: true, completion: nil)
    }
    
    func subscribeToKeyboardNotifications() {
     
    }
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
            }
    
    func keyboardDidHide(_ notification: Notification) {
              keyboardOnScreen = false
    }
    
    func keyboardHeight(_ notification: Notification) -> CGFloat {
        return ((notification as NSNotification).userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.height
    }
    
    func resignTextfield() {
        if fullNameText.isFirstResponder {
            fullNameText.resignFirstResponder()
        }
        if addressTextOne.isFirstResponder {
            addressTextOne.resignFirstResponder()
        }
        if addressTextTwo.isFirstResponder {
            addressTextTwo.resignFirstResponder()
        }
        if cityTextField.isFirstResponder {
            cityTextField.resignFirstResponder()
        }
        if pinTextField.isFirstResponder {
            pinTextField.resignFirstResponder()
        }
        if mobileTextField.isFirstResponder {
           mobileTextField.resignFirstResponder()
        }
        if emailTextField.isFirstResponder {
            emailTextField.resignFirstResponder()
        }
        
    }


    
    func signedInStatus(isSignedIn: Bool) {
        signInButton.isHidden = isSignedIn
        
        signOutButton.isHidden = !isSignedIn
        addImageButton.isHidden = !isSignedIn
        profileButton.isHidden  = !isSignedIn
       
        
        if isSignedIn {
            
            subscribeToKeyboardNotifications()
            configureDatabase()
            configureStorage()
            configureRemoteConfig()
            fetchConfig()
        }
    }
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    func convertAssetToImages(){
    
        if SelectedAsssets.count != 0{
            for i in 0..<SelectedAsssets.count{
                let manager = PHImageManager.default()
                let option = PHImageRequestOptions()
                var thumbnail = UIImage()
                option.isSynchronous = true
                manager.requestImage(for: SelectedAsssets[i], targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                    thumbnail = result!
                })
                
                let data = UIImageJPEGRepresentation(thumbnail, 0.8)
                sendPhotoMessage(photoData: data!)
            }
        }
    
    }

    func sendPhotoMessage(photoData: Data) {
               let imagePath = "chat_photos/" + Auth.auth().currentUser!.displayName! + "/\(Double(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
       
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
               storageRef!.child(imagePath).putData(photoData, metadata: metadata) { (metadata, error) in
            if let error = error {
                print("Error uploading: \(error)")
                return
            }
                        self.sendMessage(data: [Constants.UserDetailFields.imageUrl: self.storageRef!.child((metadata?.path)!).description])
            self.showAlert(title: "Success!", message: "Images are saved successfully!")
        }
    }

    
    //Action:


    @IBAction func signInPressed(_ sender: Any) {
        configureAuth()
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        myNewFunction(isVisible: true)
        
        do{
            try Auth.auth().signOut()
        }
        catch{
            print("Error in sign out")
        }
    }
    @IBAction func showImagePicker(_ sender: UIButton) {
        myNewFunction(isVisible: true)
        
        let vc = BSImagePickerViewController()
        
        bs_presentImagePickerController(vc, animated: true,
            select: { (asset: PHAsset) -> Void in
                
            }, deselect: { (asset: PHAsset) -> Void in
                
            }, cancel: { (assets: [PHAsset]) -> Void in
                           }, finish: { (assets: [PHAsset]) -> Void in
                self.SelectedAsssets.removeAll()
                for i in 0..<assets.count{
                    self.SelectedAsssets.append(assets[i])
                }
                self.convertAssetToImages()
            }, completion: nil)
        
    }
    
    @IBAction func profileButtonPressed(_ sender: Any) {
        
        myNewFunction(isVisible: false)
        
        
    }
    @IBAction func saveButtonPressed(_ sender: Any) {
        if !fullNameText.text!.isEmpty && !addressTextOne.text!.isEmpty && !addressTextTwo.text!.isEmpty && !cityTextField.text!.isEmpty && !pinTextField.text!.isEmpty && !mobileTextField.text!.isEmpty && !emailTextField.text!.isEmpty {
            let data = [Constants.UserDetailFields.full_name: fullNameText.text! as String]
            sendMessage(data: data)
            fullNameText.resignFirstResponder()
            addressTextOne.resignFirstResponder()
            addressTextTwo.resignFirstResponder()
            cityTextField.resignFirstResponder()
            pinTextField.resignFirstResponder()
            mobileTextField.resignFirstResponder()
            emailTextField.resignFirstResponder()
            showAlert(title: "Done", message: "Your details were saved successfully!")
        }
        else{
            showAlert(title: "Alert!", message: "All text fields are compulsory, enter full information and then try again")
        }

    }
    func sendMessage(data: [String:String]) {
        var mdata = data
                mdata[Constants.UserDetailFields.username] = displayName
        mdata[Constants.UserDetailFields.address1] = addressTextOne.text! as String
        mdata[Constants.UserDetailFields.address2] = addressTextTwo.text! as String
        mdata[Constants.UserDetailFields.city] = cityTextField.text! as String
        mdata[Constants.UserDetailFields.pin] = pinTextField.text! as String
        mdata[Constants.UserDetailFields.mobile] = mobileTextField.text! as String
        mdata[Constants.UserDetailFields.email] = emailTextField.text! as String
        ref.child("User Details").childByAutoId().setValue(mdata)
    }

    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        myNewFunction(isVisible: true)
        
    }
    
}
