//
//  EmojiDictionaryTests.swift
//  EmojiDictionaryTests
//
//  Testes unitários que correm no simulador de iOS (Xcode / GitHub Actions).
//  Exercitam exactamente o que a ficha 3 pede: modelo, arranque pelo storyboard,
//  ligação das outlets da célula, datasource, remoção, reordenação e o ciclo
//  Add/Edit com o unwind.
//

import XCTest
@testable import EmojiDictionary

final class EmojiDictionaryTests: XCTestCase {

    // MARK: - Helpers

    private func storyboard() -> UIStoryboard {
        UIStoryboard(name: "Main", bundle: Bundle(for: EmojiTableViewController.self))
    }

    private func makeList() -> EmojiTableViewController {
        let initial = storyboard().instantiateInitialViewController()
        guard let nav = initial as? UINavigationController,
              let list = nav.topViewController as? EmojiTableViewController else {
            fatalError("a cena inicial do Main.storyboard não é um UINavigationController com EmojiTableViewController na raiz")
        }
        list.loadViewIfNeeded()
        return list
    }

    private func makeAddForm() -> AddEditEmojiTableViewController {
        let vc = storyboard().instantiateViewController(withIdentifier: "AddEditNav")
        guard let nav = vc as? UINavigationController,
              let form = nav.topViewController as? AddEditEmojiTableViewController else {
            fatalError("a cena 'AddEditNav' não é um UINavigationController com AddEditEmojiTableViewController na raiz")
        }
        form.loadViewIfNeeded()
        return form
    }

    private func fill(_ form: AddEditEmojiTableViewController, symbol: String = "🎓", name: String = "Graduate",
                      description: String = "Finished the course.", usage: String = "success") {
        form.symbolTextField.text = symbol
        form.nameTextField.text = name
        form.descriptionTextField.text = description
        form.usageTextField.text = usage
        form.textEditingChanged(form.symbolTextField)   // o mesmo @IBAction ligado aos 4 campos
    }

    // MARK: - 1. Modelo

    func testSampleDataHasSixEmojisAndExpectedFirstOne() {
        XCTAssertEqual(Emoji.sampleEmojis.count, 6)
        let first = Emoji.sampleEmojis[0]
        XCTAssertEqual(first.symbol, "😀")
        XCTAssertEqual(first.name, "Grinning Face")
        XCTAssertEqual(first.description, "A typical smiley face.")
        XCTAssertEqual(first.usage, "happiness")
        XCTAssertEqual(Emoji.sampleEmojis.map(\.symbol), ["😀", "😕", "😍", "🧑‍💻", "🐢", "📚"])
    }

    // MARK: - 2. Arranque pelo storyboard (cena inicial, classes, barra)

    func testInitialSceneIsNavigationControllerWithListAsRoot() {
        let list = makeList()
        XCTAssertEqual(list.navigationItem.title, "Emoji Dictionary")
        XCTAssertNotNil(list.navigationItem.rightBarButtonItem, "falta o botão + na barra")
        XCTAssertEqual(list.navigationItem.rightBarButtonItem?.style, .plain)
        XCTAssertEqual(list.tableView.numberOfSections, 1)
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 6)
        XCTAssertEqual(list.tableView.rowHeight, UITableView.automaticDimension)
        XCTAssertEqual(list.tableView.estimatedRowHeight, 60.0, accuracy: 0.001)
        XCTAssertNotNil(list.navigationItem.leftBarButtonItem, "falta o editButtonItem")
        XCTAssertTrue(list.isEditing == false)
    }

    // MARK: - 3. Célula protótipo: identifier, classe e outlets ligadas

    func testPrototypeCellIsFilledFromTheModel() {
        let list = makeList()
        let indexPath = IndexPath(row: 3, section: 0)
        let cell = list.tableView(list.tableView, cellForRowAt: indexPath)
        guard let emojiCell = cell as? EmojiTableViewCell else {
            return XCTFail("a célula devolvida não é EmojiTableViewCell (identifier/classe do storyboard)")
        }
        XCTAssertEqual(emojiCell.symbolLabel.text, "🧑‍💻")
        XCTAssertEqual(emojiCell.nameLabel.text, "Developer")
        XCTAssertEqual(emojiCell.descriptionLabel.text, "Working on Mac.")
        XCTAssertTrue(emojiCell.showsReorderControl)
        XCTAssertEqual(emojiCell.descriptionLabel.numberOfLines, 0)
        XCTAssertEqual(emojiCell.symbolLabel.textAlignment, .natural)
    }

    // MARK: - 4. Remoção e reordenação

    func testDeleteRemovesFromTheModelAndTheTable() {
        let list = makeList()
        let before = list.emojis.count
        list.tableView(list.tableView, commit: .delete, forRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(list.emojis.count, before - 1)
        XCTAssertEqual(list.emojis.first?.symbol, "😕")
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), before - 1)
    }

    func testMoveReordersTheModel() {
        let list = makeList()
        let firstSymbol = list.emojis[0].symbol
        list.tableView(list.tableView, moveRowAt: IndexPath(row: 0, section: 0), to: IndexPath(row: 5, section: 0))
        XCTAssertEqual(list.emojis.count, 6)
        XCTAssertEqual(list.emojis[5].symbol, firstSymbol)
        XCTAssertEqual(list.emojis[0].symbol, "😕")
    }

    // MARK: - 5. Formulário estático e validação do Save

    func testAddFormHasFourStaticSectionsAndSaveStartsDisabled() {
        let form = makeAddForm()
        XCTAssertEqual(form.tableView.numberOfSections, 4)
        for section in 0..<4 {
            XCTAssertEqual(form.tableView.numberOfRows(inSection: section), 1, "secção \(section) devia ter 1 linha")
        }
        XCTAssertEqual(form.title, "Add Emoji")
        XCTAssertFalse(form.saveButton.isEnabled, "o Save devia começar desactivado")
        XCTAssertNotNil(form.symbolTextField)
        XCTAssertNotNil(form.nameTextField)
        XCTAssertNotNil(form.descriptionTextField)
        XCTAssertNotNil(form.usageTextField)
    }

    func testSaveButtonEnablesOnlyWhenAllFourFieldsAreFilled() {
        let form = makeAddForm()
        form.symbolTextField.text = "🎓"
        form.textEditingChanged(form.symbolTextField)
        XCTAssertFalse(form.saveButton.isEnabled, "com um só campo preenchido o Save tem de continuar desactivado")

        form.nameTextField.text = "Graduate"
        form.descriptionTextField.text = "Finished the course."
        form.textEditingChanged(form.nameTextField)
        XCTAssertFalse(form.saveButton.isEnabled)

        form.usageTextField.text = "success"
        form.textEditingChanged(form.usageTextField)
        XCTAssertTrue(form.saveButton.isEnabled, "com os quatro campos preenchidos o Save tem de ficar activo")

        form.usageTextField.text = "   "
        form.textEditingChanged(form.usageTextField)
        XCTAssertFalse(form.saveButton.isEnabled, "espaços não contam como conteúdo")
    }

    func testEditFormIsPrefilledAndTitledEdit() {
        let form = makeAddForm()
        let emoji = Emoji(symbol: "🐢", name: "Turtle", description: "Slow but steady.", usage: "slow")
        form.emoji = emoji
        form.loadViewIfNeeded()
        form.viewDidLoad()
        XCTAssertEqual(form.title, "Edit Emoji")
        XCTAssertEqual(form.symbolTextField.text, "🐢")
        XCTAssertEqual(form.nameTextField.text, "Turtle")
        XCTAssertEqual(form.descriptionTextField.text, "Slow but steady.")
        XCTAssertEqual(form.usageTextField.text, "slow")
        XCTAssertTrue(form.saveButton.isEnabled)
    }

    // MARK: - 6. Ciclo Add / Edit com os segues

    func testUnwindWithoutSelectionAppendsANewRow() {
        let list = makeList()
        let form = makeAddForm()
        fill(form)

        let segue = UIStoryboardSegue(identifier: "saveUnwind", source: form, destination: list)
        form.prepare(for: segue, sender: nil)
        XCTAssertEqual(form.emoji?.symbol, "🎓", "prepare(for:) devia ter montado o Emoji")

        list.unwindToEmojiTableView(segue)
        XCTAssertEqual(list.emojis.count, 7)
        XCTAssertEqual(list.emojis.last?.name, "Graduate")
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 7)
    }

    func testUnwindWithSelectionUpdatesTheExistingRow() {
        let list = makeList()
        list.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        XCTAssertNotNil(list.tableView.indexPathForSelectedRow)

        let form = makeAddForm()
        fill(form, symbol: "📝", name: "Edited", description: "Edited row.", usage: "edit")

        let segue = UIStoryboardSegue(identifier: "saveUnwind", source: form, destination: list)
        form.prepare(for: segue, sender: nil)
        list.unwindToEmojiTableView(segue)

        XCTAssertEqual(list.emojis.count, 6, "editar não pode acrescentar linhas")
        XCTAssertEqual(list.emojis[0].name, "Edited")
        XCTAssertEqual(list.emojis[0].symbol, "📝")
    }

    func testPrepareForEditSeguePassesTheSelectedEmoji() {
        let list = makeList()
        list.tableView.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)

        let form = makeAddForm()
        let segue = UIStoryboardSegue(identifier: "EditEmoji", source: list, destination: form.navigationController ?? form)
        list.prepare(for: segue, sender: nil)

        XCTAssertEqual(form.emoji?.symbol, "😍")
        XCTAssertEqual(form.emoji?.name, "Heart Eyes")
    }

    func testEditingTheListUsesTheEditButtonFromViewDidLoad() {
        let list = makeList()
        let editButton = list.navigationItem.leftBarButtonItem
        XCTAssertNotNil(editButton, "falta o editButtonItem na barra de navegação")
        let rotulo = ((editButton?.title ?? "") + " " + (editButton?.accessibilityLabel ?? "")).trimmingCharacters(in: .whitespaces)
        XCTAssertTrue(rotulo.isEmpty || rotulo.contains("Edit") || rotulo.contains("Editar"),
                      "o botão de edição devia identificar-se como Edit — vi '\(rotulo)'")
        XCTAssertFalse(list.isEditing)
        list.setEditing(true, animated: false)
        XCTAssertTrue(list.isEditing, "setEditing(true) devia ligar o modo de edição")
        list.setEditing(false, animated: false)
        XCTAssertFalse(list.isEditing, "setEditing(false) devia desligar o modo de edição")
        XCTAssertTrue(list.tableView.allowsMultipleSelectionDuringEditing == false)
    }
}
