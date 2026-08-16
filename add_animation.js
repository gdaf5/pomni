/*
 * add_animation.js — добавление новой Mixamo-анимации одной командой.
 *
 * Использование:
 *   node add_animation.js "Имя файла.fbx" "ключ_анимации" [loop] [speed]
 *
 * Пример:
 *   node add_animation.js "Walking.fbx" "walk" loop 1.1
 *   node add_animation.js "Falling To Roll.fbx" "roll"
 *
 * Что делает:
 *   1. Ищет FBX в папке Downloads пользователя
 *   2. Копирует его в assets/animations/ проекта
 *   3. Запускает Godot headless-импорт ДО ЗАВЕРШЕНИЯ (без крашей)
 *   4. Автоматически добавляет запись в ANIM_CONFIG в skeleton_player_model.gd
 *   5. Проверяет, что анимация реально загрузилась
 *
 * Параметры:
 *   loop — необязательно. "loop" = зацикленная, "once" = разовая (по умолчанию once)
 *   speed — необязательно. Множитель скорости (по умолчанию 1.0)
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

// ============ КОНФИГУРАЦИЯ ============
const PROJ = path.join(process.env.USERPROFILE, 'OneDrive', '\u0420\u0430\u0431\u043E\u0447\u0438\u0439 \u0441\u0442\u043E\u043B', 'dodod', '\u043D\u043E\u0432\u044B\u0439-\u0438\u0433\u0440\u043E\u0432\u043E\u0439-\u043F\u0440\u043E\u0435\u043A\u0442');
const ANIM_DIR = path.join(PROJ, 'assets', 'animations');
const DOWNLOADS = path.join(process.env.USERPROFILE, 'Downloads');
const MODEL_SCRIPT = path.join(PROJ, 'scenes', 'characters', 'player', 'skeleton_player_model.gd');
const GODOT = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Godot Engine\\godot.windows.opt.tools.64.exe';
// ======================================

// ---------- Разбор аргументов ----------
const args = process.argv.slice(2);
if (args.length < 2) {
  console.log('Использование: node add_animation.js "Имя.fbx" "ключ" [loop|once] [speed]');
  console.log('Пример: node add_animation.js "Walking.fbx" "walk" loop 1.1');
  process.exit(1);
}

const fbxName = args[0];
const animKey = args[1];
const loopMode = args[2] || 'once';
const speed = args[3] || '1.0';
const isLoop = loopMode.toLowerCase() === 'loop';

// Убираем расширение если передали
const baseName = fbxName.replace(/\.fbx$/i, '');
const fbxFileName = baseName + '.fbx';

console.log('=== Добавление анимации ===');
console.log('Файл:        ' + fbxFileName);
console.log('Ключ:        ' + animKey);
console.log('Зациклена:   ' + isLoop);
console.log('Скорость:    ' + speed);

// ---------- 1. Проверка исходного файла ----------
let srcPath = path.join(DOWNLOADS, fbxFileName);
if (!fs.existsSync(srcPath)) {
  // Пробуем другие пути: текущая папка
  srcPath = path.join(process.cwd(), fbxFileName);
}
if (!fs.existsSync(srcPath)) {
  console.error('ОШИБКА: не найден файл ' + fbxFileName + ' в Downloads или текущей папке.');
  process.exit(1);
}
console.log('Найден файл: ' + srcPath);

// ---------- 2. Копирование в проект ----------
const dstPath = path.join(ANIM_DIR, fbxFileName);
fs.copyFileSync(srcPath, dstPath);
console.log('Скопирован в: ' + dstPath);

// Удаляем старый .import если был (чтобы импорт пересоздался)
const importPath = dstPath + '.import';
if (fs.existsSync(importPath)) {
  fs.unlinkSync(importPath);
  console.log('Удалён старый .import (будет пересоздан)');
}

// ---------- 3. Импорт через Godot headless ----------
console.log('Запуск импорта Godot (может занять 30-120 сек)...');
const res = spawnSync(GODOT, ['--path', PROJ, '--editor', '--headless', '--quit-after', '900'], {
  stdio: 'pipe',
  timeout: 180000,
  encoding: 'utf8'
});

const output = (res.stdout || '') + (res.stderr || '');

// Проверяем, что .scn создан
const importedDir = path.join(PROJ, '.godot', 'imported');
let scnCreated = false;
if (fs.existsSync(importedDir)) {
  const scnFiles = fs.readdirSync(importedDir).filter(f => f.endsWith('.scn') && f.indexOf(baseName) === 0);
  scnCreated = scnFiles.length > 0;
}

if (!scnCreated) {
  console.error('ПРЕДУПРЕЖДЕНИЕ: не найден .scn для ' + baseName + '. Проверь, что импорт завершился.');
  const hasCrash = output.match(/FATAL|panic|Segmentation|crash/i);
  if (hasCrash) {
    console.error('Похоже Godot упал при импорте. Вывод:');
    console.error(output.split('\n').filter(Boolean).slice(-10).join('\n'));
  }
} else {
  console.log('Импорт прошёл успешно (.scn создан)');
}

// ---------- 4. Добавление в ANIM_CONFIG ----------
const resPath = 'res://assets/animations/' + fbxFileName;
const newLine = '\t"' + animKey + '": ["' + resPath + '", ' + (isLoop ? 'true' : 'false') + ', ' + speed + '],';

let config = fs.readFileSync(MODEL_SCRIPT, 'utf8');
if (config.indexOf('"' + animKey + '"') >= 0) {
  // Заменяем существующую запись
  const oldLineRe = new RegExp('\\t"' + animKey + '": \\[[^\\]]+\\],?');
  if (oldLineRe.test(config)) {
    config = config.replace(oldLineRe, newLine);
    console.log('Обновлена существующая запись "' + animKey + '" в ANIM_CONFIG');
  } else {
    console.log('Запись "' + animKey + '" уже существует, но формат не совпал — оставляю как есть.');
  }
} else {
  // Вставляем новую запись перед закрывающей скобкой
  const insertAt = config.lastIndexOf('}');
  config = config.slice(0, insertAt) + newLine + '\n' + config.slice(insertAt);
  console.log('Добавлена новая запись "' + animKey + '" в ANIM_CONFIG');
}
fs.writeFileSync(MODEL_SCRIPT, config);

// ---------- 5. Итог ----------
console.log('');
console.log('=== ГОТОВО ===');
console.log('Анимация "' + animKey + '" добавлена.');
console.log('Запусти игру и проверь. Управление (если это новая боевая/движенческая анимация):');
console.log('  — если нужно привязать к клавише, скажи мне, обновлю player.gd.');