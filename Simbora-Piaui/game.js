const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");

const startScreen = document.getElementById("startScreen");
const startButton = document.getElementById("startButton");
const optionsButton = document.getElementById("optionsButton");
const marketplaceButton = document.getElementById("marketplaceButton");
const wardrobeButton = document.getElementById("wardrobeButton");
const menuModal = document.getElementById("menuModal");
const menuModalTitle = document.getElementById("menuModalTitle");
const menuModalBody = document.getElementById("menuModalBody");
const closeMenuModal = document.getElementById("closeMenuModal");
const hud = document.getElementById("hud");
const placeName = document.getElementById("placeName");
const scoreEl = document.getElementById("score");
const totalEl = document.getElementById("total");
const dialog = document.getElementById("dialog");
const dialogTitle = document.getElementById("dialogTitle");
const dialogText = document.getElementById("dialogText");
const answers = document.getElementById("answers");
const bagButton = document.getElementById("bagButton");
const collection = document.getElementById("collection");
const collectionList = document.getElementById("collectionList");
const closeCollection = document.getElementById("closeCollection");
const touchControls = document.getElementById("touchControls");
const moveButtons = document.querySelectorAll(".moveButton");
const actionButton = document.getElementById("actionButton");

const TILE = 48;
const WORLD_W = 58;
const WORLD_H = 30;
const VIEW_W = 960;
const VIEW_H = 540;
const ASSET_PATH = "elementos/";
const OPENING_MISSION_ID = "boas_vindas_picos";

const images = {
  hero: loadImage(`${ASSET_PATH}personagem_animacoes.jpeg`),
  logo: loadImage(`${ASSET_PATH}LOGO SIMBORA.png`),
  museumPicos: loadImage("godot/assets/museu_picos.png"),
  seuZe: loadImage("seu_ze_lendas.png")
};
const PLAYER_SPRITE = {
  columns: 4,
  rows: 4,
  width: 82,
  height: 112,
  sourceWidth: 220,
  sourceHeight: 300,
  sourceX: [167, 409, 648, 887],
  sourceY: [70, 360, 640, 918],
  rowByDir: { down: 0, left: 1, right: 2, up: 3 }
};

const keys = new Set();
const learned = new Set(JSON.parse(localStorage.getItem("simbora.learned") || "[]"));
const redeemed = new Set(JSON.parse(localStorage.getItem("simbora.redeemed") || "[]"));
const discovered = [];
const DEFAULT_SETTINGS = {
  musicVolume: 70,
  sfxVolume: 80,
  difficulty: "normal",
  touchControls: "auto",
  reducedMotion: false,
  outfit: "explorer"
};
const settings = {
  ...DEFAULT_SETTINGS,
  ...JSON.parse(localStorage.getItem("simbora.settings") || "{}")
};
const outfits = {
  explorer: { name: "Explorador", color: "#d96b28", description: "Camisa laranja clássica da jornada." },
  river: { name: "Azul de Picos", color: "#1b79b5", description: "Azul inspirado na cidade." },
  serra: { name: "Caatinga de Picos", color: "#2f8b4f", description: "Verde para trilhas e paisagens do municipio." },
  festa: { name: "Festa Popular", color: "#c7333f", description: "Vermelho vivo para a cultura popular." }
};

const player = {
  x: 6 * TILE,
  y: 18 * TILE,
  w: 30,
  h: 40,
  speed: 150,
  dir: "down",
  walk: 0
};

const camera = { x: 0, y: 0 };
const openingCamera = { x: 0 };
let running = false;
let animationStarted = false;
let activeDialog = null;
let last = 0;
let touchVector = { x: 0, y: 0 };
const activeMoveButtons = new Map();
let heroSprite = null;
let flashAlpha = 0;

const opening = {
  active: !learned.has(OPENING_MISSION_ID),
  phase: "fade",
  time: 0,
  playerX: -90,
  playerY: 0,
  memoryOpen: false,
  zeDialogReady: false,
  hint: "Toque no icone para registrar sua primeira memoria!"
};

const openingAudio = new Audio("audio_abertura_picos.mp3");
openingAudio.loop = true;
openingAudio.preload = "auto";

const missions = [{
  id: OPENING_MISSION_ID,
  name: "Bem-vindo a Picos",
  npc: "Seu Ze das Lendas",
  item: "Primeira Memoria",
  fact: "Voce sabia? Picos e um dos maiores entroncamentos rodoviarios do Nordeste e e famosa nacionalmente como a Capital do Mel!",
  question: "Opa, meu jovem! Seja muito bem-vindo a nossa querida Picos. Aqui cada rua tem uma historia e cada parada guarda um saber. Vamos comecar sua jornada pelo coracao da cidade?"
}];



const solids = new Set();
const water = new Set();
const museumPlaza = new Set();
const props = [];

buildWorld();
totalEl.textContent = missions.length;
updateHud();

function loadImage(src) {
  const img = new Image();
  img.src = src;
  return img;
}

images.hero.addEventListener("load", prepareHeroSprite);
if (images.hero.complete && images.hero.naturalWidth) prepareHeroSprite();

function prepareHeroSprite() {
  const sheet = document.createElement("canvas");
  sheet.width = images.hero.naturalWidth || images.hero.width;
  sheet.height = images.hero.naturalHeight || images.hero.height;
  const sheetCtx = sheet.getContext("2d");
  sheetCtx.drawImage(images.hero, 0, 0);

  heroSprite = sheet;
}

function tileKey(x, y) {
  return `${x},${y}`;
}

function addSolid(x, y) {
  solids.add(tileKey(x, y));
}

function addWater(x, y) {
  water.add(tileKey(x, y));
  solids.add(tileKey(x, y));
}

function buildWorld() {
  for (let x = 0; x < WORLD_W; x++) {
    addSolid(x, 0);
    addSolid(x, WORLD_H - 1);
  }
  for (let y = 0; y < WORLD_H; y++) {
    addSolid(0, y);
    addSolid(WORLD_W - 1, y);
  }

  addPicosBlock();
}

function addPicosBlock() {
  for (let x = 11; x <= 31; x++) {
    props.push({ type: "pathTile", x, y: 15 });
  }
  for (let y = 8; y <= 22; y++) {
    props.push({ type: "pathTile", x: 21, y });
  }

  [
    [12, 9], [16, 9], [26, 9], [30, 9],
    [12, 18], [16, 20], [26, 20], [30, 18],
    [18, 12], [24, 12], [18, 18], [24, 18]
  ].forEach(([x, y]) => addHouse(x, y));

  [
    [14, 13], [28, 13], [14, 22], [28, 22],
    [19, 10], [23, 10], [19, 21], [23, 21]
  ].forEach(([x, y]) => {
    props.push({ type: "bush", x, y });
  });

  addMuseumArea(29, 13);
}

function addMuseumArea(x, y) {
  const area = { left: 21, right: 55, top: 7, bottom: 24 };
  for (let tx = area.left; tx <= area.right; tx++) {
    for (let ty = area.top; ty <= area.bottom; ty++) {
      museumPlaza.add(tileKey(tx, ty));
      solids.delete(tileKey(tx, ty));
    }
  }
  for (let tx = 21; tx <= 24; tx++) {
    for (let ty = 12; ty <= 18; ty++) {
      museumPlaza.add(tileKey(tx, ty));
    }
  }
  for (let i = props.length - 1; i >= 0; i--) {
    const prop = props[i];
    if (prop.x >= area.left && prop.x <= area.right && prop.y >= area.top && prop.y <= area.bottom) {
      props.splice(i, 1);
    }
  }
  props.push({ type: "museumPicos", x, y });
  for (let tx = x - 3; tx <= x + 5; tx++) {
    for (let ty = y - 2; ty <= y + 2; ty++) {
      addSolid(tx, ty);
    }
  }
}

function addHouse(x, y) {
  props.push({ type: "house", x, y });
  addSolid(x, y);
  addSolid(x + 1, y);
}

function addRockCluster(sx, sy, w, h) {
  for (let x = sx; x < sx + w; x++) {
    for (let y = sy; y < sy + h; y++) {
      if (Math.abs(x - (sx + w / 2)) + Math.abs(y - (sy + h / 2)) < w / 1.6) {
        props.push({ type: "rock", x, y });
        addSolid(x, y);
      }
    }
  }
}

function addVillage(sx, sy) {
  const houses = [[0, 0], [3, -1], [5, 2]];
  houses.forEach(([hx, hy]) => {
    props.push({ type: "house", x: sx + hx, y: sy + hy });
    addSolid(sx + hx, sy + hy);
    addSolid(sx + hx + 1, sy + hy);
  });
}

function nearMission(x, y) {
  return missions.some(m => Math.abs(m.x - x) < 2 && Math.abs(m.y - y) < 2);
}

function resize() {
  const dpr = Math.max(1, Math.min(devicePixelRatio || 1, 2));
  canvas.width = Math.floor(innerWidth * dpr);
  canvas.height = Math.floor(innerHeight * dpr);
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}

addEventListener("resize", resize);
resize();

applySettings();

startButton.addEventListener("click", startGame);
optionsButton.addEventListener("click", showOptions);
marketplaceButton.addEventListener("click", showMarketplace);
wardrobeButton.addEventListener("click", showWardrobe);
closeMenuModal.addEventListener("click", closeMenuPanel);
menuModal.addEventListener("click", event => {
  if (event.target === menuModal) closeMenuPanel();
});

function startGame() {
  startScreen.classList.add("hidden");
  closeMenuPanel();
  hud.classList.remove("hidden");
  bagButton.classList.remove("hidden");
  if (shouldShowTouchControls()) {
    touchControls.classList.remove("hidden");
  }
  running = true;
  playOpeningMusic();
  if (!animationStarted) {
    animationStarted = true;
    requestAnimationFrame(loop);
  }
}

function shouldShowTouchControls() {
  if (settings.touchControls === "on") return true;
  if (settings.touchControls === "off") return false;
  return matchMedia("(pointer: coarse)").matches || innerWidth < 820;
}

function saveSettings() {
  localStorage.setItem("simbora.settings", JSON.stringify(settings));
}

function saveRedeemed() {
  localStorage.setItem("simbora.redeemed", JSON.stringify([...redeemed]));
}

function applySettings() {
  touchControls.classList.toggle("hidden", !running || !shouldShowTouchControls());
  document.body.classList.toggle("reducedMotion", settings.reducedMotion);
  player.speed = settings.difficulty === "easy" ? 130 : settings.difficulty === "hard" ? 172 : 150;
  openingAudio.volume = settings.musicVolume / 100;
}

function playOpeningMusic() {
  openingAudio.volume = settings.musicVolume / 100;
  openingAudio.play().catch(() => {});
}

function openMenuPanel(title, content) {
  menuModalTitle.textContent = title;
  menuModalBody.innerHTML = "";
  menuModalBody.appendChild(content);
  menuModal.classList.remove("hidden");
}

function closeMenuPanel() {
  menuModal.classList.add("hidden");
}

function showOptions() {
  const wrap = document.createElement("div");
  wrap.className = "settingsGrid";
  wrap.innerHTML = `
    <div class="settingRow">
      <div><label for="musicVolume">Volume da música</label><span>${settings.musicVolume}%</span></div>
      <input id="musicVolume" type="range" min="0" max="100" value="${settings.musicVolume}">
    </div>
    <div class="settingRow">
      <div><label for="sfxVolume">Volume dos efeitos</label><span>${settings.sfxVolume}%</span></div>
      <input id="sfxVolume" type="range" min="0" max="100" value="${settings.sfxVolume}">
    </div>
    <div class="settingRow">
      <div><label for="difficulty">Dificuldade</label><span>Define a velocidade da jornada.</span></div>
      <select id="difficulty">
        <option value="easy">Fácil</option>
        <option value="normal">Normal</option>
        <option value="hard">Difícil</option>
      </select>
    </div>
    <div class="settingRow">
      <div><label for="touchMode">Controles de toque</label><span>Útil para celular, tablet e notebooks sensíveis ao toque.</span></div>
      <select id="touchMode">
        <option value="auto">Automático</option>
        <option value="on">Ligado</option>
        <option value="off">Desligado</option>
      </select>
    </div>
    <div class="settingRow">
      <div><label for="reducedMotion">Movimento reduzido</label><span>Diminui animações de interface.</span></div>
      <input id="reducedMotion" type="checkbox">
    </div>
    <div class="settingActions">
      <button id="fullscreenButton" type="button">Tela cheia</button>
      <button id="resetProgressButton" type="button">Zerar progresso</button>
      <button id="defaultsButton" type="button">Padrão</button>
    </div>
    <p class="statusText" id="optionsStatus">Configurações salvas automaticamente.</p>
  `;
  openMenuPanel("Opções", wrap);

  const music = wrap.querySelector("#musicVolume");
  const sfx = wrap.querySelector("#sfxVolume");
  const difficulty = wrap.querySelector("#difficulty");
  const touchMode = wrap.querySelector("#touchMode");
  const reducedMotion = wrap.querySelector("#reducedMotion");
  const status = wrap.querySelector("#optionsStatus");

  difficulty.value = settings.difficulty;
  touchMode.value = settings.touchControls;
  reducedMotion.checked = settings.reducedMotion;

  const updateRangeLabel = input => {
    input.closest(".settingRow").querySelector("span").textContent = `${input.value}%`;
  };
  const changed = text => {
    saveSettings();
    applySettings();
    player.speed = settings.difficulty === "easy" ? 130 : settings.difficulty === "hard" ? 172 : 150;
    status.textContent = text;
  };

  music.addEventListener("input", () => {
    settings.musicVolume = Number(music.value);
    updateRangeLabel(music);
    changed("Volume da música atualizado.");
  });
  sfx.addEventListener("input", () => {
    settings.sfxVolume = Number(sfx.value);
    updateRangeLabel(sfx);
    changed("Volume dos efeitos atualizado.");
  });
  difficulty.addEventListener("change", () => {
    settings.difficulty = difficulty.value;
    changed("Dificuldade atualizada.");
  });
  touchMode.addEventListener("change", () => {
    settings.touchControls = touchMode.value;
    changed("Controles de toque atualizados.");
  });
  reducedMotion.addEventListener("change", () => {
    settings.reducedMotion = reducedMotion.checked;
    changed("Movimento reduzido atualizado.");
  });
  wrap.querySelector("#fullscreenButton").addEventListener("click", async () => {
    try {
      if (!document.fullscreenElement && document.documentElement.requestFullscreen) {
        await document.documentElement.requestFullscreen();
      } else if (document.fullscreenElement && document.exitFullscreen) {
        await document.exitFullscreen();
      }
      status.textContent = document.fullscreenElement ? "Tela cheia ativada." : "Tela cheia desativada.";
    } catch {
      status.textContent = "Tela cheia não foi liberada pelo navegador.";
    }
  });
  wrap.querySelector("#resetProgressButton").addEventListener("click", () => {
    learned.clear();
    redeemed.clear();
    saveProgress();
    saveRedeemed();
    updateHud();
    status.textContent = "Progresso zerado.";
  });
  wrap.querySelector("#defaultsButton").addEventListener("click", () => {
    Object.assign(settings, DEFAULT_SETTINGS);
    saveSettings();
    showOptions();
  });
}

function showMarketplace() {
  const wrap = document.createElement("div");
  wrap.className = "shopGrid";
  const products = [
    ["mapa", "Mapa dos Parques", "Mostra melhor os pontos culturais no HUD.", 1],
    ["caderno", "Caderno de Campo", "Organiza os saberes desbloqueados na mochila.", 3],
    ["passe", "Passe Urbano", "Libera itens cosméticos no vestiário.", 5]
  ];
  const status = document.createElement("p");
  status.className = "statusText";
  status.textContent = `Saberes disponíveis: ${learned.size}/${missions.length}.`;
  products.forEach(([id, name, description, cost]) => {
    const item = document.createElement("article");
    item.className = "shopItem";
    const unlocked = learned.size >= cost;
    const alreadyRedeemed = redeemed.has(id);
    item.innerHTML = `
      <div><b>${name}</b><span>${description} Custo: ${cost} saber${cost > 1 ? "es" : ""}.</span></div>
      <button type="button">${alreadyRedeemed ? "Resgatado" : unlocked ? "Resgatar" : "Ver requisito"}</button>
    `;
    const button = item.querySelector("button");
    button.disabled = alreadyRedeemed;
    button.addEventListener("click", () => {
      if (!unlocked) {
        status.textContent = `Faltam ${cost - learned.size} saber${cost - learned.size > 1 ? "es" : ""} para ${name}.`;
        return;
      }
      redeemed.add(id);
      saveRedeemed();
      button.textContent = "Resgatado";
      button.disabled = true;
      status.textContent = `${name} resgatado.`;
    });
    wrap.appendChild(item);
  });
  wrap.appendChild(status);
  openMenuPanel("Marketplace", wrap);
}

function showWardrobe() {
  const wrap = document.createElement("div");
  wrap.className = "wardrobeGrid";
  Object.entries(outfits).forEach(([id, outfit]) => {
    const item = document.createElement("article");
    item.className = "wardrobeItem";
    item.innerHTML = `
      <div>
        <b>${outfit.name}</b>
        <span>${outfit.description}</span>
      </div>
      <div class="swatch" style="background:${outfit.color}"></div>
      <button type="button">${settings.outfit === id ? "Usando" : "Usar"}</button>
    `;
    item.querySelector("button").addEventListener("click", () => {
      settings.outfit = id;
      saveSettings();
      showWardrobe();
    });
    wrap.appendChild(item);
  });
  openMenuPanel("Vestiário", wrap);
}

addEventListener("keydown", event => {
  if (event.key === "Escape") {
    closeMenuPanel();
    closeCollectionPanel();
    return;
  }
  if (!running || !menuModal.classList.contains("hidden")) return;
  keys.add(event.key.toLowerCase());
  if ([" ", "arrowup", "arrowdown", "arrowleft", "arrowright"].includes(event.key.toLowerCase())) {
    event.preventDefault();
  }
  if (event.key.toLowerCase() === "e" || event.key === " ") interact();
  if (event.key.toLowerCase() === "m") toggleCollection();
});

addEventListener("keyup", event => keys.delete(event.key.toLowerCase()));
bagButton.addEventListener("click", toggleCollection);
closeCollection.addEventListener("click", closeCollectionPanel);
actionButton.addEventListener("click", interact);
canvas.addEventListener("pointerdown", handleCanvasPointer);

moveButtons.forEach(button => {
  button.addEventListener("pointerdown", startMoveButton);
  button.addEventListener("pointerup", endMoveButton);
  button.addEventListener("pointercancel", endMoveButton);
  button.addEventListener("lostpointercapture", endMoveButton);
});

function startMoveButton(event) {
  const button = event.currentTarget;
  button.setPointerCapture(event.pointerId);
  activeMoveButtons.set(event.pointerId, {
    x: Number(button.dataset.moveX),
    y: Number(button.dataset.moveY),
    button
  });
  button.classList.add("isPressed");
  updateTouchVector();
}

function endMoveButton(event) {
  const active = activeMoveButtons.get(event.pointerId);
  if (active) active.button.classList.remove("isPressed");
  activeMoveButtons.delete(event.pointerId);
  updateTouchVector();
}

function updateTouchVector() {
  let x = 0;
  let y = 0;
  activeMoveButtons.forEach(move => {
    x += move.x;
    y += move.y;
  });
  const len = Math.hypot(x, y);
  touchVector = len > 0 ? { x: x / len, y: y / len } : { x: 0, y: 0 };
}

function loop(time) {
  const dt = Math.min(.033, (time - last) / 1000 || 0);
  last = time;
  if (running && opening.active && !activeDialog && collection.classList.contains("hidden")) {
    updateOpening(dt);
  } else if (running && !activeDialog && collection.classList.contains("hidden")) {
    update(dt);
  }
  draw();
  requestAnimationFrame(loop);
}

function handleCanvasPointer(event) {
  if (!running || !opening.active || activeDialog) return;
  const rect = canvas.getBoundingClientRect();
  const x = event.clientX - rect.left;
  const y = event.clientY - rect.top;

  if (opening.memoryOpen) {
    closeOpeningMemory();
    return;
  }

  if (opening.phase === "photo") {
    const icon = getCameraIconRect();
    if (x >= icon.x && x <= icon.x + icon.w && y >= icon.y && y <= icon.y + icon.h) {
      takeOpeningPhoto();
    }
  }
}

function updateOpening(dt) {
  opening.time += dt;
  flashAlpha = Math.max(0, flashAlpha - dt * 2.8);
  if (opening.memoryOpen) return;

  const groundY = getOpeningGroundY();
  opening.playerY = groundY;

  if (opening.phase === "fade") {
    opening.playerX += 95 * dt;
    player.dir = "right";
    player.walk += dt * 9;
    if (opening.playerX >= 310) {
      opening.playerX = 310;
      player.walk = 0;
      player.dir = "down";
      opening.phase = "photo";
      opening.time = 0;
    }
  } else if (opening.phase === "walk") {
    let dx = 0;
    if (keys.has("arrowleft") || keys.has("a")) dx -= 1;
    if (keys.has("arrowright") || keys.has("d")) dx += 1;
    dx += touchVector.x;
    if (dx !== 0) {
      opening.playerX = clamp(opening.playerX + Math.sign(dx) * player.speed * dt, 260, 1770);
      player.dir = dx > 0 ? "right" : "left";
      player.walk += dt * 9;
    } else {
      player.walk = 0;
    }
    if (opening.playerX >= 1660) {
      opening.phase = "meet";
      opening.hint = "Aproxime-se do Seu Ze e aperte E para conversar.";
    }
  } else if (opening.phase === "meet") {
    const nearZe = Math.abs(opening.playerX - 1760) < 115;
    opening.zeDialogReady = nearZe;
    player.walk = 0;
    opening.hint = nearZe ? "Aperte E para falar com Seu Ze." : "Chegue mais perto de Seu Ze.";
  }

  const targetX = opening.phase === "fade" || opening.phase === "photo"
    ? 0
    : opening.playerX - innerWidth * .45;
  openingCamera.x += (targetX - openingCamera.x) * .12;
  openingCamera.x = clamp(openingCamera.x, 0, 1320);
  placeName.textContent = "Bem-vindo a Picos";
}

function update(dt) {
  let dx = 0;
  let dy = 0;

  if (keys.has("arrowleft") || keys.has("a")) dx -= 1;
  if (keys.has("arrowright") || keys.has("d")) dx += 1;
  if (keys.has("arrowup") || keys.has("w")) dy -= 1;
  if (keys.has("arrowdown") || keys.has("s")) dy += 1;

  dx += touchVector.x;
  dy += touchVector.y;

  const len = Math.hypot(dx, dy);
  if (len > 0) {
    dx /= len;
    dy /= len;
    player.dir = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "right" : "left") : (dy > 0 ? "down" : "up");
    player.walk += dt * 9;
    movePlayer(dx * player.speed * dt, 0);
    movePlayer(0, dy * player.speed * dt);
  } else {
    player.walk = 0;
  }

  const targetX = player.x - innerWidth / 2;
  const targetY = player.y - innerHeight / 2;
  camera.x += (targetX - camera.x) * .12;
  camera.y += (targetY - camera.y) * .12;
  camera.x = clamp(camera.x, 0, WORLD_W * TILE - innerWidth);
  camera.y = clamp(camera.y, 0, WORLD_H * TILE - innerHeight);

  const near = nearestMission();
  placeName.textContent = near ? near.name : "Picos";
}

function movePlayer(dx, dy) {
  const next = { x: player.x + dx, y: player.y + dy, w: player.w, h: player.h };
  if (!collides(next)) {
    player.x = next.x;
    player.y = next.y;
  }
}

function collides(rect) {
  const left = Math.floor((rect.x - rect.w / 2) / TILE);
  const right = Math.floor((rect.x + rect.w / 2) / TILE);
  const top = Math.floor((rect.y - rect.h / 2 + 16) / TILE);
  const bottom = Math.floor((rect.y + rect.h / 2) / TILE);
  for (let x = left; x <= right; x++) {
    for (let y = top; y <= bottom; y++) {
      if (solids.has(tileKey(x, y))) return true;
    }
  }
  return false;
}

function nearestMission() {
  let best = null;
  let bestDist = Infinity;
  for (const mission of missions) {
    if (typeof mission.x !== "number" || typeof mission.y !== "number") continue;
    const d = Math.hypot(player.x - mission.x * TILE, player.y - mission.y * TILE);
    if (d < bestDist) {
      best = mission;
      bestDist = d;
    }
  }
  return bestDist < 116 ? best : null;
}

function interact() {
  if (collection && !collection.classList.contains("hidden")) return;
  if (opening.active) {
    interactOpening();
    return;
  }
  if (activeDialog) {
    closeDialog();
    return;
  }
  const mission = nearestMission();
  if (!mission) {
    showDialog("Picos", "Explore a cidade livremente.", []);
    return;
  }
  if (learned.has(mission.id)) {
    showDialog(mission.name, `${mission.fact} Item já coletado: ${mission.item}.`, []);
    return;
  }
  showQuiz(mission);
}

function interactOpening() {
  if (activeDialog) {
    closeDialog();
    return;
  }
  if (opening.memoryOpen) {
    closeOpeningMemory();
    return;
  }
  if (opening.phase === "photo") {
    takeOpeningPhoto();
    return;
  }
  if (opening.phase === "meet" && opening.zeDialogReady) {
    const mission = missions[0];
    showDialog(`${mission.npc} - ${mission.name}`, mission.question, []);
    learned.add(OPENING_MISSION_ID);
    saveProgress();
    updateHud();
    opening.active = false;
    player.x = 21 * TILE;
    player.y = 16 * TILE;
    camera.x = clamp(player.x - innerWidth / 2, 0, WORLD_W * TILE - innerWidth);
    camera.y = clamp(player.y - innerHeight / 2, 0, WORLD_H * TILE - innerHeight);
  }
}

function takeOpeningPhoto() {
  opening.memoryOpen = true;
  opening.hint = "Nova Memoria Adicionada ao Diario de Bordo!";
  flashAlpha = 1;
  playCameraSound();
}

function closeOpeningMemory() {
  opening.memoryOpen = false;
  opening.phase = "walk";
  opening.time = 0;
  opening.hint = "Use as setas ou arraste o dedo para caminhar e explorar a cidade.";
}

function playCameraSound() {
  const AudioContext = window.AudioContext || window.webkitAudioContext;
  if (!AudioContext) return;
  const audioCtx = new AudioContext();
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  osc.type = "square";
  osc.frequency.setValueAtTime(720, audioCtx.currentTime);
  osc.frequency.exponentialRampToValueAtTime(180, audioCtx.currentTime + .08);
  gain.gain.setValueAtTime(settings.sfxVolume / 100 * .12, audioCtx.currentTime);
  gain.gain.exponentialRampToValueAtTime(.001, audioCtx.currentTime + .1);
  osc.connect(gain).connect(audioCtx.destination);
  osc.start();
  osc.stop(audioCtx.currentTime + .12);
}

function showQuiz(mission) {
  activeDialog = mission;
  dialogTitle.textContent = `${mission.npc} - ${mission.name}`;
  dialogText.textContent = mission.question;
  answers.innerHTML = "";
  mission.options.forEach((option, index) => {
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = option;
    button.addEventListener("click", () => answerMission(mission, index));
    answers.appendChild(button);
  });
  dialog.classList.remove("hidden");
}

function answerMission(mission, index) {
  if (index === mission.answer) {
    learned.add(mission.id);
    saveProgress();
    updateHud();
    showDialog(`${mission.item} desbloqueado`, mission.fact, []);
  } else {
    showDialog("Tente de novo", "Observe a paisagem e converse novamente. O conhecimento também é uma trilha.", []);
  }
}

function showDialog(title, text, buttons) {
  activeDialog = { title };
  dialogTitle.textContent = title;
  dialogText.textContent = text;
  answers.innerHTML = "";
  if (buttons.length === 0) {
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = "Continuar";
    button.addEventListener("click", closeDialog);
    answers.appendChild(button);
  }
  dialog.classList.remove("hidden");
}

function closeDialog() {
  activeDialog = null;
  dialog.classList.add("hidden");
}

function saveProgress() {
  localStorage.setItem("simbora.learned", JSON.stringify([...learned]));
}

function updateHud() {
  scoreEl.textContent = learned.size;
  renderCollection();
}

function toggleCollection() {
  renderCollection();
  const open = collection.classList.contains("hidden");
  collection.classList.toggle("hidden", !open);
  bagButton.classList.toggle("isOpen", open);
  bagButton.setAttribute("aria-pressed", String(open));
  bagButton.setAttribute("aria-label", open ? "Fechar mochila" : "Abrir mochila");
}

function closeCollectionPanel() {
  collection.classList.add("hidden");
  bagButton.classList.remove("isOpen");
  bagButton.setAttribute("aria-pressed", "false");
  bagButton.setAttribute("aria-label", "Abrir mochila");
}

function renderCollection() {
  collectionList.innerHTML = "";
  missions.forEach(mission => {
    const item = document.createElement("article");
    item.className = "item";
    const known = learned.has(mission.id);
    item.innerHTML = known
      ? `<b>${mission.item}</b><span>${mission.fact}</span>`
      : `<b>Item oculto</b><span>Explore ${mission.name} para desbloquear.</span>`;
    collectionList.appendChild(item);
  });
  if (missions.length === 0) {
    const item = document.createElement("article");
    item.className = "item";
    item.innerHTML = `<b>Picos</b><span>Mapa simplificado sem pontos nomeados.</span>`;
    collectionList.appendChild(item);
  }
}

function draw() {
  ctx.clearRect(0, 0, innerWidth, innerHeight);
  if (opening.active) {
    drawOpening();
    return;
  }
  ctx.save();
  ctx.translate(-Math.floor(camera.x), -Math.floor(camera.y));
  drawGround();
  drawPaths();
  drawProps();
  drawMissions();
  drawPlayer();
  ctx.restore();
  drawVignette();
}

function drawOpening() {
  ctx.save();
  ctx.translate(-Math.floor(openingCamera.x), 0);
  drawOpeningSky();
  drawOpeningMountains();
  drawOpeningStreet();
  drawOpeningProps();
  drawOpeningPlayer();
  drawOpeningSeuZe();
  ctx.restore();
  drawOpeningUi();
  drawVignette();
  if (opening.phase === "fade") {
    const alpha = clamp(1 - opening.time / 2.4, 0, 1);
    ctx.fillStyle = `rgba(0,0,0,${alpha})`;
    ctx.fillRect(0, 0, innerWidth, innerHeight);
  }
  if (flashAlpha > 0) {
    ctx.fillStyle = `rgba(255,255,255,${flashAlpha})`;
    ctx.fillRect(0, 0, innerWidth, innerHeight);
  }
}

function drawOpeningSky() {
  const sky = ctx.createLinearGradient(0, 0, 0, innerHeight);
  sky.addColorStop(0, "#49a7f2");
  sky.addColorStop(.58, "#9bd8ff");
  sky.addColorStop(1, "#f7cf84");
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, 2300, innerHeight);
  ctx.fillStyle = "rgba(255,255,255,.9)";
  drawCloud(170, 92, 1);
  drawCloud(780, 76, .8);
  drawCloud(1380, 112, .95);
}

function drawCloud(x, y, scale) {
  ctx.beginPath();
  ctx.arc(x, y, 24 * scale, 0, Math.PI * 2);
  ctx.arc(x + 28 * scale, y - 10 * scale, 32 * scale, 0, Math.PI * 2);
  ctx.arc(x + 64 * scale, y, 24 * scale, 0, Math.PI * 2);
  ctx.fill();
}

function drawOpeningMountains() {
  const base = getOpeningGroundY() - 116;
  ctx.fillStyle = "#5d9b69";
  ctx.beginPath();
  ctx.moveTo(0, base);
  for (let x = 0; x <= 2300; x += 120) {
    ctx.lineTo(x + 70, base - 70 - Math.sin(x * .015) * 30);
    ctx.lineTo(x + 140, base);
  }
  ctx.lineTo(2300, innerHeight);
  ctx.lineTo(0, innerHeight);
  ctx.fill();
  ctx.fillStyle = "#3b7d55";
  ctx.fillRect(0, base + 20, 2300, 90);
}

function drawOpeningStreet() {
  const ground = getOpeningGroundY();
  ctx.fillStyle = "#d6b16a";
  ctx.fillRect(0, ground - 18, 2300, innerHeight - ground + 18);
  ctx.fillStyle = "#7a7c78";
  ctx.fillRect(0, ground + 18, 2300, 74);
  ctx.fillStyle = "#e7d69d";
  for (let x = 30; x < 2300; x += 150) ctx.fillRect(x, ground + 50, 70, 8);
}

function drawOpeningProps() {
  const ground = getOpeningGroundY();
  drawPicosSign(232, ground - 8);
  drawNimTree(710, ground - 6);
  drawSaoJoaoPoster(940, ground - 6);
  drawSleepingDog(1160, ground + 8);
  drawGoldenBees();
  drawChurchPlaza(1600, ground - 12);
}

function drawPicosSign(x, y) {
  ctx.fillStyle = "#744325";
  ctx.fillRect(x + 34, y - 70, 10, 70);
  ctx.fillRect(x + 188, y - 70, 10, 70);
  ctx.fillStyle = "#ffd45a";
  ctx.fillRect(x, y - 120, 238, 58);
  ctx.strokeStyle = "#2c4f87";
  ctx.lineWidth = 5;
  ctx.strokeRect(x, y - 120, 238, 58);
  ctx.fillStyle = "#2167a8";
  ctx.font = "900 34px monospace";
  ctx.fillText("PICOS", x + 64, y - 82);
  ctx.fillStyle = "#e43d30";
  ctx.fillRect(x + 16, y - 104, 32, 10);
  ctx.fillStyle = "#2f9b55";
  ctx.fillRect(x + 190, y - 84, 30, 10);
}

function drawNimTree(x, y) {
  ctx.fillStyle = "#6d3f24";
  ctx.fillRect(x - 14, y - 98, 26, 98);
  ctx.fillStyle = "#2f7b47";
  for (let i = 0; i < 8; i++) {
    ctx.beginPath();
    ctx.arc(x + Math.cos(i) * 36, y - 118 + Math.sin(i * 1.7) * 18, 38, 0, Math.PI * 2);
    ctx.fill();
  }
}

function drawSaoJoaoPoster(x, y) {
  ctx.fillStyle = "#4b3b31";
  ctx.fillRect(x, y - 142, 10, 142);
  ctx.fillStyle = "#f2d57c";
  ctx.fillRect(x - 42, y - 122, 92, 66);
  ctx.fillStyle = "#c43d32";
  ctx.font = "900 13px monospace";
  ctx.fillText("SAO JOAO", x - 34, y - 96);
  ctx.fillStyle = "#2f78b7";
  ctx.fillRect(x - 34, y - 86, 54, 6);
  ctx.fillStyle = "#8f6a42";
  ctx.beginPath();
  ctx.moveTo(x + 18, y - 56);
  ctx.lineTo(x + 50, y - 56);
  ctx.lineTo(x + 18, y - 32);
  ctx.fill();
}

function drawSleepingDog(x, y) {
  ctx.fillStyle = "#c9843d";
  ctx.fillRect(x - 34, y - 28, 64, 24);
  ctx.fillRect(x + 18, y - 42, 28, 24);
  ctx.fillStyle = "#6b3d21";
  ctx.fillRect(x + 38, y - 36, 10, 18);
  ctx.fillStyle = "#2b1c15";
  ctx.fillRect(x + 34, y - 30, 4, 4);
  ctx.font = "800 15px monospace";
  ctx.fillText("Zzz", x - 14, y - 46);
}

function drawChurchPlaza(x, y) {
  ctx.fillStyle = "#d9bb84";
  ctx.fillRect(x - 220, y - 78, 520, 92);
  ctx.fillStyle = "#f2efe4";
  ctx.fillRect(x, y - 220, 170, 214);
  ctx.fillRect(x - 54, y - 180, 50, 174);
  ctx.fillRect(x + 174, y - 180, 50, 174);
  ctx.fillStyle = "#c99b4a";
  ctx.fillRect(x + 26, y - 92, 54, 86);
  ctx.fillStyle = "#6f8bb0";
  ctx.fillRect(x + 106, y - 140, 34, 62);
  ctx.fillRect(x - 38, y - 138, 22, 52);
  ctx.fillRect(x + 188, y - 138, 22, 52);
  ctx.fillStyle = "#d6a948";
  ctx.beginPath();
  ctx.moveTo(x - 60, y - 180); ctx.lineTo(x - 28, y - 232); ctx.lineTo(x + 4, y - 180);
  ctx.moveTo(x + 168, y - 180); ctx.lineTo(x + 199, y - 232); ctx.lineTo(x + 230, y - 180);
  ctx.moveTo(x, y - 220); ctx.lineTo(x + 86, y - 292); ctx.lineTo(x + 170, y - 220);
  ctx.fill();
  ctx.fillStyle = "#744325";
  ctx.fillRect(x - 232, y - 28, 84, 14);
  ctx.fillRect(x - 220, y - 48, 12, 28);
  ctx.fillRect(x - 166, y - 48, 12, 28);
}

function drawGoldenBees() {
  if (opening.phase !== "walk") return;
  const ground = getOpeningGroundY();
  for (let i = 0; i < 7; i++) {
    const x = 520 + i * 135 + Math.sin(opening.time * 3 + i) * 18;
    const y = ground - 150 + Math.sin(opening.time * 4 + i) * 22;
    ctx.fillStyle = "#ffc247";
    ctx.beginPath();
    ctx.ellipse(x, y, 10, 7, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#3a1c11";
    ctx.fillRect(x - 3, y - 7, 3, 14);
    ctx.fillStyle = "rgba(255,255,255,.7)";
    ctx.beginPath();
    ctx.arc(x - 6, y - 8, 6, 0, Math.PI * 2);
    ctx.arc(x + 6, y - 8, 6, 0, Math.PI * 2);
    ctx.fill();
  }
}

function drawOpeningPlayer() {
  const originalX = player.x;
  const originalY = player.y;
  player.x = opening.playerX;
  player.y = opening.playerY;
  drawPlayer();
  player.x = originalX;
  player.y = originalY;
}

function drawOpeningSeuZe() {
  const ground = getOpeningGroundY();
  const x = 1760;
  const y = ground - 4;
  if (opening.phase !== "meet" && opening.playerX < 1390) return;
  ctx.fillStyle = "#744325";
  ctx.fillRect(x - 86, y - 38, 154, 18);
  ctx.fillRect(x - 74, y - 26, 16, 42);
  ctx.fillRect(x + 42, y - 26, 16, 42);
  if (images.seuZe.complete && images.seuZe.naturalWidth) {
    ctx.drawImage(images.seuZe, x - 64, y - 206, 128, 178);
  } else {
    drawNpc(x, y - 36, OPENING_MISSION_ID);
  }
  if (opening.phase === "meet") {
    ctx.font = "900 42px monospace";
    ctx.fillStyle = "#ffc247";
    ctx.fillText("!", x - 9, y - 222 + Math.sin(opening.time * 5) * 5);
  }
}

function drawOpeningUi() {
  if (opening.memoryOpen) {
    drawMemoryCard();
    return;
  }
  if (opening.phase === "photo") drawCameraIcon();
  if (opening.phase === "photo" || opening.phase === "walk" || opening.phase === "meet") drawOpeningHint(opening.hint);
}

function drawCameraIcon() {
  const icon = getCameraIconRect();
  const pulse = 1 + Math.sin(opening.time * 5) * .06;
  ctx.save();
  ctx.translate(icon.x + icon.w / 2, icon.y + icon.h / 2);
  ctx.scale(pulse, pulse);
  ctx.fillStyle = "#ffc247";
  ctx.fillRect(-31, -20, 62, 44);
  ctx.fillStyle = "#fff7dc";
  ctx.fillRect(-18, -28, 36, 12);
  ctx.fillStyle = "#1b150c";
  ctx.beginPath();
  ctx.arc(0, 3, 14, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = "#7ed4ff";
  ctx.beginPath();
  ctx.arc(0, 3, 8, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

function drawOpeningHint(text) {
  const width = Math.min(620, innerWidth - 28);
  const x = (innerWidth - width) / 2;
  const y = innerHeight - (shouldShowTouchControls() ? 190 : 88);
  ctx.fillStyle = "rgba(58, 29, 17, .94)";
  ctx.fillRect(x, y, width, 54);
  ctx.strokeStyle = "#ffc247";
  ctx.lineWidth = 3;
  ctx.strokeRect(x, y, width, 54);
  ctx.fillStyle = "#fff7dc";
  ctx.font = "800 18px system-ui, sans-serif";
  ctx.textAlign = "center";
  ctx.fillText(text, innerWidth / 2, y + 34);
  ctx.textAlign = "left";
}

function drawMemoryCard() {
  const w = Math.min(430, innerWidth - 36);
  const h = 330;
  const x = (innerWidth - w) / 2;
  const y = Math.max(34, (innerHeight - h) / 2);
  ctx.fillStyle = "rgba(8,16,31,.48)";
  ctx.fillRect(0, 0, innerWidth, innerHeight);
  ctx.fillStyle = "#fff7dc";
  ctx.fillRect(x, y, w, h);
  ctx.fillStyle = "#7ed4ff";
  ctx.fillRect(x + 24, y + 24, w - 48, 160);
  ctx.fillStyle = "#5d9b69";
  ctx.beginPath();
  ctx.moveTo(x + 24, y + 184);
  ctx.lineTo(x + 140, y + 84);
  ctx.lineTo(x + 250, y + 184);
  ctx.lineTo(x + w - 24, y + 102);
  ctx.lineTo(x + w - 24, y + 184);
  ctx.fill();
  ctx.fillStyle = "#1b150c";
  ctx.font = "900 21px system-ui, sans-serif";
  ctx.textAlign = "center";
  ctx.fillText("Nova Memoria Adicionada", innerWidth / 2, y + 226);
  ctx.fillText("ao Diario de Bordo!", innerWidth / 2, y + 252);
  ctx.font = "700 14px system-ui, sans-serif";
  wrapCanvasText(missions[0].fact, innerWidth / 2, y + 282, w - 54, 18, "center");
  ctx.textAlign = "left";
}

function wrapCanvasText(text, x, y, maxWidth, lineHeight, align = "left") {
  const words = text.split(" ");
  let line = "";
  ctx.textAlign = align;
  for (const word of words) {
    const test = line ? `${line} ${word}` : word;
    if (ctx.measureText(test).width > maxWidth && line) {
      ctx.fillText(line, x, y);
      line = word;
      y += lineHeight;
    } else {
      line = test;
    }
  }
  ctx.fillText(line, x, y);
}

function getOpeningGroundY() {
  return Math.max(365, innerHeight * .72);
}

function getCameraIconRect() {
  const playerScreenX = opening.playerX - openingCamera.x;
  return {
    x: clamp(playerScreenX + 16, 18, innerWidth - 90),
    y: clamp(getOpeningGroundY() - 198, 70, innerHeight - 170),
    w: 70,
    h: 62
  };
}

function drawGround() {
  for (let x = 0; x < WORLD_W; x++) {
    for (let y = 0; y < WORLD_H; y++) {
      const px = x * TILE;
      const py = y * TILE;
      if (water.has(tileKey(x, y))) {
        drawTile(px, py, "#2a8fc1", "#1e6e9d");
      } else if (museumPlaza.has(tileKey(x, y))) {
        drawMuseumPlazaTile(px, py, x, y);
      } else {
        const dry = y > 20 || x > 26;
        drawTile(px, py, dry ? "#b9a05c" : "#71ad5a", dry ? "#8f7d42" : "#4d873f");
        if ((x * 13 + y * 7) % 9 === 0) {
          ctx.fillStyle = dry ? "#d6bd75" : "#93c46d";
          ctx.fillRect(px + 9, py + 14, 6, 6);
          ctx.fillRect(px + 28, py + 31, 5, 5);
        }
      }
    }
  }
}

function drawTile(x, y, fill, line) {
  ctx.fillStyle = fill;
  ctx.fillRect(x, y, TILE, TILE);
  ctx.strokeStyle = line;
  ctx.globalAlpha = .22;
  ctx.strokeRect(x + .5, y + .5, TILE - 1, TILE - 1);
  ctx.globalAlpha = 1;
}

function drawPaths() {
  ctx.strokeStyle = "#d8b96e";
  ctx.lineWidth = 18;
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  ctx.beginPath();
  ctx.moveTo(11 * TILE, 15 * TILE);
  ctx.lineTo(31 * TILE, 15 * TILE);
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(21 * TILE, 8 * TILE);
  ctx.lineTo(21 * TILE, 22 * TILE);
  ctx.stroke();
  ctx.lineWidth = 4;
  ctx.strokeStyle = "#8b6234";
  ctx.stroke();
}

function drawProps() {
  props
    .slice()
    .sort((a, b) => a.y - b.y)
    .forEach(prop => {
      const x = prop.x * TILE;
      const y = prop.y * TILE;
      if (prop.type === "palm") drawPalm(x, y);
      if (prop.type === "cactus") drawCactus(x, y);
      if (prop.type === "bush") drawBush(x, y);
      if (prop.type === "rock") drawRock(x, y);
      if (prop.type === "house") drawHouse(x, y);
      if (prop.type === "pathTile") drawCityPathTile(x, y);
      if (prop.type === "museumPicos") drawMuseumPicos(x, y);
    });
}

function drawMuseumPlazaTile(x, y, tileX, tileY) {
  drawTile(x, y, "#d7c8a5", "#8a7654");
  ctx.strokeStyle = "rgba(92,78,58,.38)";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(x, y + TILE / 2);
  ctx.lineTo(x + TILE, y + TILE / 2);
  ctx.moveTo(x + TILE / 2, y);
  ctx.lineTo(x + TILE / 2, y + TILE);
  ctx.stroke();
  if ((tileX + tileY) % 3 === 0) {
    ctx.fillStyle = "rgba(255,255,255,.18)";
    ctx.fillRect(x + 7, y + 7, 6, 6);
  }
  if ((tileX * 2 + tileY) % 5 === 0) {
    ctx.fillStyle = "rgba(80,70,48,.26)";
    ctx.fillRect(x + 30, y + 31, 8, 3);
  }
}

function drawMuseumPicos(x, y) {
  drawMuseumGarden(x - 218, y + 212, 108, 34);
  drawMuseumGarden(x + 266, y + 212, 108, 34);
  drawMuseumGarden(x - 214, y - 64, 92, 36);
  drawMuseumGarden(x + 248, y - 64, 92, 36);

  ctx.fillStyle = "#b48a55";
  ctx.fillRect(x - 48, y + 142, TILE * 4, TILE * 5);
  ctx.strokeStyle = "#6f5132";
  ctx.lineWidth = 3;
  ctx.strokeRect(x - 48, y + 142, TILE * 4, TILE * 5);
  ctx.strokeStyle = "rgba(70,44,24,.28)";
  ctx.lineWidth = 1;
  for (let i = 1; i < 5; i++) {
    ctx.beginPath();
    ctx.moveTo(x - 48, y + 142 + i * TILE);
    ctx.lineTo(x - 48 + TILE * 4, y + 142 + i * TILE);
    ctx.stroke();
  }

  ctx.fillStyle = "rgba(0,0,0,.16)";
  ctx.beginPath();
  ctx.ellipse(x + 72, y + 172, 148, 12, 0, 0, Math.PI * 2);
  ctx.fill();

  if (images.museumPicos.complete && images.museumPicos.naturalWidth) {
    const drawW = 410;
    const drawH = drawW * (images.museumPicos.naturalHeight / images.museumPicos.naturalWidth);
    ctx.drawImage(images.museumPicos, x - 132, y - 126, drawW, drawH);
    return;
  }

  ctx.fillStyle = "#d6c6a7";
  ctx.fillRect(x - 110, y - 72, 360, 210);
  ctx.fillStyle = "#7d5034";
  ctx.fillRect(x - 124, y - 92, 388, 38);
  ctx.fillStyle = "#2d3c52";
  ctx.fillRect(x + 34, y + 52, 42, 86);
  ctx.fillStyle = "#6f8aa0";
  for (let col = 0; col < 4; col++) {
    ctx.fillRect(x - 72 + col * 78, y - 22, 34, 42);
  }
}

function drawMuseumGarden(x, y, w, h) {
  ctx.fillStyle = "#715137";
  ctx.fillRect(x, y, w, h);
  ctx.fillStyle = "#4f873c";
  ctx.fillRect(x + 5, y + 5, w - 10, h - 10);
  ctx.strokeStyle = "#e0c17b";
  ctx.lineWidth = 2;
  ctx.strokeRect(x, y, w, h);
  ctx.fillStyle = "#f5d35c";
  for (let i = 0; i < 3; i++) {
    ctx.beginPath();
    ctx.arc(x + 22 + i * 28, y + h / 2, 5, 0, Math.PI * 2);
    ctx.fill();
  }
}

function drawCityPathTile(x, y) {
  ctx.fillStyle = "#d8b96e";
  ctx.fillRect(x, y, TILE, TILE);
  ctx.strokeStyle = "#8b6234";
  ctx.globalAlpha = .28;
  ctx.strokeRect(x + .5, y + .5, TILE - 1, TILE - 1);
  ctx.globalAlpha = 1;
}

function drawPalm(x, y) {
  ctx.fillStyle = "#70482c";
  ctx.fillRect(x + 20, y + 18, 8, 30);
  ctx.fillStyle = "#226d3d";
  for (let i = 0; i < 6; i++) {
    const a = i * Math.PI / 3;
    ctx.beginPath();
    ctx.ellipse(x + 24 + Math.cos(a) * 12, y + 17 + Math.sin(a) * 8, 18, 7, a, 0, Math.PI * 2);
    ctx.fill();
  }
}

function drawCactus(x, y) {
  ctx.fillStyle = "#2f8148";
  ctx.fillRect(x + 20, y + 12, 10, 34);
  ctx.fillRect(x + 12, y + 24, 10, 8);
  ctx.fillRect(x + 28, y + 20, 10, 8);
  ctx.strokeStyle = "#1d5933";
  ctx.strokeRect(x + 20.5, y + 12.5, 9, 33);
}

function drawBush(x, y) {
  ctx.fillStyle = "#3f8739";
  ctx.beginPath();
  ctx.arc(x + 18, y + 30, 12, 0, Math.PI * 2);
  ctx.arc(x + 30, y + 28, 14, 0, Math.PI * 2);
  ctx.arc(x + 27, y + 37, 10, 0, Math.PI * 2);
  ctx.fill();
}

function drawRock(x, y) {
  ctx.fillStyle = "#916d55";
  ctx.beginPath();
  ctx.moveTo(x + 8, y + 38);
  ctx.lineTo(x + 19, y + 13);
  ctx.lineTo(x + 35, y + 8);
  ctx.lineTo(x + 44, y + 39);
  ctx.closePath();
  ctx.fill();
  ctx.strokeStyle = "#5d473b";
  ctx.stroke();
}

function drawHouse(x, y) {
  ctx.fillStyle = "#bc7b43";
  ctx.fillRect(x + 5, y + 20, 78, 48);
  ctx.fillStyle = "#7b3c2b";
  ctx.beginPath();
  ctx.moveTo(x, y + 22);
  ctx.lineTo(x + 44, y - 8);
  ctx.lineTo(x + 88, y + 22);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = "#29344c";
  ctx.fillRect(x + 39, y + 42, 14, 26);
}

function drawMissions() {
  missions.forEach(mission => {
    if (typeof mission.x !== "number" || typeof mission.y !== "number") return;
    const x = mission.x * TILE;
    const y = mission.y * TILE;
    ctx.fillStyle = learned.has(mission.id) ? "#ffc247" : "#fff7dc";
    ctx.beginPath();
    ctx.arc(x, y - 34, 10 + Math.sin(performance.now() / 180) * 2, 0, Math.PI * 2);
    ctx.fill();
    drawNpc(x, y, mission.id);
  });
}

function drawNpc(x, y, id) {
  const palette = {
    museu_ozildo: ["#78442c", "#f2d17a"],
    igreja_picos: ["#54677c", "#eef6ff"],
    praca_ozildo: ["#3a8f57", "#fff7dc"],
    feira_picos: ["#a33e3e", "#ffc247"],
    guaribas: ["#1b6fa8", "#ffd6a0"]
  }[id] || ["#8a5a2b", "#f2d17a"];
  ctx.fillStyle = palette[1];
  ctx.fillRect(x - 12, y - 34, 24, 14);
  ctx.fillStyle = palette[0];
  ctx.fillRect(x - 14, y - 20, 28, 32);
  ctx.fillStyle = "#2a1a15";
  ctx.fillRect(x - 16, y - 38, 32, 7);
}

function drawPlayer() {
  const x = player.x;
  const y = player.y;
  const frame = player.walk > 0 ? Math.floor(player.walk) % PLAYER_SPRITE.columns : 0;
  if (images.hero.complete && images.hero.naturalWidth) {
    const sprite = heroSprite || images.hero;
    const row = PLAYER_SPRITE.rowByDir[player.dir] || 0;
    const sourceScaleX = sprite.width / 1254;
    const sourceScaleY = sprite.height / 1254;
    const sx = PLAYER_SPRITE.sourceX[frame] * sourceScaleX;
    const sy = PLAYER_SPRITE.sourceY[row] * sourceScaleY;
    const sw = PLAYER_SPRITE.sourceWidth * sourceScaleX;
    const sh = PLAYER_SPRITE.sourceHeight * sourceScaleY;
    const bob = frame === 1 || frame === 3 ? 1 : 0;
    ctx.drawImage(
      sprite,
      sx,
      sy,
      sw,
      sh,
      x - PLAYER_SPRITE.width / 2,
      y - PLAYER_SPRITE.height + 10 + bob,
      PLAYER_SPRITE.width,
      PLAYER_SPRITE.height
    );
  } else {
    ctx.fillStyle = (outfits[settings.outfit] || outfits.explorer).color;
    ctx.fillRect(x - 14, y - 34, 28, 34);
    ctx.fillStyle = "#f2d17a";
    ctx.fillRect(x - 18, y - 48, 36, 12);
  }
}

function drawVignette() {
  const grad = ctx.createRadialGradient(innerWidth / 2, innerHeight / 2, innerHeight * .18, innerWidth / 2, innerHeight / 2, innerWidth * .68);
  grad.addColorStop(0, "rgba(0,0,0,0)");
  grad.addColorStop(1, "rgba(0,0,0,.28)");
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, innerWidth, innerHeight);
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}
