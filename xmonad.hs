{-# LANGUAGE ScopedTypeVariables #-}

import           System.IO
import           XMonad
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.EwmhDesktops        (ewmh)
import           XMonad.Hooks.ManageDocks
import           XMonad.Layout.IndependentScreens
import           XMonad.Layout.MouseResizableTile
import           XMonad.Layout.Spacing
import           XMonad.Util.Brightness
import           XMonad.Util.EZConfig             (additionalKeysP)
import           XMonad.Util.Run                  (spawnPipe)
import           XMonad.Util.SpawnOnce            (spawnOnce)

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "nautilus"
  spawnOnce "brave"
  spawnOnce "feh --bg-scale ~/Pictures/wallpaper.png &"
  spawnOnce "gnome-terminal"
  spawnOnce "emacs"
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
                        , ppTitle = xmobarColor "darkgreen" "" . shorten 20
                        }
        , startupHook        = myStartupHook
        , modMask            = myModMask     -- Rebind Mod to the Windows key
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormalBorderColor
        , focusedBorderColor = myFocusedBorderColor
        , terminal           = myTerminal
        } `additionalKeysP`
        [ ("<Print>", spawn "scrot -e \'mv $f ~/Pictures/Screenshots\'")
        , ("M-u", liftIO $ change (\i -> i - 10) >> pure ()) -- decrease brightness
        , ("M-i", liftIO $ change (\i -> i + 10) >> pure ()) -- increase brightness
        , ("M-y", setBrightness 1) -- set to minimum brightness
        , ("M-j", spawn "amixer -q sset Master 2%-")
        , ("M-k", spawn "amixer -q sset Master 2%+")
        , ("M-m", spawn "amixer set Master toggle")
        ]
