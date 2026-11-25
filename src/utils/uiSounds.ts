export type SkylineSoundType =
  | 'tick'
  | 'confirm'
  | 'back'
  | 'fade'
  | 'launch'
  | 'settings'
  | 'browser'
  | 'album'
  | 'user'
  | 'error';

const SOUND_FILE_MAP: Record<SkylineSoundType, string> = {
  tick: '/assets/skyline-sounds/Tick.wav',
  confirm: '/assets/skyline-sounds/Select.wav',
  back: '/assets/skyline-sounds/EnterBack.wav',
  fade: '/assets/skyline-sounds/Klick.wav',
  launch: '/assets/skyline-sounds/PopupRunTitle.wav',
  settings: '/assets/skyline-sounds/Settings.wav',
  browser: '/assets/skyline-sounds/Browser.wav',
  album: '/assets/skyline-sounds/Album.wav',
  user: '/assets/skyline-sounds/User.wav',
  error: '/assets/skyline-sounds/Error.wav',
};

let audioCtx: AudioContext | null = null;
const wavPool = new Map<string, HTMLAudioElement>();

function getCtx(): AudioContext | null {
  if (typeof window === 'undefined') return null;
  const Ctor =
    window.AudioContext ||
    (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
  if (!Ctor) return null;
  if (!audioCtx) {
    audioCtx = new Ctor();
  }
  if (audioCtx.state === 'suspended') {
    audioCtx.resume().catch(() => {});
  }
  return audioCtx;
}

function playSynthFallback(type: SkylineSoundType) {
  try {
    const ctx = getCtx();
    if (!ctx) return;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    const now = ctx.currentTime;
    const freqMap: Record<SkylineSoundType, [number, number, number]> = {
      tick: [540, 660, 0.045],
      confirm: [620, 880, 0.08],
      back: [480, 320, 0.075],
      fade: [520, 740, 0.065],
      launch: [440, 960, 0.14],
      settings: [500, 720, 0.07],
      browser: [560, 820, 0.07],
      album: [600, 860, 0.07],
      user: [580, 790, 0.07],
      error: [280, 180, 0.1],
    };
    const [f1, f2, dur] = freqMap[type];
    osc.frequency.setValueAtTime(f1, now);
    osc.frequency.exponentialRampToValueAtTime(f2, now + dur);
    gain.gain.setValueAtTime(0.001, now);
    gain.gain.exponentialRampToValueAtTime(0.04, now + 0.012);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + dur);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + dur + 0.01);
  } catch {
    // Ignore autoplay errors
  }
}

/**
 * Plays authentic SkylineOS2 Switch 2 WAV sound effects when available,
 * with clean WebAudio oscillator fallback.
 */
export function playUiSound(type: SkylineSoundType, enabled: boolean): void {
  if (!enabled || typeof window === 'undefined') return;
  const src = SOUND_FILE_MAP[type];
  try {
    let base = wavPool.get(src);
    if (!base) {
      base = new Audio(src);
      base.preload = 'auto';
      wavPool.set(src, base);
    }
    const inst = base.cloneNode(true) as HTMLAudioElement;
    inst.volume = type === 'tick' ? 0.35 : 0.45;
    const p = inst.play();
    if (p && typeof p.catch === 'function') {
      p.catch(() => playSynthFallback(type));
    }
  } catch {
    playSynthFallback(type);
  }
}
