{-# LANGUAGE ScopedTypeVariables #-}

import           System.IO
import           XMonad
-- import           XMonad.Actions.WindowGo          (runOrRaise)
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.EwmhDesktops        (ewmh)
import           XMonad.Hooks.ManageDocks
import           XMonad.Layout.IndependentScreens
import           XMonad.Layout.MouseResizableTile
import           XMonad.Layout.Spacing
import           XMonad.Util.EZConfig             (additionalKeysP)
import           XMonad.Util.Run                  (spawnPipe)
import           XMonad.Util.SpawnOnce            (spawnOnce)
import qualified Debug.Trace as Debug (trace)

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "feh --bg-scale ~/Pictures/wallpaper.png &"
  spawnOnce "brave"
  spawnOnce "gnome-terminal"
  spawnOnce "emacs"
  spawnOnce "nautilus"
  spawnOnce "signal-desktop"
  spawnOnce "env XDG_CURRENT_DESKTOP=GNOME gnome-control-center"

myModMask            = mod4Mask                        -- Sets modkey to super/windows key
myTerminal           = "gnome-terminal"
myTextEditor         = "emacs"                         -- Sets default text editor
myBorderWidth        = 2                               -- Sets border width for windows
myNormalBorderColor  = "#4a4a4a"
myFocusedBorderColor = "#7fff00"

mySpacing = spacingRaw True (Border 0 10 10 10) True (Border 10 10 10 10) True

myManageHook = composeAll
   [ className =? "brave-browser" --> doShift "2"
   , className =? "Org.gnome.Nautilus" --> doShift "3"
   , className =? "Emacs" --> doShift "1"
   , className =? "Gnome-control-center" --> doShift "4"
   , className =? "Signal" --> doShift "6"
   , manageDocks
   ]

main = do
  -- xmproc <- spawnPipe "tee -a ~/.cache/xmonad/xmobar.log | xmobar"
  xmproc <- spawnPipe "tee -a ~/.xmobar.log | xmobar"
  xmonad . ewmh . docks $ def
      { manageHook = myManageHook <+> manageHook def
      , layoutHook = avoidStruts . mySpacing $ layoutHook def
      , handleEventHook = handleEventHook def -- <+> docksEventHook
      , logHook = dynamicLogWithPP xmobarPP
                      { ppOutput = hPutStrLn xmproc
                      , ppTitle = xmobarColor "darkgreen" "" . shorten 20
                      }
      , startupHook        = myStartupHook
      , modMask            = myModMask     -- Rebind Mod to the Windows key
      , borderWidth        = myBorderWidth
      , normalBorderColor  = myNormalBorderColor
      , focusedBorderColor = myFocusedBorderColor
      , terminal           = myTerminal
      } `additionalKeysP`
      [ ("M-q", restart "xmonad" True)
      , ("<Print>", spawn "scrot -e \'mv $f ~/Pictures/Screenshots\'")
      , ("M-i", spawn $ unwords
          [ "bash -c '"
          , "exec 2>>~/.cache/xmonad/ocrshot.log;"
          , "set -x;"
          , "echo \"=== OCR attempt at $(date) ===\" >>~/.cache/xmonad/ocrshot.log;"
          , "mkdir -p ~/.cache/xmonad;"
          , "sleep 0.2;"
          , "scrot -s -o /tmp/ocr.png"
          , "&& tesseract /tmp/ocr.png - | xclip -selection clipboard"
          , "&& rm -f /tmp/ocr.png;"
          , "EXIT=$?;"
          , "echo \"Exit code: $EXIT\" >>~/.cache/xmonad/ocrshot.log;"
          , "echo \"===\" >>~/.cache/xmonad/ocrshot.log"
          , "'"
          ]
        )
      -- , ("M-c", spawn "scrot -s /tmp/ocr.png && tesseract /tmp/ocr.png - | xclip -selection clipboard && rm /tmp/ocr.png")
      -- , ("M-u", spawn "brightnessctl set 5%-") -- decrease brightness
      -- , ("M-i", spawn "brightnessctl set +5%") -- increase brightness
      , ("M-j", spawn "amixer -q sset Master 2%-")
      , ("M-k", spawn "amixer -q sset Master 2%+")
      , ("M-m", spawn "amixer set Master toggle")
      ]
