> [!WARNING]  
> _This project is in active development!  Proceed at your own risk!_

***

<div align="center">
 
 <h1>
   <span style="font-family: system-ui, -apple-system, sans-serif; font-weight: 800; font-size: 50px; color: #ffffff; letter-spacing: -1px; vertical-align: middle;">Aethr</span>
 </h1>
  
 <p align="center" style="margin-top: 10px; margin-bottom: 15px;">
   <span style="font-size: 16px; color: #a3a8ce; font-family: system-ui, -apple-system, sans-serif;">A modular, bar-less shell for Quickshell on Hyprland.</span>
 </p>
  
 <p align="center">
   <a href="https://archlinux.org"><img src="https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux" /></a>&nbsp;
   <a href="https://hyprland.org"><img src="https://img.shields.io/badge/Hyprland-33CCFF?style=for-the-badge&logo=hyprland&logoColor=white" alt="Hyprland" /></a>&nbsp;
   <a href="https://github.com/outfoxxed/quickshell"><img src="https://img.shields.io/badge/Quickshell-41CD52?style=for-the-badge&logo=qt&logoColor=white" alt="Quickshell" /></a>
 </p>
 <br>
</div>

A modular shell with no persistent bar, built for Quickshell on Hyprland.

Why "Aethr"? Aethr represents the invisible, transient layer of the interface. By eschewing a persistent bar, this shell stays out of your way until you need it—using hover-proximity and intelligent triggers to summon docks and trays, leaving your workspace completely clear.

<img width="1920" height="1080" alt="01" src="https://github.com/user-attachments/assets/b90c2336-5b69-417f-8a80-4dabb4811303" />

<img width="1920" height="1080" alt="02" src="https://github.com/user-attachments/assets/38279eb3-c90e-4c1c-bd10-1f42096151ac" />

<img width="1920" height="1080" alt="03" src="https://github.com/user-attachments/assets/89bbdb23-d7ef-4660-ab53-8093e148814c" />

<div align="center"><img height="300" alt="05" src="https://github.com/user-attachments/assets/7864ee13-16cb-499f-878e-838e695b73ee" />&nbsp;<img height="300" alt="04" src="https://github.com/user-attachments/assets/0aaa47da-e79b-47e4-b2ea-dc226142fe9e" /></div>

<div align="center"><img width="966" height="511" alt="06" src="https://github.com/user-attachments/assets/7f1fb60c-f5d7-4182-a520-890dc69695a9" /></div>

## Installation & Deployment

An automated deployment script is included:


    git clone https://github.com/natepayn3/Aethr.git
    cd Aethr
    chmod +x install.sh
    ./install.sh

Add the following rule to your hyprland.lua for blur:

    -- Combined rule handles all quickshell layer panels (Bar, Settings HUD, etc.)
    hl.layer_rule({
        name         = "quickshell-all",
        match        = { namespace = "^quickshell-.*" },
        blur         = true,
        xray         = false,
        ignore_alpha = 0,
    })

### Wallpaper controls

The wallpaper picker uses awww and supports animated wallpapers as well as ctrl+clicking for single wallpaper changes on multi-monitor setups.

### IPC Handlers

Once deployed, you can interact with or toggle the shell layout elements cleanly via the command line or desktop keybinds:

- Toggle App Launcher: qs -c Aethr ipc call launcher toggle
- Toggle Workspace Overview: qs -c Aethr ipc call overview toggle

## Star History

<a href="https://www.star-history.com/?repos=natepayn3%2FAethr&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=natepayn3/Aethr&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=natepayn3/Aethr&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=natepayn3/Aethr&type=date&legend=top-left" />
 </picture>
</a>
