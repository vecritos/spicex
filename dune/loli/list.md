# Windows Hardening — 30‑Day Checklist

## Week 1 — Hardware & Firmware 🔧
- [ ] **Day 1:** Verify Secure Boot (`Confirm-SecureBootUEFI`) ✔️
- [ ] **Day 2:** Check BIOS/UEFI boot order 🔒
- [ ] **Day 3:** Set BIOS/UEFI password 🛡️
- [ ] **Day 4:** Check TPM status (`Get-TPM`) 🔍
- [ ] **Day 5:** Re-provision TPM (optional) ⚠️
- [ ] **Day 6:** Record firmware version 📝
- [ ] **Day 7:** Consider vendor firmware update 🧭

## Week 2 — OS & Accounts 🖥️
- [ ] **Day 8:** List local accounts (`Get-LocalUser`) 👤
- [ ] **Day 9:** Apply all Windows updates 🔄
- [ ] **Day 10:** Disable unneeded features/apps 🧹
- [ ] **Day 11:** Document essential applications 📋
- [ ] **Day 12:** Plan sandboxing (VM/container) 🧪
- [ ] **Day 13:** Limit admin account usage 🔐
- [ ] **Day 14:** Final OS sanity check ✔️

## Week 3 — Network & Services 🌐
- [ ] **Day 15:** List listening ports (`Get-NetTCPConnection -State Listen`) 🚨
- [ ] **Day 16:** List startup commands (`Get-CimInstance Win32_StartupCommand`) ⚙️
- [ ] **Day 17:** List scheduled tasks (`Get-ScheduledTask`) 📆
- [ ] **Day 18:** Configure inbound firewall (block by default) 🛑
- [ ] **Day 19:** Configure outbound firewall (allow essentials) 🎯
- [ ] **Day 20:** Monitor live connections (`Get-NetTCPConnection`) 👁️
- [ ] **Day 21:** Log unexpected connections 📦

## Week 4 — Secrets & Monitoring 🔐
- [ ] **Day 22:** Move critical secrets to secure storage
- [ ] **Day 23:** Enable BitLocker drive encryption 🔒
- [ ] **Day 24:** Review app permissions (camera/mic/etc.)
- [ ] **Day 25:** Configure audit logging 📊
- [ ] **Day 26:** Set up integrity checks 🧩
- [ ] **Day 27:** Review Event Viewer 🕵️
- [ ] **Day 28:** Verify offline backup plan 💾
- [ ] **Day 29:** Test recovery options (media, restore points) 🧭
- [ ] **Day 30:** Final review & documentation 🎉
