# AI CLEANUP GUIDE

**Decrypted by AK Leaks Decryptor Bot V2** | Discord: https://discord.gg/6NCbAv2VNK

---

## How to Use

This code has been decompiled and has **`[AI-FIX]` comments** marking issues.

**Upload ONE Lua file to ChatGPT/Claude with this prompt:**

```
Clean this decompiled Lua code. Follow all [AI-FIX] comments:

1. Rename AKL/AKA variables to descriptive names
2. Remove goto statements, use if-else instead  
3. Fix redundant code (x=y; x=x.z becomes x=y.z)
4. Simplify comparisons (remove == true, fix false == x)
5. Add brief comments where needed

Keep function names unchanged. Only improve readability.
```

Then paste the file content below.

---

## Example

**Before:**
```lua
function AKL1_1(AKA0_2) -- [AI-FIX] Rename parameters
  if AKA0_2 == true then -- [AI-FIX] Redundant comparison
    goto lbl_52 -- [AI-FIX] Replace goto with if-else
  end
  ::lbl_52:: -- [AI-FIX] Remove label
end
```

**After:**
```lua
function InitResource(playerId)
  if playerId then
    -- Initialize resource logic
    SetupPlayer(playerId)
  end
end
```

---

## Tips

- Start with config files first
- Test after cleaning each file
- Don't change exported function names
- Remove this file when done

**Need help?** https://discord.gg/6NCbAv2VNK
