### ASCII control characters

| Dec | Hex | Name | Abbrev. | Modern computing usage |
|---:|---:|---|---|---|
| 0 | `00` | **NUL** | `NUL` | Null byte. C string terminators, binary padding, zero-filled memory, protocol fields. |
| 1 | `01` | **Start of Heading** | `SOH` | Legacy communications protocols; marks beginning of a message/header. Rare today. |
| 2 | `02` | **Start of Text** | `STX` | Legacy serial/packet protocols; marks beginning of payload text. |
| 3 | `03` | **End of Text** | `ETX` | Legacy communications; sometimes used as a packet terminator. |
| 4 | `04` | **End of Transmission** | `EOT` | Historically signals end of transmission. Unix terminals commonly use `Ctrl-D` for EOF instead. |
| 5 | `05` | **Enquiry** | `ENQ` | Requests a response/status from another device. Mostly legacy. |
| 6 | `06` | **Acknowledge** | `ACK` | Positive acknowledgment in communication protocols. |
| 7 | `07` | **Bell** | `BEL` | Terminal alert. `\a` in C; may cause a terminal notification/beep. |
| 8 | `08` | **Backspace** | `BS` | Moves cursor one position backward. |
| 9 | `09` | **Horizontal Tab** | `HT` / `TAB` | Tab character. `\t`; indentation and column separation in text. |
| 10 | `0A` | **Line Feed** | `LF` | New line on Unix/Linux/macOS. `\n`; also part of Windows CRLF. |
| 11 | `0B` | **Vertical Tab** | `VT` | Vertical cursor movement. Very rarely used today. |
| 12 | `0C` | **Form Feed** | `FF` | Page break in printers; historically used to advance to next page. |
| 13 | `0D` | **Carriage Return** | `CR` | Return cursor to beginning of line. Used with LF in Windows (`CRLF`). |
| 14 | `0E` | **Shift Out** | `SO` | Select alternate character set. Mostly obsolete. |
| 15 | `0F` | **Shift In** | `SI` | Return to primary character set. Mostly obsolete. |
| 16 | `10` | **Data Link Escape** | `DLE` | Escapes control sequences in communications protocols. |
| 17 | `11` | **Device Control 1** | `DC1` | Commonly XON in software flow control. |
| 18 | `12` | **Device Control 2** | `DC2` | Device-specific control. Rare today. |
| 19 | `13` | **Device Control 3** | `DC3` | Commonly XOFF in software flow control. |
| 20 | `14` | **Device Control 4** | `DC4` | Device-specific control. Rare today. |
| 21 | `15` | **Negative Acknowledge** | `NAK` | Negative response in communication protocols. |
| 22 | `16` | **Synchronous Idle** | `SYN` | Maintains synchronization on synchronous communications links. |
| 23 | `17` | **End of Transmission Block** | `ETB` | Marks end of a transmission block. Legacy communications. |
| 24 | `18` | **Cancel** | `CAN` | Cancels a message/operation in communication protocols. |
| 25 | `19` | **End of Medium** | `EM` | Indicates physical end of a medium. Mostly historical. |
| 26 | `1A` | **Substitute** | `SUB` | Replacement for an invalid/corrupted character. `Ctrl-Z` has special meanings in some systems. |
| 27 | `1B` | **Escape** | `ESC` | Terminal escape sequences, ANSI colors, cursor control, keyboard Escape key. |
| 28 | `1C` | **File Separator** | `FS` | Hierarchical data separator. Rare modern use. |
| 29 | `1D` | **Group Separator** | `GS` | Separates groups of records. Rare modern use. |
| 30 | `1E` | **Record Separator** | `RS` | Separates records. Rare modern use. |
| 31 | `1F` | **Unit Separator** | `US` | Separates fields/units within records. Rare modern use. |
| 127 | `7F` | **Delete** | `DEL` | Historically punched a character out of paper tape; today associated with Delete/terminal input behavior. |
