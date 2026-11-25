import type { UiKitCharacterId, UserProfile } from '../types/skyline';

export interface UiKitAvatarMeta {
  id: UiKitCharacterId;
  label: string;
  /** Exact pixel rect inside /public/assets/aistudio/UI_Kit_29e8735c.png (1747x2145) */
  rect: { x: number; y: number; size: number };
  bgTint: string;
}

export const UI_KIT_AVATARS: UiKitAvatarMeta[] = [
  {
    id: 'mario',
    label: 'Mario',
    rect: { x: 1632, y: 39, size: 76 },
    bgTint: '#F9E8E8',
  },
  {
    id: 'luigi',
    label: 'Luigi',
    rect: { x: 1632, y: 133, size: 76 },
    bgTint: '#BFE8CA',
  },
  {
    id: 'peach',
    label: 'Peach',
    rect: { x: 1632, y: 227, size: 76 },
    bgTint: '#F9D6E7',
  },
  {
    id: 'yoshi',
    label: 'Yoshi',
    rect: { x: 1632, y: 322, size: 76 },
    bgTint: '#7ABF51',
  },
  {
    id: 'dk',
    label: 'Donkey Kong',
    rect: { x: 1632, y: 416, size: 76 },
    bgTint: '#E0AC69',
  },
  {
    id: 'bowser',
    label: 'Bowser',
    rect: { x: 1632, y: 510, size: 76 },
    bgTint: '#E83C33',
  },
];

export const INITIAL_USERS: UserProfile[] = [
  { id: 'user-mario', name: 'Mario', characterId: 'mario', friendCode: 'SW-1234-5678-9012' },
  { id: 'user-peach', name: 'Peach', characterId: 'peach', friendCode: 'SW-4820-1934-7710' },
];

