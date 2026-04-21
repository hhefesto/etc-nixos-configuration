{-# LANGUAGE ScopedTypeVariables #-}

import           System.IO
import           XMonad
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.EwmhDesktops        (ewmh)
import           XMonad.Hooks.ManageDocks
import           XMonad.Layout.IndependentScreens
import           XMonad.Layout.MouseResizableTile
import           XMonad.Layout.Spacing
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
                        , ppTitle = xmobarColor "green" "" . shorten @xmonadShortenLength@
                        }
        , startupHook        = myStartupHook
        , modMask            = myModMask     -- Rebind Mod to the Windows key
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormalBorderColor
        , focusedBorderColor = myFocusedBorderColor
        , terminal           = myTerminal
        } `additionalKeysP`
        [ ("<Print>", spawn "touch /tmp/print-test")
        , ("M-<Print>", spawn "sh -lc 'mkdir -p ~/Pictures/Screenshots; f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png; scrot -s \"$f\"; s=$?; echo $(date) scrot=$s file=$f >> /tmp/xmonad-print.log; env | grep -E \\\"DBUS|XDG_RUNTIME_DIR|DISPLAY\\\" >> /tmp/xmonad-print.log; if [ $s -eq 0 ]; then notify-send Screenshot \"$f\"; n=$?; echo notify=$n >> /tmp/xmonad-print.log; else notify-send \"scrot failed\"; n=$?; echo notify=$n >> /tmp/xmonad-print.log; fi'")
        , ("M-c", spawn "scrot -s /tmp/ocr.png && tesseract /tmp/ocr.png - | xclip -selection clipboard && rm /tmp/ocr.png")
        , ("<XF86MonBrightnessUp>", spawn "brightnessctl set 5%+")
        , ("<XF86MonBrightnessDown>", spawn "brightnessctl set 5%-")
        , ("M-y", spawn "brightnessctl set 1") -- set to minimum brightness
        , ("M-j", spawn "amixer -q sset Master 2%- && notify-send Volume \"$(amixer get Master | grep -o '[0-9]*%' | head -1)\"")
        , ("M-k", spawn "amixer -q sset Master 2%+ && notify-send Volume \"$(amixer get Master | grep -o '[0-9]*%' | head -1)\"")
        , ("M-m", spawn "amixer set Master toggle")
        , ("M-q", restart "/run/current-system/sw/bin/xmonad" True)
        ]
