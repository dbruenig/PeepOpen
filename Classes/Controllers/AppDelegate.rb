# AppDelegate.rb
# FuzzyWindow
#
# Created by Geoffrey Grosenbach on 3/20/10.
# Copyright 2010 Topfunky Corporation. All rights reserved.

class AppDelegate

  attr_accessor :fuzzyWindowController, :preferencesWindowController, :welcomeWindowController, :releaseNotesWindowController, :statusMenu, :aboutWindowController

  def self.registrationDefaults
    {
      "editorApplicationName" => "TextMate",
      "maximumDocumentCount"  => 1000,
      "scmShowMetadata" => true,
      "scmGitDiffAgainst" => "Current",
      "directoryIgnoreRegex" => '^(\.git|\.hg|\.svn|\.sass-cache|build|tmp|log|vendor\/(rails|gems|plugins))',
      "fileIgnoreRegex" => '(\.#.+|\.DS_Store|\.svn|\.png|\.jpe?g|\.gif|\.elc|\.rbc|\.pyc|\.swp|\.psd|\.ai|\.pdf|\.mov|\.aep|\.dmg|\.zip|\.gz|~)$',
      "projectRootRegex" => '^(\.git|\.hg|Rakefile|Makefile|README\.?.*|build\.xml|.*\.xcodeproj)$',
      "useCoreAnimation" => true,
      "showStatusBarMenu" => true
    }
  end

  def applicationWillFinishLaunching(aNotification)
    NSUserDefaults.standardUserDefaults.registerDefaults(AppDelegate.registrationDefaults)
  end

  def applicationDidFinishLaunching(aNotification)
    if NSUserDefaults.standardUserDefaults.boolForKey("showStatusBarMenu")
      createStatusBarMenu
    end
    # HACK: Load window and immediately close it so menu validation
    # doesn't accidentally show it.
    # fuzzyWindowController.window.close

    # Force loading of help index for searching
    NSHelpManager.sharedHelpManager

    unless NSUserDefaults.standardUserDefaults.boolForKey("hasBeenRunAtLeastOnce")
      showWelcome(self)
    end
  end

  def createStatusBarMenu
    statusItem =
      NSStatusBar.systemStatusBar.statusItemWithLength(NSVariableStatusItemLength)
    statusItem.setMenu(statusMenu)
    statusItem.setHighlightMode(true)
    statusItem.setToolTip("PeepOpen")
    statusItem.setImage(NSImage.imageNamed("statusItemIcon.png"))
  end

  ##
  # Do something with the dropped file.

  def application(sender, openFile:path)
    fuzzyWindowController.show(self)
    fuzzyWindowController.loadFilesFromProjectRoot(path)
  end

  def showPreferences(sender)
    # TODO: If visible
    if fuzzyWindowController.respondsToSelector(:close)
      fuzzyWindowController.close
    end
    if !@preferencesWindowController
      self.preferencesWindowController =
        windowControllerForNib("PreferencesWindow")
    end
    preferencesWindowController.show(self)
  end

  def showWelcome(sender)
    self.welcomeWindowController =
      windowControllerForNib("WelcomeWindow")
    welcomeWindowController.show(self)
  end

  def showReleaseNotesWindow(sender)
    if fuzzyWindowController.respondsToSelector(:close)
      fuzzyWindowController.close
    end
    if !@releaseNotesWindowController
      self.releaseNotesWindowController =
        windowControllerForNib("ReleaseNotesWindow")
    end
    releaseNotesWindowController.show(self)
  end

  def showSupportSite(sender)
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString("http://github.com/topfunky/peepopen-issues/issues"))
  end

  def showAbout(sender)
    if fuzzyWindowController.respondsToSelector(:close)
      fuzzyWindowController.close
    end
    if (!aboutWindowController)
      self.aboutWindowController = windowControllerForNib("AboutWindow")
    end
    aboutWindowController.show(self)
  end

  def refreshFileList(sender)
    fuzzyWindowController.refreshFileList(sender)
  end

  ##
  # Returns true if the menu item should be enabled.

  def validateMenuItem(menuItem)
    case menuItem.title
    when "Reload Files"
      if @fuzzyWindowController && @fuzzyWindowController.window.isVisible
        return true
      else
        return false
      end
    end
    return true
  end

  private

  ##
  # Watch filesystem for changes so new files can be indexed automatically.
  
  def setupFSEventListener(thePaths)
    # HACK: Disable until fully implemented and reliable
    return
    
    # TODO: Needs to be able to watch several paths and distinguish between them.
    # Scenarios: Switch projects. Should it keep watching the inactive project or just upon return?
    #            Should the model watch files or just the controller or AppDelegate?
    
    events = SCEvents.sharedPathWatcher
    events.setDelegate(self)
      
    # excludePaths = [NSMutableArray arrayWithObject:[NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"]];
    # Set the paths to be excluded
    # events.setExcludedPaths(excludePaths)
    
    # Start receiving events
    events.stopWatchingPaths
    events.startWatchingPaths(thePaths)

    if ENV["TF_VISUAL_DEBUG"]
      # Display a description of the stream
      NSLog("%@", events.streamDescription)
    end
  end

  ##
  # Take action on directories that have changed recently.

  def pathWatcher(pathWatcher, eventOccurred:event)
    # NSLog("%@", event)
  end

  # Given +nibName+, allocate and initialize the appropriate window
  # controller for the NIB.
  def windowControllerForNib nibName
    klass = Object.const_get "#{nibName}Controller"
    klass.alloc.initWithWindowNibName(nibName)
  end

  def fuzzyWindowController
    @fuzzyWindowController ||= windowControllerForNib("FuzzyWindow")
  end

end

