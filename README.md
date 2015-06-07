# Coiffeur

![Coiffeur icon](Coiffeur/rsrc/scissors-512.png =128x)

Coiffeur is a style sheets editor for both [uncrustify](http://uncrustify.sourceforge.net) and [clang-format](http://clang.llvm.org/docs/ClangFormat.html).   

![screenshot](images/screenshot.png)

You change the style sheet parameters and you immediately see the changes reflected in a sample source code file. 

On this screesnot you see the changes after I toggled from **remove** to **add** in the **Add or remove space in 'template <' vs 'template<'.** option. Coiffeur runs **uncrustiy** in the background, displayes the newly formatted document, and highlights where the changes have been made. 

## Requirements

Mac OS X 10.9+.

## Suggested Use

Use Coiffeur with the excellent XCode [BBUncrustifyPlugin](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode).

## Dependencies

The [Fragaria](http://www.mugginsoft.com/code/fragaria) framework for code syntax highlighting. The [Diff, Match, and Patch](https://github.com/JanX2/google-diff-match-patch-Objective-C) framework for recognizing the changes in the source code between edits. Both are included into the repository as submodules.

## Creator 

[Anton Leuski](https://github.com/leuski)

## License

Coiffeur is available under Apache v.2 license. See LICENSE file for info.

 