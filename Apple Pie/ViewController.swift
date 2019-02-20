//
//  ViewController.swift
//  Apple Pie
//
//  Created by student12 on 2/19/19.
//  Copyright © 2019 pedro. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    var listOfWords: [String] = []
    let incorrectMovesAllowed = 7
    var totalScore = 0
    var totalWins = 0 {
        didSet {
            newRound()
        }
    }
    var totalLosses = 0 {
        didSet {
            newRound()
        }
    }
    var currentGame: Game!
    
    @IBOutlet weak var treeImageView: UIImageView!
    @IBOutlet weak var correctWordLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet var letterButtons: [UIButton]!
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        sender.isEnabled = false
        
        let letterString = sender.title(for: .normal)!
        let letter = Character(letterString.lowercased())
        
        currentGame.playerGuessed(letter: letter)
        updateGameState()
    }
    
    @IBAction func highScoresPressed(_ sender: Any) {
        var scores = ""
        let context = self.appDelegate!.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Scores")
        request.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]
        request.fetchLimit = 10
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            
            for data in result as! [NSManagedObject] {
                scores += "\(data.value(forKey: "name") as! String) \(data.value(forKey: "score") as! Int)\n"
            }
            
            let alert = UIAlertController(title: "Highest Scores", message: scores, preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil ))
            
            self.present(alert, animated: true, completion: nil)
        } catch {
            print("Failed")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newGame()
    }
    
    func newGame() {
        listOfWords = ["book", "ability", "address", "chair", "detail", "fish", "happy", "money", "north", "season", "travel"]
        
        listOfWords.shuffle()
        totalScore = 0
        
        newRound()
    }

    func newRound() {
        if !listOfWords.isEmpty {
            let newWord = listOfWords.remove(at: Int.random(in: 0..<listOfWords.count))
            currentGame = Game(word: newWord, incorrectMovesRemaining: incorrectMovesAllowed, guessedLetters: [])
            enableLetterButtons(true)
            updateUI()
        } else {
            enableLetterButtons(false)
            updateUI()
            if isTopScore(score: totalScore) {
                saveScoreAlert()
            } else {
                showPlayAgainAlert()
            }
        }
        
    }
    
    func updateUI() {
        var letters = [String]()
        
        for letter in currentGame.formattedWord.characters {
            letters.append(String(letter))
        }
        
        let wordWithSpacing = letters.joined(separator: " ")
        
        correctWordLabel.text = wordWithSpacing
        scoreLabel.text = "Wins: \(totalWins), Losses: \(totalLosses), Score: \(totalScore)"
        treeImageView.image = UIImage(named: "Tree \(currentGame.incorrectMovesRemaining)")
    }
    
    func updateGameState() {
        if currentGame.incorrectMovesRemaining == 0 {
            totalLosses += 1
        } else if currentGame.word == currentGame.formattedWord {
            totalScore += currentGame.incorrectMovesRemaining + 3
            totalWins += 1
        } else {
            updateUI()
        }
    }
    
    func enableLetterButtons(_ enable: Bool) {
        for button in letterButtons {
            button.isEnabled = enable
        }
    }
    
    func showPlayAgainAlert() {
        let alert = UIAlertController(title: "Apple Pie", message: "Your score is \(totalScore)!\nWould you like to play again?", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Play Again", style: UIAlertAction.Style.default, handler: { action in
            self.newGame()
        }
        ))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:
            { antion in
                exit(0)
        }
        ))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveScoreAlert() {
        let alert = UIAlertController(title: "Apple Pie", message: "Great Job!\nYour score is \(totalScore).\n Would you like to save it?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler:
            { action in
                let name = alert.textFields![0] as UITextField
                self.saveScore(name: name.text!, score: self.totalScore)
                self.showPlayAgainAlert()
            }
        ))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:
            { action in
                self.showPlayAgainAlert()
            }
        ))
        
        alert.addTextField { (textField) in textField.placeholder = "Enter your name" }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func isTopScore(score: Int) -> Bool {
        let context = self.appDelegate!.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Scores")
        request.predicate = NSPredicate(format: "score >= %@", String(score))
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            
            if result.count < 10 {
                return true
            } else {
                return false
            }
        } catch {
            print("Failed")
            return false
        }
    }
    
    func saveScore(name: String, score: Int) {
        let context = self.appDelegate!.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Scores",in: context)!
        let newScore = NSManagedObject(entity: entity, insertInto: context)
        
        newScore.setValue(name, forKey: "name")
        newScore.setValue(score, forKey: "score")
        
        do {
            try context.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

