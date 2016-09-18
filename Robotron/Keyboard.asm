; Keys are listed in order from bit 4 (left) to bit 0 (right).

; Example of use:
;       ld bc, PortShiftZXCV
;       in a, (c)
;       and KeyZMask
;       jr z, ZKeyPressed

PortShiftZXCV           equ $fefe
PortASDFG               equ $fdfe
PortQWERT               equ $fbfe
Port12345               equ $f7fe
Port09876               equ $effe
PortPOIUY               equ $dffe
PortEnterLKJH           equ $bffe
PortSpaceSymMNB         equ $7ffe

KeyVMask                equ %00010000
KeyCMask                equ %00001000
KeyXMask                equ %00000100
KeyZMask                equ %00000010
KeyShiftMask            equ %00000001

KeyGMask                equ %00010000
KeyFMask                equ %00001000
KeyDMask                equ %00000100
KeySMask                equ %00000010
KeyAMask                equ %00000001

KeyTMask                equ %00010000
KeyRMask                equ %00001000
KeyEMask                equ %00000100
KeyWMask                equ %00000010
KeyQMask                equ %00000001

Key5Mask                equ %00010000
Key4Mask                equ %00001000
Key3Mask                equ %00000100
Key2Mask                equ %00000010
Key1Mask                equ %00000001

Key6Mask                equ %00010000
Key7Mask                equ %00001000
Key8Mask                equ %00000100
Key9Mask                equ %00000010
Key0Mask                equ %00000001

KeyYMask                equ %00010000
KeyUMask                equ %00001000
KeyIMask                equ %00000100
KeyOMask                equ %00000010
KeyPMask                equ %00000001

KeyHMask                equ %00010000
KeyJMask                equ %00001000
KeyKMask                equ %00000100
KeyLMask                equ %00000010
KeyEnterMask            equ %00000001

KeyBMask                equ %00010000
KeyNMask                equ %00001000
KeyMMask                equ %00000100
KeySymMask              equ %00000010
KeySpaceMask            equ %00000001

