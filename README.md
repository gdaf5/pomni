# DODOD

Экшен-игра на Godot 4.7.1 (Windows). Бой мечом и автоматом от третьего лица, персонаж с Mixamo-анимациями, меню → выбор персонажа → арена → порталы в полянку и подземелье.

## Запуск

- Godot 4.7.1: открыть `project.godot` или запустить `godot.windows.opt.tools.64.exe --path <эта папка>`.
- Главная сцена: `res://scenes/ui/main_menu.tscn`.
- Отрисовка: GL Compatibility (`gl_compatibility`), физика: Jolt Physics.

## Структура

- `scenes/ui/` — меню, HUD, инвентарь.
- `scenes/world/` — локации (`world` арена, `meadow` полянка, `dungeon` подземелье), порталы, сундук, ловушки, лут.
- `scenes/characters/player/` — игрок (`player.tscn` — кастом, `player_skeleton.tscn` — скелет).
- `scenes/characters/dummy/` — враги/манекены.
- `scenes/vfx/` — эффекты (удар, частицы, урон).
- `scripts/` — общая логика: GameManager, предметы, оружие, порталы, сборщик анимаций.

## Ключевые системы

- **GameManager** (`scripts/game_manager.gd`, autoload) — состояние игрока между сценами (HP, стамина, оружие) + инвентарь (`add_item/remove_item/use_item`, сигнал `inventory_changed`).
- **Предметы** (`scripts/items.gd`) — класс `ItemDefinition`, каталог: зелья HP/стамины, монеты, самоцветы, костяной ключ.
- **Инвентарь** — клавиша **T**, панель `scenes/ui/inventory_ui.tscn` (сетка 5 колонок, описание, использование ENTER/E, Esc — закрыть). Пока открыт, управление игроком блокируется (`input_locked`).
- **Порталы** (`scripts/portal.gd`) — Area3D, телепорт между сценами с сохранением состояния игрока.
- **Сундук** (`scenes/world/treasure_chest.gd`) — выдаёт лут в инвентарь (зелья + монеты).
- **Враги** (`scenes/characters/dummy/dummy.gd`) — экспорты: `max_health`, `display_name`, `attack_damage`, `respawns`, `loot_on_death`, `loot_table`. При смерти роняют лут (`scenes/world/pickup.tscn`).
- **Оружие**: меч (`sword_weapon.gd`) и автомат (`assault_rifle_weapon.gd`) на базе `weapon_base.gd`.

## Управление (в игре)

- WASD — движение, Shift — спринт, Пробел — прыжок
- Q/Alt — кувырок (i-frames), 1/2 — меч/автомат
- ЛКМ — удар/стрельба, ПКМ — сильный удар / прицел
- R — перезарядка, F — блок (меч), B — танец, T — инвентарь, Esc — курсор

## Анимации и импорт

- FBX-анимации Mixamo в `assets/animations/`.
- Для импорта новой анимации используется `add_animation.js` (Node): `node add_animation.js "Name.fbx" "key" [loop|once] [speed]`.
- В импортах FBX-анимаций задано `fbx/embedded_image_handling=0`.
- Папку `.godot/` в git НЕ пушить (в `.gitignore`).

## Тестирование

- Проверка сцен headless: `godot --headless --path . res://scenes/world/world.tscn --quit-after 30`.
- Сценарные тесты — временные `*.gd`-скрипты (SceneTree), запуск: `godot --headless --path . --script <файл>`.

## Важно

- Путь проекта на кириллице: `C:\Users\User\OneDrive\Рабочий стол\dodod\новый-игровой-проект`.
- При работе через AI-агента: не удалять `.godot/` вручную, коммитить только осмысленные изменения.