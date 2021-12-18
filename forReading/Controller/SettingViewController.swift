//
//  SettingViewController.swift
//  forReading
//
//  Created by kashiwa-gohan on 2021/12/18.
//

import Cocoa
import RealmSwift
import OSLog

//設定画面のViewController
class SettingViewController: NSViewController {
    
    static let osLog = OSLog(subsystem: "forReading", category: "SettingViewController")
    var allSettings: Results<Settings>!
    var allGrades: Results<Grades>!
    let defaultNumber: Int = 10
    var selectedNumber: Int = 10
    //csvファイルの設置場所
    var dir_path = "\(NSHomeDirectory())/Desktop/forReading/text/"
    
    @IBOutlet weak var numOfQuestions: NSPopUpButtonCell!
    
    //SettingViewController起動時の処理を実行する
    override func viewDidLoad() {
        os_log(.info, log: SettingViewController.osLog, "【設定画面の起動】")
        
        do {
            let realm = try Realm()
            
            //データを全て削除する（デバッグ用）
            /*
            try realm.write {
                realm.deleteAll()
            }
            */
            
            //データベースから、設定を全件取得する
            self.allSettings = realm.objects(Settings.self)
            
            //設定が0件の場合、サンプルを登録する
            if(self.allSettings.count == 0) {
                let sampleSettings = sampleSetSettings()
                try realm.write {
                    realm.add(sampleSettings)
                }
            }
            
            self.allSettings = realm.objects(Settings.self)
            os_log(.debug, log: SettingViewController.osLog, "登録済みの設定：\(self.allSettings.count)個")
            
            //出題件数を表示する
            numOfQuestions.title = String(self.allSettings[0].numOfQuestions)
            self.selectedNumber = self.allSettings[0].numOfQuestions

            //データベースから、過去の成績を全件取得する
            self.allGrades = realm.objects(Grades.self)
            
            //過去の成績が0件の場合、サンプルを登録する
            if(self.allGrades.count == 0) {
                let sampleGrades = sampleSetGrades()
                try realm.write {
                    realm.add(sampleGrades)
                }
            }
            
            self.allGrades = realm.objects(Grades.self)
            os_log(.debug, log: SettingViewController.osLog, "登録済みの過去の成績：\(self.allGrades.count)個")
            
            super.viewDidLoad()

        } catch {
            os_log(.error, log: SettingViewController.osLog, "設定の取得に失敗しました。")
        }
    }
    
    //戻るボタンをクリックした時、segueを実行する
    @IBAction func backBtnClicked(_ sender: NSButton) {
        performSegue(withIdentifier: "SettingToStart", sender: nil)
    }
    
    //出題件数を変更した時、データベースを更新する
    @IBAction func selectNumOfQ(_ sender: NSPopUpButton) {
        let changedNumber: Int = Int(self.numOfQuestions.title)!
        os_log(.debug, log: SettingViewController.osLog, "変更前の出題件数：\(self.selectedNumber)")
        os_log(.debug, log: SettingViewController.osLog, "変更後の出題件数：\(changedNumber)")
        
        if (self.selectedNumber != changedNumber) {
            do {
                let realm = try Realm()
                try realm.write {
                    self.allSettings[0].numOfQuestions = changedNumber
                    self.allSettings[0].updatedDate = Date()
                    self.selectedNumber = changedNumber
                }
            } catch {
                os_log(.error, log: SettingViewController.osLog, "出題件数の変更に失敗しました。")
            }
        }
    }
    
    @IBAction func resultsBtnClick(_ sender: Any) {
    }
    
    //ファイル入力をクリックした時
    @IBAction func inputBtnClicked(_ sender: NSButton) {
        
        //指定したファイルを読み込む
        inputFiles()
    }
    
    //segue実行前処理
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        //segueの実行をStartViewControllerに通知する
        if segue.identifier == "SettingToStart" {
            _ = segue.destinationController as! StartViewController
        }
    }
    
    //設定のサンプルデータをセットする
    func sampleSetSettings() -> Settings {
        let sample = Settings()
        
        sample.numOfQuestions = self.defaultNumber
        sample.createdDate = Date()
        sample.updatedDate = Date()
        
        return sample
    }
    
    //過去の成績のサンプルデータをセットする
    func sampleSetGrades() -> Grades {
        let sample = Grades()
        let answer = Answered()
        
        answer.question = "あいう"
        answer.trueOrfalse = true
        sample.results.append(answer)
        sample.answeredDate = Date()
        
        return sample
    }
    
    //指定したファイルを読み込む
    func inputFiles() {
        
        let openPanel = NSOpenPanel()
        //ファイルの選択を許可する
        openPanel.canChooseFiles = true
        //ディレクトリの選択を許可する
        openPanel.canChooseDirectories = false
        //複数のファイルの選択を許可する
        openPanel.allowsMultipleSelection = true
        //選択画面のタイトルを設定する
        openPanel.message = "ひらがな、カタカナのファイルを選択してください。"
        //選択可能なファイルの拡張子を設定する
        openPanel.allowedFileTypes = ["txt"]
        
        //ファイル選択画面を開く
        openPanel.begin(completionHandler: {(response) -> Void  in
            switch response {
            case NSApplication.ModalResponse.OK:
                //テキストファイルから名詞を抽出するクラスを呼び出す
                InputWords().callAnalyze(urls: openPanel.urls)
            default:
                break
            }
        })
    }
}
