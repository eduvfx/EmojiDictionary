#!/usr/bin/env python3
"""Verificador do projecto EmojiDictionary (corre no Windows, sem Xcode).

Verifica, a partir dos ficheiros em disco:
  1. XML bem formado (storyboards) e plists/JSON válidos;
  2. a estrutura do Main.storyboard exigida pela ficha 3 (cenas, classes,
     cell, stacks, constraints, segues, unwind, outlets, acções);
  3. que cada outlet/acção/segue declarado no storyboard existe no código Swift;
  4. que o project.pbxproj referencia ficheiros que existem e que as fases
     Sources/Resources incluem tudo o que é preciso.

Uso:  python Tools/verify_project.py        (exit 0 = tudo verificado)
"""
import json, os, plistlib, re, sys, xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'EmojiDictionary')
SB = os.path.join(SRC, 'Main.storyboard')
PBX = os.path.join(ROOT, 'EmojiDictionary.xcodeproj', 'project.pbxproj')

fails, checks = [], 0


def check(cond, label):
    global checks
    checks += 1
    print(('  OK   ' if cond else '  FALHA') + '  ' + label)
    if not cond:
        fails.append(label)


def read(p):
    with open(p, encoding='utf-8') as fh:
        return fh.read()


print('== 1. ficheiros e sintaxe ==')
for rel in ['EmojiDictionary/AppDelegate.swift', 'EmojiDictionary/SceneDelegate.swift',
            'EmojiDictionary/Emoji.swift', 'EmojiDictionary/EmojiTableViewController.swift',
            'EmojiDictionary/AddEditEmojiTableViewController.swift', 'EmojiDictionary/Main.storyboard',
            'EmojiDictionary/LaunchScreen.storyboard', 'EmojiDictionary/Info.plist',
            'EmojiDictionary.xcodeproj/project.pbxproj']:
    check(os.path.isfile(os.path.join(ROOT, rel)), f'existe {rel}')

for rel in ['EmojiDictionary/Main.storyboard', 'EmojiDictionary/LaunchScreen.storyboard']:
    try:
        ET.parse(os.path.join(ROOT, rel))
        check(True, f'XML bem formado: {rel}')
    except ET.ParseError as e:
        check(False, f'XML bem formado: {rel} ({e})')

try:
    info = plistlib.load(open(os.path.join(SRC, 'Info.plist'), 'rb'))
    check(True, 'Info.plist é um plist válido')
except Exception as e:
    info = {}
    check(False, f'Info.plist é um plist válido ({e})')

for rel in ['EmojiDictionary/Assets.xcassets/Contents.json',
            'EmojiDictionary/Assets.xcassets/AppIcon.appiconset/Contents.json',
            'EmojiDictionary/Assets.xcassets/AccentColor.colorset/Contents.json']:
    try:
        json.loads(read(os.path.join(ROOT, rel)))
        check(True, f'JSON válido: {os.path.basename(rel)}')
    except Exception as e:
        check(False, f'JSON válido: {rel} ({e})')

print('== 2. Info.plist (arranque por storyboard) ==')
scene = info.get('UIApplicationSceneManifest', {}).get('UISceneConfigurations', {}) \
            .get('UIWindowSceneSessionRoleApplication', [{}])
scene = scene[0] if scene else {}
check(scene.get('UISceneStoryboardFile') == 'Main', 'UISceneStoryboardFile == Main')
check(scene.get('UISceneDelegateClassName', '').endswith('SceneDelegate'), 'UISceneDelegateClassName aponta para SceneDelegate')
check(info.get('UILaunchStoryboardName') == 'LaunchScreen', 'UILaunchStoryboardName == LaunchScreen')

print('== 3. Main.storyboard: estrutura ==')
tree = ET.parse(SB)
doc = tree.getroot()
by_id = {el.get('id'): el for el in doc.iter() if el.get('id')}

initial = doc.get('initialViewController')
check(initial in by_id and by_id[initial].tag == 'navigationController',
      'initialViewController é um UINavigationController')

# recursivamente a partir do nav controller: relationship segue -> table view controller
def kids_by_tag(el, tag):
    return [c for c in el.iter() if c.tag == tag]

def first_subtree(root_el, tag):
    return next((e for e in root_el.iter() if e.tag == tag), None)

root_tvc = None
if initial in by_id:
    seg = next((s for s in by_id[initial].iter('segue') if s.get('kind') == 'relationship'), None)
    check(seg is not None, 'nav controller tem segue de relação (rootViewController)')
    if seg is not None:
        root_tvc = by_id.get(seg.get('destination'))
check(root_tvc is not None and root_tvc.get('customClass') == 'EmojiTableViewController',
      'o root view controller tem customClass EmojiTableViewController')
check(root_tvc is not None and root_tvc.get('customModule') == 'EmojiDictionary',
      'customModule == EmojiDictionary')

nav_item = first_subtree(root_tvc, 'navigationItem') if root_tvc is not None else None
check(nav_item is not None and nav_item.get('title') == 'Emoji Dictionary',
      'navigationItem do root tem título "Emoji Dictionary"')
add_btn = first_subtree(nav_item, 'barButtonItem') if nav_item is not None else None
check(add_btn is not None and add_btn.get('systemItem') == 'add',
      'botão direito da barra é o System Item Add')

# AddEmoji segue
add_seg = first_subtree(add_btn, 'segue') if add_btn is not None else None
check(add_seg is not None and add_seg.get('identifier') == 'AddEmoji' and add_seg.get('kind') == 'presentation',
      'segue AddEmoji (presentation) parte do botão +')

# prototype cell
cell = first_subtree(root_tvc, 'tableViewCell') if root_tvc is not None else None
check(cell is not None and cell.get('reuseIdentifier') == 'EmojiCell', 'prototype cell com identifier EmojiCell')
check(cell is not None and cell.get('customClass') == 'EmojiTableViewCell', 'prototype cell com classe EmojiTableViewCell')

edit_seg = first_subtree(cell, 'segue') if cell is not None else None
check(edit_seg is not None and edit_seg.get('identifier') == 'EditEmoji' and edit_seg.get('kind') == 'presentation',
      'segue EditEmoji (presentation) parte da célula')

labels = {l.get('id'): l for l in kids_by_tag(cell, 'label')} if cell is not None else {}
outlets_cell = {o.get('property'): o.get('destination') for o in kids_by_tag(cell, 'outlet')} if cell is not None else {}
check(set(outlets_cell) == {'symbolLabel', 'nameLabel', 'descriptionLabel'},
      'célula expõe outlets symbolLabel/nameLabel/descriptionLabel')
for prop in ('symbolLabel', 'nameLabel', 'descriptionLabel'):
    check(outlets_cell.get(prop) in labels, f'outlet {prop} ligado a um UILabel existente')

sym = labels.get(outlets_cell.get('symbolLabel'))
if sym is not None:
    check(sym.get('horizontalHuggingPriority') == '252', 'symbolLabel: content hugging horizontal = 252')
    check(sym.get('horizontalCompressionResistancePriority') == '751', 'symbolLabel: compression resistance horizontal = 751')
    check(sym.find('fontDescription') is not None and sym.find('fontDescription').get('pointSize') == '34',
          'symbolLabel com tipo grande (34 pt)')
desc = labels.get(outlets_cell.get('descriptionLabel'))
if desc is not None:
    check(desc.get('numberOfLines') == '0', 'descriptionLabel: Lines = 0')
    check(desc.get('lineBreakMode') == 'wordWrap', 'descriptionLabel: Line Break = Word Wrap')
    tc = desc.find('color')
    check(tc is not None and tc.get('systemColor') == 'secondaryLabelColor',
          'descriptionLabel com cor Secondary Label')

# stacks
stacks = kids_by_tag(cell, 'stackView') if cell is not None else []
h = next((s for s in stacks if s.get('spacing') == '12' and s.get('alignment') == 'center'), None)
v = next((s for s in stacks if s.get('spacing') == '2' and s.get('alignment') == 'leading'), None)
check(h is not None, 'stack horizontal (spacing 12, alignment center)')
check(v is not None, 'stack vertical (spacing 2, alignment leading)')
if h is not None and v is not None:
    check(v in list(h.iter('stackView')), 'stack vertical está embutido no horizontal')
    check(sym is not None and sym in list(h.iter('label')), 'symbolLabel está no stack horizontal')
    check(desc is not None and desc in list(v.iter('label')), 'descriptionLabel está no stack vertical')

constraints = kids_by_tag(cell, 'constraint') if cell is not None else []
def has_constraint(attr1, attr2):
    return any((c.get('firstAttribute') == attr1 and c.get('secondAttribute') == attr2) or
               (c.get('firstAttribute') == attr2 and c.get('secondAttribute') == attr1) for c in constraints)
if h is not None:
    check(has_constraint('leading', 'leadingMargin'), 'constraint Leading do stack para a margem da célula')
    check(has_constraint('top', 'topMargin'), 'constraint Top do stack para a margem da célula')
    check(has_constraint('trailing', 'trailingMargin'), 'constraint Trailing do stack para a margem da célula')
    check(has_constraint('bottom', 'bottomMargin'), 'constraint Bottom do stack para a margem da célula')

# Add/Edit scene
tvc2 = next((e for e in doc.iter('tableViewController')
             if e.get('customClass') == 'AddEditEmojiTableViewController'), None)
check(tvc2 is not None, 'existe cena com classe AddEditEmojiTableViewController')
if tvc2 is not None:
    tv = first_subtree(tvc2, 'tableView')
    check(tv is not None and tv.get('dataMode') == 'static', 'Add/Edit usa Static Cells')
    sections = kids_by_tag(tv, 'tableViewSection')
    check(len(sections) == 4, 'Add/Edit tem 4 secções')
    check([s.get('headerTitle') for s in sections] == ['Symbol', 'Name', 'Description', 'Usage'],
          'cabeçalhos das secções: Symbol/Name/Description/Usage')
    fields = kids_by_tag(tv, 'textField')
    check(len(fields) == 4, 'Add/Edit tem 4 text fields')
    check([f.get('placeholder') for f in fields] == ['The emoji', "The emoji's name",
                                                     'Describe this emoji', 'When do you use it?'],
          'placeholders dos text fields')
    for f in fields:
        cs = kids_by_tag(f, 'constraint') + kids_by_tag(f.getparent() if hasattr(f, 'getparent') else tv, 'constraint') \
             if False else kids_by_tag(tv, 'constraint')
    outs2 = {o.get('property'): o.get('destination') for o in kids_by_tag(tvc2, 'outlet')}
    check(set(outs2) == {'symbolTextField', 'nameTextField', 'descriptionTextField', 'usageTextField', 'saveButton'},
          'Add/Edit expõe os 5 outlets (4 text fields + saveButton)')
    field_ids = {f.get('id') for f in fields}
    check(all(outs2.get(k) in field_ids for k in ('symbolTextField', 'nameTextField', 'descriptionTextField', 'usageTextField')),
          'os outlets dos text fields apontam para os 4 campos')
    acts = [a for a in kids_by_tag(tvc2, 'action')]
    check(sum(1 for a in acts if a.get('selector') == 'textEditingChanged:') == 4,
          'acção textEditingChanged: ligada aos 4 text fields (Editing Changed)')
    check(any(a.get('selector') == 'cancelButtonTapped:' for a in acts), 'acção cancelButtonTapped: no botão Cancel')
    check(any(a.get('eventType') == 'editingChanged' for a in acts), 'acções usam o evento Editing Changed')
    nav2 = first_subtree(tvc2, 'navigationItem')
    save_btn = None
    if nav2 is not None:
        save_btn = next((b for b in kids_by_tag(nav2, 'barButtonItem') if b.get('systemItem') == 'save'), None)
    check(save_btn is not None, 'botão direito é o System Item Save')
    unw = first_subtree(save_btn, 'segue') if save_btn is not None else None
    check(unw is not None and unw.get('kind') == 'unwind' and unw.get('identifier') == 'saveUnwind'
          and unw.get('unwindAction') == 'unwindToEmojiTableView:',
          'unwind segue saveUnwind -> unwindToEmojiTableView: ligado ao botão Save')

print('== 4. ligações storyboard <-> código Swift ==')
src_tvc = read(os.path.join(SRC, 'EmojiTableViewController.swift'))
src_add = read(os.path.join(SRC, 'AddEditEmojiTableViewController.swift'))
src_model = read(os.path.join(SRC, 'Emoji.swift'))

for prop in ('symbolLabel', 'nameLabel', 'descriptionLabel'):
    check(re.search(r'@IBOutlet\s+weak\s+var\s+' + prop + r'\s*:\s*UILabel!', src_tvc) is not None,
          f'EmojiTableViewCell declara @IBOutlet {prop}')
for prop in ('symbolTextField', 'nameTextField', 'descriptionTextField', 'usageTextField'):
    check(re.search(r'@IBOutlet\s+weak\s+var\s+' + prop + r'\s*:\s*UITextField!', src_add) is not None,
          f'AddEdit declara @IBOutlet {prop}')
check(re.search(r'@IBOutlet\s+weak\s+var\s+saveButton\s*:\s*UIBarButtonItem!', src_add) is not None,
      'AddEdit declara @IBOutlet saveButton')
check(re.search(r'@IBAction\s+func\s+textEditingChanged\(', src_add) is not None, 'AddEdit tem @IBAction textEditingChanged')
check(re.search(r'@IBAction\s+func\s+cancelButtonTapped\(', src_add) is not None, 'AddEdit tem @IBAction cancelButtonTapped')
check(re.search(r'@IBAction\s+func\s+unwindToEmojiTableView\(', src_tvc) is not None,
      'EmojiTableViewController tem @IBAction unwindToEmojiTableView')
check(re.search(r'class\s+EmojiTableViewCell\s*:\s*UITableViewCell', src_tvc) is not None, 'classe EmojiTableViewCell existe')
check(re.search(r'class\s+EmojiTableViewController\s*:\s*UITableViewController', src_tvc) is not None,
      'classe EmojiTableViewController é UITableViewController')
check(re.search(r'class\s+AddEditEmojiTableViewController\s*:\s*UITableViewController', src_add) is not None,
      'classe AddEditEmojiTableViewController é UITableViewController')
check('"EmojiCell"' in src_tvc, 'o código usa o reuse identifier "EmojiCell"')
check('"AddEmoji"' in src_tvc and '"EditEmoji"' in src_tvc, 'prepare(for:) reconhece AddEmoji e EditEmoji')
check('"saveUnwind"' in src_add, 'prepare(for:) do AddEdit usa saveUnwind')
check('editButtonItem' in src_tvc, 'viewDidLoad instala o editButtonItem')
check('UITableView.automaticDimension' in src_tvc and 'estimatedRowHeight = 60.0' in src_tvc,
      'células com altura automática (automaticDimension, estimada 60)')
check(all(k in src_model for k in ('struct Emoji', 'static var sampleEmojis')), 'modelo Emoji + sampleEmojis')
check(len(re.findall(r'Emoji\(symbol:', src_model)) == 6, 'sampleEmojis com 6 emojis')

print('== 5. project.pbxproj ==')
pbx = read(PBX)
refs = re.findall(r'isa = PBXFileReference;.*?path = ([^;]+);', pbx)
present = {os.path.basename(p.strip().strip('"')) for p in refs}
for f in ['AppDelegate.swift', 'SceneDelegate.swift', 'Emoji.swift', 'EmojiTableViewController.swift',
          'AddEditEmojiTableViewController.swift', 'Main.storyboard', 'LaunchScreen.storyboard',
          'Assets.xcassets', 'Info.plist']:
    check(f in present, f'pbxproj referencia {f}')
    check(os.path.exists(os.path.join(SRC, f)), f'ficheiro do pbxproj existe no grupo EmojiDictionary: {f}')
check('INFOPLIST_FILE = EmojiDictionary/Info.plist;' in pbx, 'INFOPLIST_FILE aponta para EmojiDictionary/Info.plist')
for f in ['AppDelegate.swift', 'SceneDelegate.swift', 'Emoji.swift', 'EmojiTableViewController.swift',
          'AddEditEmojiTableViewController.swift']:
    check(f'{f} in Sources' in pbx, f'{f} na fase Sources')
for f in ['Main.storyboard', 'LaunchScreen.storyboard', 'Assets.xcassets']:
    check(f'{f} in Resources' in pbx, f'{f} na fase Resources')
check('PRODUCT_BUNDLE_IDENTIFIER = com.example.EmojiDictionary;' in pbx, 'PRODUCT_BUNDLE_IDENTIFIER definido')
check('SWIFT_VERSION = 5.0;' in pbx, 'SWIFT_VERSION = 5.0')
check('IPHONEOS_DEPLOYMENT_TARGET = 16.0;' in pbx, 'IPHONEOS_DEPLOYMENT_TARGET = 16.0')

print('== 6. alvo de testes, scheme e CI ==')
TESTS = os.path.join(ROOT, 'EmojiDictionaryTests', 'EmojiDictionaryTests.swift')
SCHEME = os.path.join(ROOT, 'EmojiDictionary.xcodeproj', 'xcshareddata', 'xcschemes', 'EmojiDictionary.xcscheme')
WF = os.path.join(ROOT, '.github', 'workflows', 'ios-simulator.yml')

check(os.path.isfile(TESTS), 'existe EmojiDictionaryTests/EmojiDictionaryTests.swift')
check(os.path.isfile(SCHEME), 'existe o scheme partilhado EmojiDictionary.xcscheme')
check(os.path.isfile(WF), 'existe .github/workflows/ios-simulator.yml')

src_tests = read(TESTS) if os.path.isfile(TESTS) else ''
check('@testable import EmojiDictionary' in src_tests, 'os testes importam o módulo da app (@testable)')
check('class EmojiDictionaryTests: XCTestCase' in src_tests, 'classe XCTestCase presente')
check(src_tests.count('func test') >= 8, f'pelo menos 8 testes (tem {src_tests.count("func test")})')
for api in ['Emoji.sampleEmojis', 'EmojiTableViewController', 'EmojiTableViewCell', 'AddEditEmojiTableViewController',
            'unwindToEmojiTableView', 'textEditingChanged', 'saveButton', 'symbolTextField', 'usageTextField',
            'indexPathForSelectedRow', 'automaticDimension', 'editButtonItem']:
    check(api in src_tests, f'os testes exercitam {api}')
    check(api in src_tvc or api in src_add or api in src_model, f'{api} existe no código da app')

# o identifier usado pelos testes tem de existir no storyboard
check('"AddEditNav"' in src_tests, 'os testes instanciam a cena pelo identifier AddEditNav')
check('storyboardIdentifier="AddEditNav"' in read(SB), 'a cena Add/Edit do storyboard tem storyboardIdentifier="AddEditNav"')

check('com.apple.product-type.bundle.unit-test' in pbx, 'pbxproj tem um alvo de testes unitários')
check('EmojiDictionaryTests.swift in Sources' in pbx, 'o ficheiro de testes está na fase Sources do alvo de testes')
check('TEST_HOST = "$(BUILT_PRODUCTS_DIR)/EmojiDictionary.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/EmojiDictionary";' in pbx,
      'TEST_HOST aponta para a app')
check('BUNDLE_LOADER = "$(TEST_HOST)";' in pbx, 'BUNDLE_LOADER definido')
check('TestTargetID = AA0000000000000000000002;' in pbx, 'o alvo de testes está ligado à app (TestTargetID)')
check('EmojiDictionaryTests.xctest' in pbx, 'o produto .xctest está declarado')

scheme = read(SCHEME) if os.path.isfile(SCHEME) else ''
check('BlueprintIdentifier = "AA0000000000000000000025"' in scheme, 'o scheme corre o alvo de testes na TestAction')
check('BlueprintIdentifier = "AA0000000000000000000002"' in scheme, 'o scheme compila a app')
check('<TestAction' in scheme and '<LaunchAction' in scheme, 'o scheme tem TestAction e LaunchAction')

wf = read(WF) if os.path.isfile(WF) else ''
for frag, label in [('runs-on: macos', 'CI corre num runner macOS'),
                    ('xcodebuild build', 'CI compila o projecto'),
                    ('xcodebuild test', 'CI corre os testes no simulador'),
                    ('simctl boot', 'CI arranca um simulador de iPhone'),
                    ('simctl install', 'CI instala a app no simulador'),
                    ('simctl launch', 'CI arranca a app no simulador'),
                    ('simctl io', 'CI tira screenshots do simulador'),
                    ('upload-artifact', 'CI publica as imagens/testes como artefacto')]:
    check(frag in wf, label)

print('== 7. testes de interface (XCUITest) ==')
UITESTS = os.path.join(ROOT, 'EmojiDictionaryUITests', 'EmojiDictionaryUITests.swift')
check(os.path.isfile(UITESTS), 'existe EmojiDictionaryUITests/EmojiDictionaryUITests.swift')
src_ui = read(UITESTS) if os.path.isfile(UITESTS) else ''
check('class EmojiDictionaryUITests: XCTestCase' in src_ui, 'classe XCTestCase dos testes de interface')
check(src_ui.count('func test') >= 7, f'pelo menos 7 testes de interface (tem {src_ui.count("func test")})')
for api, label in [('XCUIApplication()', 'arranca a app (XCUIApplication)'),
                   ('app.launch()', 'faz launch da app'),
                   ('XCUIScreen.main.screenshot()', 'tira screenshots do ecrã'),
                   ('XCTAttachment(screenshot:', 'anexa as imagens ao relatório de testes'),
                   ('typeText(', 'escreve nos campos (usa as opções)'),
                   ('.tap()', 'toca nos botões (usa as opções)'),
                   ('swipeLeft()', 'faz swipe para apagar'),
                   ('thenDragTo:', 'arrasta para reordenar')]:
    check(api in src_ui, f'os testes de interface: {label}')
check('buttons["Add"]' in src_ui, 'toca no botão + da barra')
check('navigationBars["Add Emoji"]' in src_ui and 'navigationBars["Edit Emoji"]' in src_ui, 'verifica os títulos das duas cenas do formulário')
check('isEnabled' in src_ui, 'verifica o estado activo/desactivado do Save')
check('cells().count' in src_ui, 'conta as células da lista')

check('com.apple.product-type.bundle.ui-testing' in pbx, 'pbxproj tem alvo de testes de interface (ui-testing)')
check('TEST_TARGET_NAME = EmojiDictionary;' in pbx, 'TEST_TARGET_NAME aponta para a app')
check('EmojiDictionaryUITests.swift in Sources' in pbx, 'o ficheiro de UI tests está na fase Sources')
check('EmojiDictionaryUITests.xctest' in pbx, 'o produto .xctest de interface está declarado')
check(pbx.count('TestTargetID = AA0000000000000000000002;') == 2, 'ambos os alvos de teste estão ligados à app')
check('AA0000000000000000000035 /* Build configuration list for PBXNativeTarget "EmojiDictionaryUITests" */' in pbx,
      'o alvo de UI tests tem lista de configurações')
check(scheme.count('<TestableReference') == 2, 'o scheme corre os dois alvos de teste')
check('BlueprintIdentifier = "AA0000000000000000000034"' in scheme, 'o scheme inclui o alvo de testes de interface')
check('recordVideo' in wf, 'CI grava vídeo do simulador durante os testes')
check('xcresulttool export attachments' in wf, 'CI extrai os screenshots do relatório de testes')
check('EmojiDictionary-app.zip' in wf, 'CI empacota o .app (para abrir no Appetize.io)')

print()
print(f'verificações: {checks}   falhas: {len(fails)}')
if fails:
    print('FALHAS:')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('RESULTADO: tudo verificado ✔')
