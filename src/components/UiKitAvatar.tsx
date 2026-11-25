import { UI_KIT_AVATARS } from '../data/profiles';
import type { UiKitCharacterId } from '../types/skyline';

interface UiKitAvatarProps {
  characterId: UiKitCharacterId;
  size: number;
  roundedClass?: string;
  alt?: string;
}

const SHEET_W = 1747;
const SHEET_H = 2145;

export function UiKitAvatar({
  characterId,
  size,
  roundedClass = 'rounded-full',
  alt,
}: UiKitAvatarProps) {
  const meta = UI_KIT_AVATARS.find((a) => a.id === characterId) ?? UI_KIT_AVATARS[0];
  const scale = size / meta.rect.size;
  const bgW = SHEET_W * scale;
  const bgH = SHEET_H * scale;
  const offsetX = -meta.rect.x * scale;
  const offsetY = -meta.rect.y * scale;

  return (
    <span
      role="img"
      aria-label={alt ?? meta.label}
      className={`block shrink-0 overflow-hidden ${roundedClass}`}
      style={{
        width: `${size}px`,
        height: `${size}px`,
        backgroundColor: meta.bgTint,
        backgroundImage: "url('/assets/aistudio/UI_Kit_29e8735c.png')",
        backgroundRepeat: 'no-repeat',
        backgroundSize: `${bgW}px ${bgH}px`,
        backgroundPosition: `${offsetX}px ${offsetY}px`,
      }}
    />
  );
}
