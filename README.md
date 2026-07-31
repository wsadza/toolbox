<div align="center">

   <!-- logo -->
   <div style="width: 100%; height: auto; background-color: black;">
      <img src="./.media/assets/badges/assets_badges_project.png" width="100%" height="auto"/>      
   </div>
   <br>
  
   <!-- labels -->
   <img src="https://labl.es/svg?text=Docker&width=200&bgcolor=a93226" align="center" style="margin: 5px"/>
   <img src="https://labl.es/svg?text=Toolbox&width=200&bgcolor=1e8449" align="center" style="margin: 5px"/>
   
</div>

<!---
 /$$$$$$$$                  /$$ /$$                          
|__  $$__/                 | $$| $$                          
   | $$  /$$$$$$   /$$$$$$ | $$| $$$$$$$   /$$$$$$  /$$   /$$
   | $$ /$$__  $$ /$$__  $$| $$| $$__  $$ /$$__  $$|  $$ /$$/
   | $$| $$  \ $$| $$  \ $$| $$| $$  \ $$| $$  \ $$ \  $$$$/ 
   | $$| $$  | $$| $$  | $$| $$| $$  | $$| $$  | $$  >$$  $$ 
   | $$|  $$$$$$/|  $$$$$$/| $$| $$$$$$$/|  $$$$$$/ /$$/\  $$
   |__/ \______/  \______/ |__/|_______/  \______/ |__/  \__/
                                                             
--->
# Toolbox 
<img src="https://api.dicebear.com/9.x/identicon/svg?seed=toolbox" align="left" width="7%" height="auto"/>

Toolbox is .. 

##
<!---
#####################################################
# TL;DR
#####################################################
--->
<h3 id="tldr">
   $\large\color{Goldenrod}{\textbf{TL;DR}}$
</h3>

> [!NOTE]  
> Minimal Debian image that utilizes software rendering ([LLVMpipe](https://docs.mesa3d.org/drivers/llvmpipe.html])), suitable for WSL / Native linux instances.

```sh
docker run -d -p 8080:8080 -p 3478:3478/udp -p 3478:3478/tcp -p 9091:9091 -e STREAMER_HOST=$(hostname -I | awk '{print $1}') ghcr.io/wsadza/metal/minimal-debian:latest && sleep 10 && echo -e "\n\tApplication: http://$(hostname -I | awk '{print $1}'):8080" && echo -e "\tSupervisor: http://$(hostname -I | awk '{print $1}'):9091\n"
```

<!---
$$$$$$$\  $$$$$$$\  $$$$$$$$\ $$\    $$\ $$$$$$\ $$$$$$$$\ $$\      $$\ 
$$  __$$\ $$  __$$\ $$  _____|$$ |   $$ |\_$$  _|$$  _____|$$ | $\  $$ |
$$ |  $$ |$$ |  $$ |$$ |      $$ |   $$ |  $$ |  $$ |      $$ |$$$\ $$ |
$$$$$$$  |$$$$$$$  |$$$$$\    \$$\  $$  |  $$ |  $$$$$\    $$ $$ $$\$$ |
$$  ____/ $$  __$$< $$  __|    \$$\$$  /   $$ |  $$  __|   $$$$  _$$$$ |
$$ |      $$ |  $$ |$$ |        \$$$  /    $$ |  $$ |      $$$  / \$$$ |
$$ |      $$ |  $$ |$$$$$$$$\    \$  /   $$$$$$\ $$$$$$$$\ $$  /   \$$ |
\__|      \__|  \__|\________|    \_/    \______|\________|\__/     \__|
--->
## Preview
<div align="center">
   <sup><code>It was easy, right?</code></sup>
   <br>
   <br>
   <div style="width: 800; height: auto; background-color: black;">
   <img src="./.media/previews/previews_installation.gif" width="800" height="auto"/>
   </div>      
</div>


<!---
$$$$$$$$\  $$$$$$\   $$$$$$\  
\__$$  __|$$  __$$\ $$  __$$\ 
   $$ |   $$ /  $$ |$$ /  \__|
   $$ |   $$ |  $$ |$$ |      
   $$ |   $$ |  $$ |$$ |      
   $$ |   $$ |  $$ |$$ |  $$\ 
   $$ |    $$$$$$  |\$$$$$$  |
   \__|    \______/  \______/
--->
## Table Of Contents:
- [Installation](#installation)
- [Configuration](#configuration)
- [Miscellaneous](#miscellaneous)

<!---
  /$$$$$$             /$$$$$$   /$$                                                
 /$$__  $$           /$$__  $$ | $$                                                
| $$  \__/  /$$$$$$ | $$  \__//$$$$$$   /$$  /$$  /$$  /$$$$$$   /$$$$$$   /$$$$$$ 
|  $$$$$$  /$$__  $$| $$$$   |_  $$_/  | $$ | $$ | $$ |____  $$ /$$__  $$ /$$__  $$
 \____  $$| $$  \ $$| $$_/     | $$    | $$ | $$ | $$  /$$$$$$$| $$  \__/| $$$$$$$$
 /$$  \ $$| $$  | $$| $$       | $$ /$$| $$ | $$ | $$ /$$__  $$| $$      | $$_____/
|  $$$$$$/|  $$$$$$/| $$       |  $$$$/|  $$$$$/$$$$/|  $$$$$$$| $$      |  $$$$$$$
 \______/  \______/ |__/        \___/   \_____/\___/  \_______/|__/       \_______/
                                                                                   
--->

## Software 
<sup>[(Back to Top)](#table-of-contents)</sup><br>

Toolbox is shipped with..

<!---
 $$$$$$\   $$$$$$\  $$\   $$\ $$$$$$$$\ $$$$$$\  $$$$$$\  $$\   $$\ $$$$$$$\   $$$$$$\ $$$$$$$$\ $$$$$$\  $$$$$$\  $$\   $$\ 
$$  __$$\ $$  __$$\ $$$\  $$ |$$  _____|\_$$  _|$$  __$$\ $$ |  $$ |$$  __$$\ $$  __$$\\__$$  __|\_$$  _|$$  __$$\ $$$\  $$ |
$$ /  \__|$$ /  $$ |$$$$\ $$ |$$ |        $$ |  $$ /  \__|$$ |  $$ |$$ |  $$ |$$ /  $$ |  $$ |     $$ |  $$ /  $$ |$$$$\ $$ |
$$ |      $$ |  $$ |$$ $$\$$ |$$$$$\      $$ |  $$ |$$$$\ $$ |  $$ |$$$$$$$  |$$$$$$$$ |  $$ |     $$ |  $$ |  $$ |$$ $$\$$ |
$$ |      $$ |  $$ |$$ \$$$$ |$$  __|     $$ |  $$ |\_$$ |$$ |  $$ |$$  __$$< $$  __$$ |  $$ |     $$ |  $$ |  $$ |$$ \$$$$ |
$$ |  $$\ $$ |  $$ |$$ |\$$$ |$$ |        $$ |  $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |  $$ |     $$ |  $$ |  $$ |$$ |\$$$ |
\$$$$$$  | $$$$$$  |$$ | \$$ |$$ |      $$$$$$\ \$$$$$$  |\$$$$$$  |$$ |  $$ |$$ |  $$ |  $$ |   $$$$$$\  $$$$$$  |$$ | \$$ |
 \______/  \______/ \__|  \__|\__|      \______| \______/  \______/ \__|  \__|\__|  \__|  \__|   \______| \______/ \__|  \__|
--->

## Configuration
<sup>[(Back to Top)](#table-of-contents)</sup><br>

<img src=".media/assets/sections/assets_sections_d.png" align="left" width="5%" height="auto"/>

This section highlights the two main components of configuring the <code>Kubeforge</code> controller: first, the general Helm chart description, and second, the controller-specific configuration. The latter covers both the source configuration and the overlay configuration, providing full examples of overlays for provisioning Banana and Apple pods.

### Table Of Contents:
  - $\large\color{Goldenrod}{\textbf{Configuration}}$
     - [Configuration - `Helm`](./.docs/30_configuration/CONFIGURATION.md#configuration---helm)
     - [Configuration - `Overlay`](./.docs/30_configuration/CONFIGURATION.md#configuration---overlay)

<!---
$$$$$$$\  $$$$$$$\  $$$$$$$$\ $$\    $$\ $$$$$$\ $$$$$$$$\ $$\      $$\ 
$$  __$$\ $$  __$$\ $$  _____|$$ |   $$ |\_$$  _|$$  _____|$$ | $\  $$ |
$$ |  $$ |$$ |  $$ |$$ |      $$ |   $$ |  $$ |  $$ |      $$ |$$$\ $$ |
$$$$$$$  |$$$$$$$  |$$$$$\    \$$\  $$  |  $$ |  $$$$$\    $$ $$ $$\$$ |
$$  ____/ $$  __$$< $$  __|    \$$\$$  /   $$ |  $$  __|   $$$$  _$$$$ |
$$ |      $$ |  $$ |$$ |        \$$$  /    $$ |  $$ |      $$$  / \$$$ |
$$ |      $$ |  $$ |$$$$$$$$\    \$  /   $$$$$$\ $$$$$$$$\ $$  /   \$$ |
\__|      \__|  \__|\________|    \_/    \______|\________|\__/     \__|
--->
<h2>Preview</h2>
<div align="center">
   <sup><code>Sequences! We love sequences, right?</code></sup>
   <br>
   <br>
   <div style="width: 600; height: auto; background-color: black;">
      <img src="./.media/previews/previews_sequence.png" align="center" width="600" height="auto"/>   
   </div>
</div>

<!---
$$\      $$\ $$$$$$\  $$$$$$\   $$$$$$\  
$$$\    $$$ |\_$$  _|$$  __$$\ $$  __$$\ 
$$$$\  $$$$ |  $$ |  $$ /  \__|$$ /  \__|
$$\$$\$$ $$ |  $$ |  \$$$$$$\  $$ |      
$$ \$$$  $$ |  $$ |   \____$$\ $$ |      
$$ |\$  /$$ |  $$ |  $$\   $$ |$$ |  $$\ 
$$ | \_/ $$ |$$$$$$\ \$$$$$$  |\$$$$$$  |
\__|     \__|\______| \______/  \______/
--->
## Miscellaneous
<sup>[(Back to top)](#table-of-contents)</sup>

<img src="./.media/assets/sections/assets_sections_f.png" align="left" width="5%" height="auto"/>

The "Miscellaneous" section gathers various resources and content that may not belong to a specific category but are still valuable and worth referencing. It's a place for extra tools, tips, and information that support a wide range of needs.

### Table Of Contents:
- $\large\color{Goldenrod}{\textbf{Helpful Resources}}$
   - [Controller Patterns](./.docs/50_miscellaneous/MISCELLANEOUS.md#helpful-resources---controller-patterns)
   - [TODO List](./.docs/50_miscellaneous/MISCELLANEOUS.md#helpful-resources---todo-list)
- [Document Template](./.docs/50_miscellaneous/DOCUMENT_TEMPLATE.md)

<br>
<br>
<div align="center">
   <img src="./.media/assets/badges/assets_badges_project_backgroundless.png" width="15%" height="auto"/>
</div>
