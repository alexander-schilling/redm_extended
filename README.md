# RedM Extended [RDX]
![RedM Extended](https://i.imgur.com/OEjfYF0.jpg)

redm_extended is a roleplay framework for RedM, original code is from es_extended based on FiveM. The to-go framework for creating an economy based roleplay server on RedM!
This fork is customized to fit some of the changes that I've made, like multi-character support, and merging some functions made by different projects.

ESX was initially developed by Gizz back in 2017, later on developed and improved by ESX-Org.
All credits go to ESX-Org for all the work they had in the original framework (es_extended).
RDX was initially developed by ThymonA.
All credits go to him for the work made in this custom frawework for RedM.
extendedmode is a community edition fork of es_extended (better known as ESX) and is maintained by various trusted members of the FiveM community.
Some of the changes made are included in this fork, all the credits go to them.
RedEM: Roleplay is an Advanced roleplay framework for RedEM developed by amakuu and kanersps.
Some functions and natives implementations are from that project, all credits go to them.

## Links & Read more
- [RDX Framework Documentation](https://rdx-framework.cfx.digital/)
- [RedM Native Reference](https://vespura.com/doc/natives/)
- [RDX Menu Default](https://github.com/alexander-schilling/rdx_menu_default)
- [RDX Menu Dialog](https://github.com/alexander-schilling/rdx_menu_dialog)
- [Async RedM](https://github.com/TigoDevelopment/redm-async/tree/master)
- [MySQL Async](https://github.com/brouznouf/fivem-mysql-async)
- [RDX Identity](https://github.com/alexander-schilling/rdx_identity)
- [RDX Framework Discord](https://discord.gg/HScTyEt)

## Features
- Multi character support
- Weight based inventory system
- Weapons support
- Supports different money accounts (defaulted with cash, bank and black money)
- Job system with grades
- Easy to use API for developers to easily integrate RDX to their projects
- Register your own commands easily, with argument validation, chat suggestion and using FXServer ACL

## Setup
```
set mysql_connection_string "mysql://user:password@location/database"

add_ace resource.redm_extended command.add_ace allow
add_ace resource.redm_extended command.add_principal allow
add_ace resource.redm_extended command.remove_principal allow

ensure spawnmanager
ensure mapmanager
ensure sessionmanager-rdr3
ensure chat
ensure yarn

ensure async
ensure mysql-async
ensure redm_extended
ensure rdx_menu_default
ensure rdx_menu_dialog
ensure rdx_identity
```

## Screenshots
![RedM-Extended](https://i.imgur.com/Ijczndn.jpg)
![RedM-Extended](https://i.imgur.com/amlwgHj.jpg)
