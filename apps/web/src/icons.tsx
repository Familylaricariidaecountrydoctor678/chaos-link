/* eslint-disable react-refresh/only-export-components */
import {
  ArrowUp,
  Check,
  CirclePause,
  Crosshair,
  Keyboard,
  LogOut,
  RefreshCcw,
  RotateCcw,
  ShieldAlert,
  Sun,
  Sword,
  Trash2,
  Volume2,
  Wifi,
  WifiOff,
} from 'lucide-react'

export const effectIcons: Record<string, typeof Sword> = {
  knife: Sword,
  reload: RotateCcw,
  jump: ArrowUp,
  drop_weapon: Trash2,
  mouse_jerk: Crosshair,
  hold_ctrl: CirclePause,
  block_wasd: Keyboard,
  flash: Sun,
  screamer: Volume2,
}

export { Check, LogOut, RefreshCcw, ShieldAlert, Wifi, WifiOff }
