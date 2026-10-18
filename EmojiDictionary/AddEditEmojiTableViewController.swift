//
//  AddEditEmojiTableViewController.swift
//  EmojiDictionary
//

import UIKit

class AddEditEmojiTableViewController: UITableViewController {
    @IBOutlet weak var symbolTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var usageTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!

    var emoji: Emoji?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let emoji = emoji {
            symbolTextField.text = emoji.symbol
            nameTextField.text = emoji.name
            descriptionTextField.text = emoji.description
            usageTextField.text = emoji.usage
            title = "Edit Emoji"
        } else {
            title = "Add Emoji"
        }

        updateSaveButtonState()
    }

    @IBAction func textEditingChanged(_ sender: UITextField) {
        updateSaveButtonState()
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func updateSaveButtonState() {
        let symbol = symbolTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let name = nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let description = descriptionTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let usage = usageTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        saveButton.isEnabled = !symbol.isEmpty && !name.isEmpty && !description.isEmpty && !usage.isEmpty
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "saveUnwind" else { return }

        let symbol = symbolTextField.text ?? ""
        let name = nameTextField.text ?? ""
        let description = descriptionTextField.text ?? ""
        let usage = usageTextField.text ?? ""
        emoji = Emoji(symbol: symbol, name: name, description: description, usage: usage)
    }
}
