Calldata for `forwarder.execute(request, signature)`

**Function: `execute(Request calldata request, bytes calldata signature)`**

**Calldata Breakdown:**

**Word 0 (Bytes 0x00 - 0x1F)**
`0x44d46c8e00000000000000000000000000000000000000000000000000000000`
  - Bytes 0-3: `0x44d46c8e` (Function selector for `execute(Request,bytes)`)
  - Bytes 4-31: Padding

**Word 1 (Bytes 0x20 - 0x3F)** (Start of arguments block for `execute`)
`0x0000000000000000000000000000000000000000000000000000000000000040`
  - Offset to `Request` struct data (0x40 bytes from start of arguments block, so at absolute calldata offset `0x20 + 0x40 = 0x60`)

**Word 2 (Bytes 0x40 - 0x5F)**
`0x0000000000000000000000000000000000000000000000000000000000000260`
  - Offset to `signature` bytes data (0x260 bytes from start of arguments block, so at absolute calldata offset `0x20 + 0x260 = 0x280`)

--- `Request` Struct Data (Starts at absolute offset 0x60) ---
`struct Request { address from; address target; uint256 value; uint256 gas; uint256 nonce; bytes data; uint256 deadline; }`
Static part of `Request` struct is 7 * 32 = 224 bytes.

**Word 3 (Bytes 0x60 - 0x7F)**
`0x00000000000000000000000044e97af4418b7a17aabd8090bea0a471a366305c` (`Request.from` - player address)

**Word 4 (Bytes 0x80 - 0x9F)**
`0x000000000000000000000000ff2bd636b9fc89645c2d336aeade2e4abafe1ea5` (`Request.target` - pool address)

**Word 5 (Bytes 0xA0 - 0xBF)**
`0x0000000000000000000000000000000000000000000000000000000000000000` (`Request.value` - 0 ETH)

**Word 6 (Bytes 0xC0 - 0xDF)**
`0x000000000000000000000000000000000000000000000000000000003fff342e` (`Request.gas` - gas limit for the call)

**Word 7 (Bytes 0xE0 - 0xFF)**
`0x0000000000000000000000000000000000000000000000000000000000000000` (`Request.nonce` - 0)

**Word 8 (Bytes 0x100 - 0x11F)**
`0x00000000000000000000000000000000000000000000000000000000000000e0` (`Request.data` offset - pointer to data for `Request.data` field, 0xE0 bytes from start of `Request` struct data, so at `0x60 + 0xE0 = 0x140`)

**Word 9 (Bytes 0x120 - 0x13F)**
`0x0000000000000000000000000000000000000000000000000000000000015180` (`Request.deadline` - timestamp)

--- `Request.data` Content (Starts at absolute offset 0x140) ---
This is a `bytes` field. The content is the calldata for `pool.multicall(callDatas)`.
Total length of `Request.data` content is 260 bytes.

**Word 10 (Bytes 0x140 - 0x15F)**
`0x0000000000000000000000000000000000000000000000000000000000000104` (Length of `Request.data` content - 260 bytes = 0x104)

The 260 bytes of `Request.data` content (calldata for `multicall`) start at absolute offset 0x160.
`multicall` calldata structure: `selector (4B) || offset_to_callDatas_array (32B) || callDatas_array_length (32B) || offset_to_callDatas[0] (32B) || callDatas[0]_length (32B) || callDatas[0]_data (100B) || callDatas[0]_padding (28B)`

**Word 11 (Bytes 0x160 - 0x17F)**
`0xac9650d800000000000000000000000000000000000000000000000000000000`
  - Bytes 0x160-0x163: `ac9650d8` (Function selector for `multicall(bytes[])`)
  - Bytes 0x164-0x17F: First 28 bytes of "offset to `callDatas` array data" (value `0x00...0020`). These are all zeros.

**Word 12 (Bytes 0x180 - 0x19F)**
`0x0000002000000000000000000000000000000000000000000000000000000001`
  - Bytes 0x180-0x183: Last 4 bytes of "offset to `callDatas` array data" (`00000020`). (Offset points to `0x164 + 0x20 = 0x184`)
  - Bytes 0x184-0x19F: First 28 bytes of "`callDatas` array length" (value `0x00...0001`). These are all zeros.

**Word 13 (Bytes 0x1A0 - 0x1BF)**
`0x0000000000000000000000000000000000000000000000000000000000000020`
  - Bytes 0x1A0-0x1A3: Last 4 bytes of "`callDatas` array length" (`00000001`).
  - Bytes 0x1A4-0x1BF: First 28 bytes of "offset to `callDatas[0]` content" (value `0x00...0020`). These are all zeros. (Offset points to `0x1A4 + 0x20 = 0x1C4`)

**Word 14 (Bytes 0x1C0 - 0x1DF)**
`0x0000000000000000000000000000000000000000000000000000000000000064`
  - Bytes 0x1C0-0x1C3: Last 4 bytes of "offset to `callDatas[0]` content" (`00000020`).
  - Bytes 0x1C4-0x1DF: First 28 bytes of "`callDatas[0]` length" (value `0x00...0064` = 100 bytes). These are all zeros.

**Word 15 (Bytes 0x1E0 - 0x1FF)**
`0x0000000000f714ce000000000000000000000000000000000000003635c9adc5dea00000`
  - Bytes 0x1E0-0x1E3: Last 4 bytes of "`callDatas[0]` length" (`00000064`).
  - Bytes 0x1E4-0x1E7: `00f714ce` (Function selector for `withdraw(uint256,address)`)
  - Bytes 0x1E8-0x1FF: First 24 bytes of `amount` for `withdraw` (`00...003635c9adc5dea00000`).

**Word 16 (Bytes 0x200 - 0x21F)**
`0x00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea`
  - Bytes 0x200-0x207: Last 8 bytes of `amount` for `withdraw`.
  - Bytes 0x208-0x21F: First 24 bytes of `recovery address` for `withdraw`.

**Word 17 (Bytes 0x220 - 0x23F)**
`0x000000000000000000000000ae0bdc4eeac5e950b67c6819b118761caaf61946`
  - Bytes 0x220-0x227: Last 8 bytes of `recovery address` for `withdraw`.
  - Bytes 0x228-0x23F: First 24 bytes of `deployer address` (appended to `callDatas[0]`).

**Word 18 (Bytes 0x240 - 0x25F)**
`0x0000000000000000000000000000000000000000000000000000000000000000`
  - Bytes 0x240-0x247: Last 8 bytes of `deployer address`.
  - Bytes 0x248-0x25F: First 24 bytes of padding for `callDatas[0]` data (28 bytes total padding needed for 100-byte data).

**Word 19 (Bytes 0x260 - 0x27F)**
`0x0000000000000000000000000000000000000000000000000000000000000000`
  - Bytes 0x260-0x263: Last 4 bytes of padding for `callDatas[0]` data. (This completes the 28 bytes of padding, making `callDatas[0]` encoded length 128 bytes. End of `Request.data` content is at 0x263).
  - Bytes 0x264-0x27F: Inter-parameter padding (28 bytes) before the `signature` data block.

--- `Signature` Data Block (Starts at absolute offset 0x280) ---
This is a `bytes` field, so the first 32 bytes is its length.

**Word 20 (Bytes 0x280 - 0x29F)**
`0x0000000000000000000000000000000000000000000000000000000000000041` (Length of signature - 65 bytes = 0x41)

Actual signature data starts here (at absolute offset 0x2A0). This data is 65 bytes long.

**Word 21 (Bytes 0x2A0 - 0x2BF)**
`0x594f8118f2b46ab55e306619e41e8847d386654661191e0af480b5a985823dda` (Signature `r` - 32 bytes)

**Word 22 (Bytes 0x2C0 - 0x2DF)**
`0x59550f11b5468eb049d7762d1b8eea44f6d0338449425fb166b635784cb5b873` (Signature `s` - 32 bytes)

**Word 23 (Bytes 0x2E0 - 0x2FF)**
`0x1c00000000000000000000000000000000000000000000000000000000000000`
  - Byte 0x2E0: `1c` (Signature `v` - 1 byte)
  - Bytes 0x2E1-0x2FF: Padding for signature data (31 zero bytes to make its encoded length 96 bytes: 65 data + 31 padding)
End of calldata.