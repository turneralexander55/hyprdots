# hyprdots

A reproducible, Arch Linux–based Hyprland desktop environment with a clean separation between
system provisioning, configuration deployment, and user customization.

This repository is designed to be:
- Safe to run on fresh installs
- Explicit about destructive actions
- Re-runnable without breaking the system
- Easy to reason about and extend

---

## Philosophy

This repo intentionally separates concerns:

- **System provisioning** (packages, dependencies)
- **Configuration deployment** (copy-once defaults)
- **Advanced workflows** (optional symlink mode)

Nothing happens implicitly.  
Anything destructive is guarded and opt-in.

This structure reflects real-world infrastructure and DevOps best practices.

---

Install with:

git clone https://github.com/turneralexander55/hyprdots.git ~/hyprdots
cd ~/hyprdots
chmod +x scripts/*.sh
./scripts/install.sh


## Repository Structure
