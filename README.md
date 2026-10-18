# EmojiDictionary — Ficha 3 (Storyboard / UIKit)

Projecto Xcode da app **Emoji Dictionary** pedida na ficha 3 de *Desenvolvimento para Dispositivos Móveis*:
lista de emojis com símbolo, nome e descrição, com adicionar, editar, remover e reordenar.

## O que está aqui

| Caminho | O que é |
|---|---|
| `EmojiDictionary.xcodeproj/` | projecto Xcode (abre com duplo-clique num Mac) |
| `EmojiDictionary/Emoji.swift` | modelo `Emoji` + `sampleEmojis` (6 emojis) |
| `EmojiDictionary/EmojiTableViewController.swift` | `EmojiTableViewCell` + lista (datasource, delete, reorder, segues) |
| `EmojiDictionary/AddEditEmojiTableViewController.swift` | formulário estático (4 secções, validação do Save) |
| `EmojiDictionary/Main.storyboard` | 4 cenas: Navigation Controller, lista, Navigation Controller (Add/Edit), formulário |
| `EmojiDictionary/LaunchScreen.storyboard`, `Info.plist`, `Assets.xcassets` | arranque, configuração da cena, ícone/accent |
| `Tools/verify_project.py` | verificador (corre no Windows, sem Xcode) |
| `Tools/relatorio.html`, `Tools/tutorial.html` | fontes dos dois PDFs entregues na pasta da cadeira |

## Como correr (precisa de Xcode)

```
abrir EmojiDictionary.xcodeproj  →  escolher um simulador de iPhone  →  ⌘R
```

Não há passos manuais pendentes no storyboard: todas as cenas, outlets, acções, segues e
identifiers estão declarados nos ficheiros. `IPHONEOS_DEPLOYMENT_TARGET = 16.0`,
`SWIFT_VERSION = 5.0`, bundle id `com.example.EmojiDictionary` (muda-o antes de submeter se
a cadeira pedir outro).

## Como testar tudo — um comando

```
python Tools/verify_project.py
```

| âmbito | comando | o que afirma |
|---|---|---|
| ficheiros + sintaxe | `python Tools/verify_project.py` | os 9 ficheiros existem; os storyboards são XML bem formado; `Info.plist` é plist válido; os 3 `Contents.json` são JSON válido |
| storyboard | (incluído acima) | cena inicial, classes e módulo, título e botão Add, célula + `EmojiCell`, 3 outlets, stacks (12/center e 2/leading), 4 constraints, hugging 252 / compression 751, 4 secções estáticas com headers e placeholders, 5 outlets, 4 acções *Editing Changed*, botão Save, unwind `saveUnwind` |
| storyboard ↔ Swift | (incluído acima) | cada outlet/acção/segue declarado existe no código; `EmojiCell`, `AddEmoji`, `EditEmoji`, `saveUnwind`, `editButtonItem`, altura automática, 6 emojis |
| projecto | (incluído acima) | cada ficheiro referenciado no `project.pbxproj` existe; 5 Swift na fase *Sources*; storyboards e assets na fase *Resources*; `INFOPLIST_FILE`, bundle id, Swift 5, iOS 16 |

Saída esperada: `verificações: 111   falhas: 0` e `RESULTADO: tudo verificado ✔`.
Alternativa sem Python: abrir o storyboard no Xcode e usar o **Connections Inspector** de cada
objecto (checklist na última página do tutorial).

## O que este verificador NÃO prova

Não há Xcode nem macOS nesta máquina: **não** está provado que o código compila nem que a app
corre. O que fica provado é que a estrutura, as ligações e o projecto estão completos e
coerentes — a lista de erros mais comum (um outlet sem ligação, um identifier trocado, um
ficheiro fora da fase de build) é exactamente o que este guião apanha. Para fechar o ciclo:
compilar e correr no simulador e usar o checklist manual do tutorial.

## Documentos

- `../DDM_Ficha3_EmojiDictionary_Relatorio.pdf` — o que foi feito, por secção da ficha, com as figuras e a evidência da verificação.
- `../DDM_Ficha3_EmojiDictionary_Tutorial.pdf` — como fazer à mão no Xcode, passo a passo.
