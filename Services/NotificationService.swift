import Foundation
import UserNotifications
import Firebase

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var hasPermission = false
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkPermission()
    }
    
    func checkPermission() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                
                if granted {
                    self?.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // Schedule local notification
    func scheduleMatchReminder(matchID: String, matchTitle: String, date: Date) {
        // Only proceed if we have permission
        guard hasPermission else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Match Reminder"
        content.body = "Your match \(matchTitle) is starting soon!"
        content.sound = .default
        content.userInfo = ["matchID": matchID]
        
        // Create a trigger - 1 hour before the match
        let triggerDate = date.addingTimeInterval(-3600)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "match-reminder-\(matchID)",
            content: content,
            trigger: trigger
        )
        
        // Add request to notification center
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelMatchReminder(matchID: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["match-reminder-\(matchID)"])
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification interaction
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification types
        if let matchID = userInfo["matchID"] as? String {
            // Navigate to match screen - would be handled by app coordinator
            print("Should navigate to match: \(matchID)")
        }
        
        completionHandler()
    }
    
    // In a real app, this would receive and process remote notifications from Firebase Cloud Messaging
    func processFCMNotification(userInfo: [AnyHashable: Any]) {
        // Parse notification data
        // Update app state based on notification type
        
        if let matchID = userInfo["matchID"] as? String,
           let notificationType = userInfo["type"] as? String {
            
            switch notificationType {
            case "new_pairing":
                print("New pairing for match: \(matchID)")
                // Update local state
                
            case "match_completion":
                print("Match completed: \(matchID)")
                // Update local state
                
            case "score_submission":
                print("New score submitted for match: \(matchID)")
                // Update local state
                
            default:
                break
            }
        }
    }
} 