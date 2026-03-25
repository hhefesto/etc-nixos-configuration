{-# LANGUAGE ScopedTypeVariables #-}

import           System.IO
import           XMonad.Main                      (launch)
import           XMonad.Core                      (Directories(..))
import           XMonad
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.EwmhDesktops        (ewmh)
import           XMonad.Hooks.ManageDocks
import           XMonad.Layout.IndependentScreens
import           XMonad.Layout.MouseResizableTile
import           XMonad.Layout.Spacing
import           XMonad.Util.EZConfig             (additionalKeysP
                                                  ,additionalKeys
                                                  )
import           XMonad.Util.Run                  (spawnPipe)
import           XMonad.Util.SpawnOnce            (spawnOnce)
import qualified Debug.Trace as Debug

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "nautilus"
  spawnOnce "brave"
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
   [ className =? "Emacs" --> doShift "1"
   , className =? "brave-browser" --> doShift "2"
   , className =? "Org.gnome.Nautilus" --> doShift "3"
   , className =? "Emacs" --> doShift "1"
   , className =? "Gnome-control-center" --> doShift "4"
   , className =? "Signal" --> doShift "6"
   , manageDocks
   ]

main = do
    xmproc <- spawnPipe "xmobar"
    xmonad . ewmh . docks $ def
        { manageHook = myManageHook <+> manageHook def
        , layoutHook = avoidStruts . mySpacing $ layoutHook def
        , handleEventHook = handleEventHook def -- <+> docksEventHook
        , logHook = dynamicLogWithPP xmobarPP
                        { ppOutput = hPutStrLn xmproc
                        , ppTitle = xmobarColor "green" "" . shorten 30
                        }
        , startupHook        = myStartupHook
        , modMask            = myModMask     -- Rebind Mod to the Windows key
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormalBorderColor
        , focusedBorderColor = myFocusedBorderColor
        , terminal           = myTerminal
        } `additionalKeysP`
        [ ("<Print>", spawn "scrot -e \'mv $f ~/Pictures/Screenshots\'")
        , ("M-c", spawn "scrot -s /tmp/ocr.png && tesseract /tmp/ocr.png - | xclip -selection clipboard && rm /tmp/ocr.png")
        , ("<XF86MonBrightnessUp>", spawn "brightnessctl set 5%+")
        , ("<XF86MonBrightnessDown>", spawn "brightnessctl set 5%-")
        , ("M-y", spawn "brightnessctl set 1") -- set to minimum brightness
        , ("M-j", spawn "amixer -q sset Master 2%-")
        , ("M-k", spawn "amixer -q sset Master 2%+")
        , ("M-m", spawn "amixer set Master toggle")
        , ("M-q", restart "xmonad" True)
        ]
