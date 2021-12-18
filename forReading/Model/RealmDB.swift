//
//  Words.swift
//  forReading
//
//  Created by kashiwa-gohan on 2021/12/18.
//

import RealmSwift

//Realmのモデル定義において、クラスとプロパティが1:1の場合は
//@objc dynamic varを使用、
//1:多の場合は、Listを使用すること（Swift4以降？）

//出題する単語のModel
class Words: Object {
    @objc dynamic var id: String = NSUUID().uuidString
    @objc dynamic var word: String = ""
    @objc dynamic var numOfEntries: Int = 0
    @objc dynamic var numOfCorrects: Int = 0
    @objc dynamic var createdDate: Date = Date()
}

//過去の成績のModel
class Grades: Object {
    @objc dynamic var id: String = NSUUID().uuidString
    var results = List<Answered>()
    @objc dynamic var answeredDate: Date = Date()
}
class Answered: Object {
    @objc dynamic var question: String = ""
    @objc dynamic var trueOrfalse: Bool = false
}

//ツールの設定に関するModel
class Settings: Object {
    @objc dynamic var id: String = NSUUID().uuidString
    @objc dynamic var numOfQuestions: Int = 10
    @objc dynamic var createdDate:Date = Date()
    @objc dynamic var updatedDate:Date = Date()
}
