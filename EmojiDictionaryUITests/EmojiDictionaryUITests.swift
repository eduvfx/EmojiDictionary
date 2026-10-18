//
//  EmojiDictionaryUITests.swift
//  EmojiDictionaryUITests
//
//  Testes de interface: usam a app como um utilizador usaria (tocar, escrever,
//  arrastar) num simulador de iPhone. Guardam screenshots em cada passo.
//

import XCTest

final class EmojiDictionaryUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Utilitários

    /// Pasta onde os screenshots são guardados (o workflow define SCREENSHOT_DIR).
    private var shotDir: URL {
        let path = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] ?? NSTemporaryDirectory()
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    private func shot(_ name: String) -> XCUIScreenshot {
        let s = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: s)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        try? s.pngRepresentation.write(to: shotDir.appendingPathComponent("\(name).png"))
        return s
    }

    private func cells() -> XCUIElementQuery { app.tables.cells }

    private func firstCellStaticTexts() -> [String] {
        let cell = cells().element(boundBy: 0)
        return cell.staticTexts.allElementsBoundByIndex.map { $0.label }
    }

    private func formField(_ index: Int) -> XCUIElement {
        app.tables.textFields.element(boundBy: index)
    }

    private func type(_ text: String, into index: Int) {
        let field = formField(index)
        XCTAssertTrue(field.waitForExistence(timeout: 5), "campo \(index) do formulário não apareceu")
        field.tap()
        field.typeText(text)
    }

    // MARK: - 1. Lista (arranque)

    func test01_ListShowsTheSixSampleEmojis() {
        let nav = app.navigationBars["Emoji Dictionary"]
        XCTAssertTrue(nav.waitForExistence(timeout: 10), "a barra 'Emoji Dictionary' não apareceu")
        XCTAssertEqual(cells().count, 6, "a lista devia começar com 6 emojis")

        let first = firstCellStaticTexts()
        XCTAssertTrue(first.contains("😀"), "a primeira célula devia mostrar o emoji 😀 — vi \(first)")
        XCTAssertTrue(first.contains("Grinning Face"), "a primeira célula devia mostrar 'Grinning Face' — vi \(first)")
        XCTAssertTrue(first.contains("A typical smiley face."), "falta a descrição na célula — vi \(first)")
        shot("01-lista")
    }

    func test02_ScrollingTheList() {
        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        cells().element(boundBy: 5).swipeUp()
        shot("02-lista-fim")
        XCTAssertTrue(cells().count >= 6)
    }

    // MARK: - 2. Adicionar

    func test03_AddEmojiFlow() {
        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        app.navigationBars["Emoji Dictionary"].buttons["Add"].tap()

        XCTAssertTrue(app.navigationBars["Add Emoji"].waitForExistence(timeout: 10), "não abriu o formulário 'Add Emoji'")
        let save = app.navigationBars["Add Emoji"].buttons["Save"]
        XCTAssertTrue(save.exists, "falta o botão Save")
        XCTAssertFalse(save.isEnabled, "o Save devia começar desactivado")
        shot("03-form-add-vazio")

        type("🎓", into: 0)
        XCTAssertFalse(save.isEnabled, "com um só campo o Save tem de continuar desactivado")

        type("Graduate", into: 1)
        type("Finished the course.", into: 2)
        shot("04-form-add-preenchido")
        XCTAssertFalse(save.isEnabled, "com três campos o Save tem de continuar desactivado")

        type("success", into: 3)
        XCTAssertTrue(save.isEnabled, "com os quatro campos preenchidos o Save tem de estar activo")
        shot("05-form-add-save-activo")

        save.tap()

        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10), "não voltou à lista")
        XCTAssertEqual(cells().count, 7, "a lista devia ter 7 emojis depois de adicionar")
        cells().element(boundBy: 6).swipeUp()
        let last = cells().element(boundBy: 6).staticTexts.allElementsBoundByIndex.map { $0.label }
        XCTAssertTrue(last.contains("Graduate"), "o emoji novo devia estar no fim da lista — vi \(last)")
        shot("06-lista-com-novo-emoji")
    }

    func test04_CancelDoesNotAddAnything() {
        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        app.navigationBars["Emoji Dictionary"].buttons["Add"].tap()
        XCTAssertTrue(app.navigationBars["Add Emoji"].waitForExistence(timeout: 10))
        type("🚫", into: 0)
        app.navigationBars["Add Emoji"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        XCTAssertEqual(cells().count, 6, "Cancel não pode alterar a lista")
    }

    // MARK: - 3. Editar

    func test05_EditEmojiFlow() {
        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        cells().element(boundBy: 1).tap()

        XCTAssertTrue(app.navigationBars["Edit Emoji"].waitForExistence(timeout: 10), "não abriu o formulário 'Edit Emoji'")
        XCTAssertEqual(formField(0).value as? String, "😕", "o campo do símbolo devia vir preenchido")
        shot("07-form-edit-preenchido")

        let nameField = formField(1)
        nameField.tap()
        nameField.typeText(" Edited")
        app.navigationBars["Edit Emoji"].buttons["Save"].tap()

        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        XCTAssertEqual(cells().count, 6, "editar não pode acrescentar linhas")
        let second = firstCellStaticTexts().count > 0 ? cells().element(boundBy: 1).staticTexts.allElementsBoundByIndex.map { $0.label } : []
        XCTAssertTrue(second.contains { $0.contains("Edited") }, "a segunda célula devia mostrar o nome editado — vi \(second)")
        shot("08-lista-com-emoji-editado")
    }

    // MARK: - 4. Apagar e reordenar

    func test06_DeleteWithSwipe() {
        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        let first = cells().element(boundBy: 0)
        first.swipeLeft()
        shot("09-swipe-delete")
        let delete = first.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "o swipe devia revelar o botão Delete")
        delete.tap()
        XCTAssertEqual(cells().count, 5, "a lista devia ficar com 5 emojis")
        shot("10-depois-de-apagar")
    }

    func test07_ReorderInEditMode() {
        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        let firstBefore = firstCellStaticTexts().first ?? ""

        app.navigationBars["Emoji Dictionary"].buttons["Edit"].tap()
        shot("11-modo-edicao")

        let handles = cells().buttons.matching(identifier: "Reorder")
        guard handles.count > 1 else {
            return XCTFail("no modo de edição devia haver pegas de reordenamento (encontrei \(handles.count))")
        }
        handles.element(boundBy: 0).press(forDuration: 0.8, thenDragTo: cells().element(boundBy: 3))
        shot("12-depois-de-reordenar")

        let firstAfter = firstCellStaticTexts().first ?? ""
        XCTAssertNotEqual(firstAfter, firstBefore, "a primeira linha devia ter mudado depois de arrastar")
        XCTAssertEqual(cells().count, 6, "reordenar não pode alterar o número de linhas")

        app.navigationBars["Emoji Dictionary"].buttons["Done"].tap()
    }

    func test08_DeleteInEditMode() {
        XCTAssertTrue(app.navigationBars["Emoji Dictionary"].waitForExistence(timeout: 10))
        app.navigationBars["Emoji Dictionary"].buttons["Edit"].tap()
        let badge = cells().element(boundBy: 0).buttons.matching(identifier: "Delete").firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 5), "no modo de edição a célula devia ter o badge Delete")
        badge.tap()
        cells().element(boundBy: 0).buttons["Delete"].tap()
        shot("13-delete-modo-edicao")
        XCTAssertEqual(cells().count, 5)
        app.navigationBars["Emoji Dictionary"].buttons["Done"].tap()
    }
}
