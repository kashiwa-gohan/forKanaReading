//
//  StartViewController.swift
//  forReading
//
//  Created by kashiwa-gohan on 2021/12/18.
//

import Cocoa
import RealmSwift
import OSLog

//スタート画面のViewController
class StartViewController: NSViewController {

    static let osLog = OSLog(subsystem: "forReading", category: "StartViewController")
    var allSettings: Results<Settings>!
    let defaultNumber: Int = 10
    var allWords: Results<Words>!
    
    //StartViewController起動時の処理を実行する
    override func viewDidLoad() {
        os_log(.info, log: StartViewController.osLog, "【スタート画面の起動】")
        
        do {
            //Modelに対応するRealmファイルを再作成する
            let config = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
            Realm.Configuration.defaultConfiguration = config
            os_log(.debug, log: StartViewController.osLog, "Realmファイルの場所：\(Realm.Configuration.defaultConfiguration.fileURL!)")
            
            let realm = try Realm()
            
            //データを全て削除する（デバッグ用）
            /*
            try realm.write {
                realm.deleteAll()
            }
            */
            
            //データベースから設定を取得する
            self.allSettings = realm.objects(Settings.self)

            //設定が0件の場合、サンプルを登録する
            if(self.allSettings.count == 0) {
                let sampleSettings = sampleSetSettings()
                try realm.write {
                    realm.add(sampleSettings)
                }
                self.allSettings = realm.objects(Settings.self)
            }
            
            //データベースに登録されている単語を全て取得する
            self.allWords = realm.objects(Words.self)
            
            //登録されている単語が0件の場合、サンプルを登録する
            if(self.allWords.count == 0) {
                let sampleWords = sampleSetWords()
                try realm.write {
                    realm.add(sampleWords)
                }
                self.allWords = realm.objects(Words.self)
            }
            
            os_log(.debug, log: StartViewController.osLog, "登録済みの単語：\(self.allWords.count)個")
            
            super.viewDidLoad()
            
        } catch {
            os_log(.error, log: StartViewController.osLog, "データの取得に失敗しました")
        }
    }
    
    //スタートボタンをクリックした時、segueを実行する
    @IBAction func startBtnClicked(_ sender: Any) {
        
        performSegue(withIdentifier: "StartToMain", sender: nil)
    }
    
    //segue実行前処理
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        //segueの実行をMainViewControllerに通知する
        if segue.identifier == "StartToMain" {
            //出題を作成する
            let questions = setQuestions()
            
            os_log(.debug, log: StartViewController.osLog, "出題一覧：\(questions)")

            let mainController = segue.destinationController as! MainViewController
            mainController.questions = questions
        }
        
        //segueの実行をSettingViewControllerに通知する
        if segue.identifier == "StartToSetting" {
            _ = segue.destinationController as! SettingViewController
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

    //出題語のサンプルデータをセットする
    func sampleSetWords() -> Words {
        let sample = Words()
        
        sample.word = "サンプル"
        sample.numOfEntries = 0
        sample.numOfCorrects = 0
        sample.numOfEntries = 0
        sample.createdDate = Date()
        
        return sample
    }
    
    //出題を作成する
    func setQuestions() -> Results<Words> {
        
        var questions = self.allWords!
        //設定されている出題件数
        let number = self.allSettings![0].numOfQuestions
        
        //登録されている単語が出題件数より少ない場合
        if questions.count < number {
            os_log(.info, log: StartViewController.osLog, "登録されている単語が、設定されている出題件数より少ないです。")
        //登録されている単語が出題件数より多い場合
        } else {
            //未出題の単語を取得する
            let unEntries = questions.filter("numOfEntries = 0")
            //不正解の単語を取得する
            let inCorrects = questions.filter("numOfEntries > 0 AND numOfCorrects = 0")
            //出題件数 -（未出題＋不正解）
            let lefts = number - (unEntries.count + inCorrects.count)
            
            //未出題の単語が出題件数より多い場合
            var id_list: [String] = []
            if unEntries.count > number {
                //未出題の単語からランダムで出題件数分のデータを取得する
                for _ in 0 ..< number {
                    let id: String = unEntries.randomElement()!.id
                    id_list.append(id)
                }
                questions = questions.filter(NSPredicate(format: "id IN %@", id_list))
            //未出題の単語が出題件数より少ない場合
            } else {
                switch lefts {
                    //未出題＋不正解の単語が出題件数と同じか多い場合
                    case let l where l <= 0:
                        //全ての未出題のidを取得する
                        for i in 0 ..< unEntries.count{
                            let id: String = unEntries[i].id
                            id_list.append(id)
                        }
                        //出題件数 - 未出題
                        let _lefts = number - unEntries.count
                        //不正解の単語からランダムで出題の不足分のデータを取得する
                        for _ in 0 ..< _lefts {
                            let _id: String = inCorrects.randomElement()!.id
                            id_list.append(_id)
                        }
                        questions = questions.filter(NSPredicate(format: "id IN %@", id_list))
                    //未出題＋不正解の単語が出題件数より少ない場合
                    case let l where l > 0:
                        //全ての未出題のidを取得する
                        for i in 0 ..< unEntries.count{
                            let id: String = unEntries[i].id
                            id_list.append(id)
                        }
                        //全ての不正解のidを取得する
                        for i in 0 ..< inCorrects.count{
                            let _id: String = inCorrects[i].id
                            id_list.append(_id)
                        }
                        //未出題＋不正解以外の単語を取得する
                        let notUnEntriesInCorrects = questions.filter("numOfEntries > 0 AND numOfCorrects > 0")
                        //未出題＋不正解以外の単語からランダムで出題の不足分のデータを取得する
                        for _ in 0 ..< l {
                            let __id: String = notUnEntriesInCorrects.randomElement()!.id
                            id_list.append(__id)
                        }
                        questions = questions.filter(NSPredicate(format: "id IN %@", id_list))
                    default:
                        break
                }
            }
        }
        
        return questions
    }
}
