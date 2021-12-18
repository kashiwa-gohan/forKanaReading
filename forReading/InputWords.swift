//
//  CreateWords.swift
//  forReading
//
//  Created by kashiwa-gohan on 2021/12/18.
//

import Foundation
import OSLog
import NaturalLanguage
import PythonKit
import RealmSwift

//テキストファイルから名詞を抽出してデータベースに登録するクラス
class InputWords {
    static let osLog = OSLog(subsystem: "forReading", category: "InputWords")
    var allWords: Results<Words>!

    //pythonプログラムの呼び出し：テキストファイルを品詞分解して名詞を抽出する
    func callAnalyze(urls: [URL]) {
        let sys = Python.import("sys")
        sys.path.append("\(NSHomeDirectory())/Desktop/forReading/")
        let externalPython = Python.import("externalPython")
        
        var word_list: [String] = []
        for url in urls {
            //品詞分解した結果：result（PythonObject）を配列に変換する
            let result = externalPython.analyze(url.path)
            var conversion: [String] = []
            for i in 0 ..< Int(result.endIndex)! {
                var word: String = ""
                word = String(result[i])!
                conversion.append(word)
            }
            word_list += conversion
        }
        //配列から重複を除く
        let orderedSet:NSOrderedSet = NSOrderedSet(array: word_list)
        var word_unique = orderedSet.array as! [String]
        //配列から1文字のものを除く
        word_unique = word_unique.filter{$0.lengthOfBytes(using: String.Encoding.shiftJIS) > 2}

        resistration(word_unique: word_unique)
    }
    
    //出題語をデータベースに登録する
    func resistration(word_unique: [String]) {
        do {
            let realm = try Realm()
            var words: [Words] = []
            
            for word in word_unique {
                let _word = Words()
                _word.word = word
                _word.numOfEntries = 0
                _word.numOfCorrects = 0
                _word.createdDate = Date()
                words.append(_word)
            }
            
            try! realm.write {
                realm.add(words)
            }
                        
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "出題語をデータベースに登録しました。"
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
              switch response {
              case .alertFirstButtonReturn:
                  print("OK")
              default:
                  break
              }
            
        } catch {
            os_log(.error, log: SettingViewController.osLog, "出題語の登録に失敗しました。")
        }
    }
}
