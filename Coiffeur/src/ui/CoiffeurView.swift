//
//  CoiffeurView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//

import Cocoa

class CoiffeurView: NSViewController {

  @IBOutlet weak var optionsView: OutlineView!
  @IBOutlet weak var jumpMenu: NSPopUpButton!
  @IBOutlet var optionsController: NSTreeController!

  private var rowHeightCache = [String: CGFloat]()

  private var observer: NSKeyValueObservation?

  override init(nibName nibNameOrNil: NSNib.Name? = NSNib.Name(rawValue: "CoiffeurView"),
                bundle nibBundleOrNil: Bundle? = nil)
  {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()

    observer = observe(\.optionsController.content, options: [.new]) {
      [weak self] _, _ in
      self?._finishSettingUpView()
      self?.observer = nil
    }
  }

  private func _finishSettingUpView()
  {
    self.optionsView.expandItem(nil, expandChildren: true)

    if let node: AnyObject = self.optionsController.firstLeaf  {
      self.optionsController.setSelectionIndexPath(node.indexPath)
    }

    for node in self.optionsController.nodes {
      if let section = node.representedObject as? ConfigSection {
        let item = NSMenuItem()
        item.title = section.title
        item.indentationLevel  = section.depth - 1
        item.representedObject = node
        self.jumpMenu.menu?.addItem(item)
      }
    }
  }

  @IBAction func jumpToSection(_ sender: AnyObject)
  {
    if let popup = sender as? NSPopUpButton {
      self.optionsView.scrollItemToVisible(
        popup.selectedItem?.representedObject)
    }
  }
}

extension CoiffeurView: NSOutlineViewDelegate {

  func outlineView(_ outlineView: NSOutlineView,
                   isGroupItem item: Any) -> Bool
  {
    if let node = (item as AnyObject).representedObject as? ConfigNode {
      return !node.leaf
    }
    return false
  }

  private func _rowViewIdentifierForItem(_ item: AnyObject) -> String?
  {
    if let node = item.representedObject as? ConfigNode {
      if node is ConfigOption {
        return "row.option"
      } else if node is ConfigSection {
        return "row.section"
      }
    }
    return nil
  }

  private func _cellViewIdentifierForItem(_ item: AnyObject) -> String?
  {
    if let node = item.representedObject as? ConfigNode {
      let tokens = node.tokens
      if tokens.count == 0 {
        return "view.section"
      } else if tokens.count == 1
        && tokens[0] == CoiffeurController.OptionType.signed.rawValue {
        return "view.signed"
      } else if tokens.count == 1
        && tokens[0] == CoiffeurController.OptionType.unsigned.rawValue {
        return "view.unsigned"
      } else if tokens.count == 1 {
        return "view.string"
      } else {
        return "view.choice"
      }
    }
    return nil
  }

  func outlineView(_ outlineView: NSOutlineView,
                   viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if
      let identifier = _cellViewIdentifierForItem(item as AnyObject),
      let view = outlineView.makeView(
        withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier),
        owner: self),
      let node = (item as AnyObject).representedObject as? ConfigNode
    {
      if let cell = view as? ConfigChoiceCellView, let segmented = cell.segmented {
        segmented.labels = node.tokens
      }
      if let cell = view as? ConfigOptionCellView {
        cell.leftMargin.constant = 8
      }
      return view
    }
    return nil
  }

  private func _outlineView(
    _ outlineView: NSOutlineView,
    heightOfRowByIdentifier identifier: String) -> CGFloat
  {
    if let height = rowHeightCache[identifier] {
      return height
    }
    if let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier),
                                       owner: self)
    {
      let height = view.frame.size.height
      if height > 0 {
        rowHeightCache[identifier] = height
        return height
      }
    }
    return 10
  }

  // this is a very, very, very frequently called method. We need to make it
  // as fast as possible. We cache the view height based on the cell
  // view identifier
  func outlineView(_ outlineView: NSOutlineView,
                   heightOfRowByItem item: Any) -> CGFloat
  {
    if let identifier = _cellViewIdentifierForItem(item as AnyObject),
      let rowIdentifier = _rowViewIdentifierForItem(item as AnyObject)
    {
      return _outlineView(outlineView, heightOfRowByIdentifier: identifier)
        + _outlineView(outlineView, heightOfRowByIdentifier: rowIdentifier)
    }
    return 10
  }

  func outlineView(_ outlineView: NSOutlineView,
                   shouldSelectItem item: Any) -> Bool
  {
    return !self.outlineView(outlineView, isGroupItem: item)
  }

  func outlineView(_ outlineView: NSOutlineView,
                   rowViewForItem item: Any) -> NSTableRowView?
  {
    if let identifier = _rowViewIdentifierForItem(item as AnyObject),
      let theNode = (item as AnyObject).representedObject as? ConfigNode,
      let container = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier),
                                           owner: self) as? ConfigRowView
    {
      container.locations = theNode.path
      container.textField.stringValue = theNode.title
      container.leftMargin.constant = (1.5
        + CGFloat(outlineView.level(forItem: item)))
        * outlineView.indentationPerLevel+4.0
      container.drawSeparator = theNode is ConfigSection
      //        || theNode.index == theNode.parent!.children.count-1
      if !container.drawSeparator {
        let row = outlineView.row(forItem: item) + 1
        if row < outlineView.numberOfRows {
          container.drawSeparator =
            (outlineView.item(atRow: row) as AnyObject).representedObject is ConfigSection
        }
      }
      return container
    } else {
      return nil
    }
  }

  // the row is added as the predicate changes. Restore the expanded state
  // from the model.
  // We do it asynchroniously, because node expansion
  // can lead to more rows being added to the view.
  func outlineView(_ outlineView: NSOutlineView,
                   didAdd rowView: NSTableRowView, forRow row: Int)
  {
    let item: AnyObject? = outlineView.item(atRow: row) as AnyObject
    if let section = item?.representedObject as? ConfigSection {
      if section.expanded {
        DispatchQueue.main.async {
          outlineView.animator().expandItem(item)
        }
      }
    }
  }

  private func _section(_ notification: Notification) -> ConfigSection? {
    return (notification.userInfo?["NSObject"] as AnyObject)
      .representedObject as? ConfigSection
  }

  // records the state of the node in the model
  func outlineViewItemDidExpand(_ notification: Notification)
  {
    _section(notification)?.expanded = true
  }

  func outlineViewItemDidCollapse(_ notification: Notification)
  {
    _section(notification)?.expanded = false
  }
}
