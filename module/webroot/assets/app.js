const MODID = 'doze_aod_wallpaper';
const MODDIR = `/data/adb/modules/${MODID}`;

const slider = document.getElementById('slider');
const valueEl = document.getElementById('value');
const arrayEl = document.getElementById('array');
const statusEl = document.getElementById('status');
const presets = document.querySelectorAll('.presets button');

function arrayFor(v) {
  const b1 = v;
  const b2 = Math.min(v * 2, 255);
  const b3 = Math.min(v * 3, 255);
  const b4 = Math.min(v * 4, 255);
  return `-1:${b1}:${b2}:${b3}:${b4}`;
}

function showStatus(msg, isErr) {
  statusEl.textContent = msg;
  statusEl.className = 'status ' + (isErr ? 'err' : 'ok');
  setTimeout(() => { statusEl.className = 'status'; }, 3000);
}

function exec(cmd) {
  try {
    return ksu.exec(cmd) || '';
  } catch (e) {
    return '';
  }
}

function readConfig() {
  const out = exec(`cat ${MODDIR}/config.ini 2>/dev/null`);
  const m = out.match(/brightness=(\d+)/);
  return m ? parseInt(m[1], 10) : 40;
}

function writeConfig(v) {
  exec(`echo "brightness=${v}" > ${MODDIR}/config.ini`);
}

function apply(v) {
  writeConfig(v);
  const res = exec(`sh ${MODDIR}/apply.sh`);
  showStatus(`Applied brightness ${v}`);
}

function updateUI(v) {
  slider.value = v;
  valueEl.textContent = v;
  arrayEl.textContent = arrayFor(v);
  presets.forEach(p => {
    p.classList.toggle('active', parseInt(p.dataset.v, 10) === v);
  });
}

slider.addEventListener('input', () => {
  const v = parseInt(slider.value, 10);
  valueEl.textContent = v;
  arrayEl.textContent = arrayFor(v);
});

slider.addEventListener('change', () => {
  apply(parseInt(slider.value, 10));
});

presets.forEach(p => {
  p.addEventListener('click', () => {
    const v = parseInt(p.dataset.v, 10);
    updateUI(v);
    apply(v);
  });
});

const current = readConfig();
if (current >= 5 && current <= 100) {
  updateUI(current);
} else {
  updateUI(40);
}
