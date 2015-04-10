//
//  BorderlessTextView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class BorderlessTextView : NSTextView {

  override func awakeFromNib()
  {
    self.textContainerInset = NSSize(width: 0, height: 0)
    self.textContainer!.lineFragmentPadding = 0
  }
}
