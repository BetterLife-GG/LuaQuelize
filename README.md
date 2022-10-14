# LuaQuelize

LuaQuelize is an Object-relational mapper for FiveM (inspired by Sequelize).

---

This project is already in early beta state, not ready for production wide yet. If you want to contribute, please contact me.

Maintainer: maicek\_ @ BetterLife.GG

## Current limitations

- Force sync allows to create only one column at time, needs to rework alter table logic.
- Every table needs to have primary key, even if it's not used. For now all interactions with MySQL are using WHERE {primaryKey} = {value} to identify records.
- Not all data types are supported yet, i personally don't need them for this state of project, will be added later.

## Features

- [x] OOP (Object-oriented programming)
- [x] MySQL support - only (maybe only for now, idk)
- [x] Models
- [ ] Native associations (not yet)
- [ ] Transactions (not yet)
- [ ] Hooks (not yet)
- [ ] Validations (not yet)
- [ ] Querying (not yet)
- [ ] Logging (not yet)
- [ ] Ingame menu for debugging/performance (not yet)

## Installation

`todo`

## Usage

`todo`

## License

MIT

## Credits

[overextended/oxmysql](https://github.com/overextended/oxmysql) - some javascript code was inspired
[sequelize/sequelize](https://github.com/sequelize/sequelize) - inspiration for the project, some code was ported to lua
