import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func refreshQR() {
        label.setHidden(false)
        QRImage.setHidden(true)
        label.setText(NSLocalizedString("Updating...\nThis may take some time depending on Fudan servers.\nNote: Your watch must be connected to your iPhone.", comment: "Updating"))
        sendString(text: "refresh")
    }
    
    func sendString(text: String){
        let session = WCSession.default;
        if(session.isReachable){
         DispatchQueue.main.async {
                session.sendMessage(["qr_text": text], replyHandler: nil)
            }
        }else{
            label.setText(NSLocalizedString("iPhone Unreachable.", comment: "iPhone Unreachable"))
        }
    }
    
    @IBOutlet var label: WKInterfaceLabel!
    @IBOutlet weak var QRImage: WKInterfaceImage!
    @IBAction func tapRecognizer(_ sender: Any) {
        refreshQR()
    }
    @IBAction func tapRecognizerLabel(_ sender: Any) {
        tapRecognizer(sender)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if(WCSession.isSupported()){
         let session = WCSession.default;
         session.delegate = self;
         session.activate();
        }
        
        label.setText(NSLocalizedString("Connecting...", comment: "Connecting"))
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        refreshQR()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        //self.label.setText(message["qr_text"] as! String)
        if let image = EFQRCode.generate(content: message["qr_text"] as! String) {
            QRImage.setImage(UIImage(cgImage: image))
            label.setHidden(true)
            QRImage.setHidden(false)
        }
        else {
            label.setText(NSLocalizedString("Failed to generate QR. Please file bug report.", comment: "Failed to generate QR. Please file bug report."))
        }
    }

}
