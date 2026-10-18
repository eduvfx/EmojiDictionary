//
//  EmojiTableViewController.swift
//  EmojiDictionary
//

import UIKit

// MARK: - Custom Cell
class EmojiTableViewCell: UITableViewCell {
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    func update(with emoji: Emoji) {
        symbolLabel.text = emoji.symbol
        nameLabel.text = emoji.name
        descriptionLabel.text = emoji.description
    }
}

// MARK: - Table View Controller
class EmojiTableViewController: UITableViewController {
    var emojis: [Emoji] = Emoji.sampleEmojis

    override func viewDidLoad() {
        super.viewDidLoad()

        // Built-in edit button toggles delete and reorder controls
        navigationItem.leftBarButtonItem = editButtonItem

        // Dynamic self-sizing cell calculation
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60.0
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emojis.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmojiCell", for: indexPath) as! EmojiTableViewCell
        let emoji = emojis[indexPath.row]
        cell.update(with: emoji)
        cell.showsReorderControl = true
        return cell
    }

    // MARK: - Deletion & Reordering

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            emojis.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let movedEmoji = emojis.remove(at: fromIndexPath.row)
        emojis.insert(movedEmoji, at: to.row)
    }

    // MARK: - Navigation & Unwind

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "AddEmoji" || segue.identifier == "EditEmoji" else { return }
        let navController = segue.destination as! UINavigationController
        let addEditController = navController.topViewController as! AddEditEmojiTableViewController

        if segue.identifier == "EditEmoji", let indexPath = tableView.indexPathForSelectedRow {
            addEditController.emoji = emojis[indexPath.row]
        }
    }

    @IBAction func unwindToEmojiTableView(_ segue: UIStoryboardSegue) {
        guard segue.identifier == "saveUnwind",
              let sourceViewController = segue.source as? AddEditEmojiTableViewController,
              let emoji = sourceViewController.emoji else { return }

        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            // Edit mode: update existing row
            emojis[selectedIndexPath.row] = emoji
            tableView.reloadRows(at: [selectedIndexPath], with: .none)
        } else {
            // Add mode: insert new row at the end
            let newIndexPath = IndexPath(row: emojis.count, section: 0)
            emojis.append(emoji)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
}
