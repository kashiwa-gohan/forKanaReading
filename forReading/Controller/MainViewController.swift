//
//  MainViewController.swift
//  forReading
//
//  Created by kashiwa-gohan on 2021/12/18.
//

import Cocoa
import RealmSwift
import OSLog
import Speech
import AVFoundation
import AVFAudio
import Foundation

//メイン画面のViewController
class MainViewController: NSViewController, AVAudioRecorderDelegate, AVSpeechSynthesizerDelegate, SFSpeechRecognizerDelegate {

    static let osLog = OSLog(subsystem: "forReading", category: "MainViewController")
    var questions: Results<Words>!
    var count: Int = 0
    var mongon: String = "もんめ"
    var results = List<Answered>()
    var grades = Grades()
    
    let dir_path = "\(NSHomeDirectory())/Desktop/forReading/audio/"

    var syntherizer = AVSpeechSynthesizer()
    
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionReq: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var pronounce: String = ""
    
    @IBOutlet weak var questionNo: NSTextField!
    @IBOutlet weak var questionText: NSTextField!
    
    //MainViewController起動時の処理を実行する
    override func viewDidLoad() {
        os_log(.info, log: MainViewController.osLog, "【メイン画面の起動】")
        
        //音声認識の許可
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
          DispatchQueue.main.async {
            if authStatus != SFSpeechRecognizerAuthorizationStatus.authorized {
                print("音声認識を許可")
            }
          }
        }
        
        //1問目を画面に表示する
        questionNo.stringValue = String(count + 1) + mongon
        questionText.stringValue = questions[count].word
        
        super.viewDidLoad()
        
        //読み上げのデリゲート
        syntherizer.delegate = self
        
        //音声認識のデリゲート
        recognizer.delegate = self
    }

    //こたえるボタンをクリックした時
    @IBAction func answerBtnClicked(_ sender: Any) {
                
        //音声認識を開始する
        startRecognition()
        
        //画面を表示する
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5)  {
            self.displayText()
        }
    }
    
    //せいかいボタンをクリックした時
    @IBAction func correctBtnClicked(_ sender: NSButton) {
        
        //読み上げ音声
        let voice = AVSpeechSynthesisVoice(language: "ja-JP")
        //読み上げる出題
        let utterance = AVSpeechUtterance(string: questionText.stringValue)
        //読み上げ速度（最小）
        utterance.rate = AVSpeechUtteranceMinimumSpeechRate
        //声の高さ
        utterance.pitchMultiplier = 1.5
        utterance.voice = voice
        self.syntherizer.speak(utterance)

        //回答：誤りを登録
        let answerd = Answered()
        answerd.question = questionText.stringValue
        answerd.trueOrfalse = false
        results.append(answerd)
        grades.results = results
    }
    
    //画面に問題を表示する
    func displayText() {
        questionText.textColor = NSColor.black
        //クリックごとにカウンタの値を追加する
        self.count += 1
        
        //カウンタの値が設定した出題件数を超えた場合
        if self.count >= self.questions.count {
            
            //成績を登録する
            do {
                let realm = try Realm()
                try realm.write {
                    realm.add(grades)
                }
            } catch {
                os_log(.error, log: MainViewController.osLog, "データの登録に失敗しました")
            }
            
            //メッセージを表示してスタート画面に戻る
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.addButton(withTitle: "はい")
            alert.messageText = "もんだいがおわりました。スタートにもどります。"
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                performSegue(withIdentifier: "MainToStart", sender: nil)
            default:
                break
            }
        //カウンタの値が設定した出題件数以下の時
        } else {
            questionNo.stringValue = String(self.count + 1) + self.mongon
            questionText.stringValue = self.questions[self.count].word
        }
    }
    
    //segue実行前処理
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        //segueの実行をStartViewControllerに通知する
        if segue.identifier == "MainToStart" {
            _ = segue.destinationController as! StartViewController
        }
    }
    
    func startRecognition() {
        //前回の音声認識が実行中の場合はキャンセルする
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        //音声認識リクエストを作成する（ライブ）
        recognitionReq = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionReq = recognitionReq else {
          return
        }
        recognitionReq.shouldReportPartialResults = true
        
        //入力ノードとしてMacの内蔵マイクを使用する
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        //ノードの出力を監視してバッファを逐次保存する
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            recognitionReq.append(buffer)
        }
        
        do{
            audioEngine.prepare()
            try audioEngine.start()
        }catch let error{
            os_log(.error, log: MainViewController.osLog, "音声の取得に失敗しました：\(String(describing: error.localizedDescription))")
        }

        let answerd = Answered()
        answerd.question = questionText.stringValue
        answerd.trueOrfalse = false
        //音声認識の結果を取得する
        recognitionTask = recognizer.recognitionTask(with: recognitionReq, resultHandler: { (result, error) in
            
            if let error = error {
                os_log(.error, log: MainViewController.osLog, "音声認識の結果の取得に失敗しました：\(String(describing: error.localizedDescription))")
            }else {
                DispatchQueue.main.async {
                    print(result?.bestTranscription.formattedString as Any)
                    self.pronounce = result?.bestTranscription.formattedString as Any as! String
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    self.recognitionReq?.endAudio()
                    
                    //発音と出題が一致した場合、回答：正解を登録する
                    if answerd.question == self.pronounce{
                        answerd.trueOrfalse = true
                    }
                    self.results.append(answerd)
                    self.grades.results = self.results
                }
            }
        })
    }
    
    /* AVSpeechSynthesizerのデリゲート */
    //読み上げの途中を検出
    func speechSynthesizer(_: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance){
        questionText.textColor = NSColor.red
    }
    //読み上げ終了を検出
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            //画面に問題を表示
            self.displayText()
        }
    }

    /* SFSpeechRecognitionTaskのデリゲート */
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            os_log(.info, log: MainViewController.osLog, "音声認識を開始しました")
        } else {
            os_log(.info, log: MainViewController.osLog, "音声認識が停止しました")
        }
    }
}
