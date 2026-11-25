import React from 'react';

interface IconProps {
  size: number;
  color?: string;
}

/** UI Kit Column 3: Game-card badge icon shown beside the selected game title */
export function UiKitGameCardBadgeIcon({ size, color = '#215FE5' }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
      className="shrink-0"
    >
      <path
        d="M6.5 2.5h8.2L19.5 7.3V20a1.5 1.5 0 0 1-1.5 1.5h-11.5A1.5 1.5 0 0 1 5 20V4a1.5 1.5 0 0 1 1.5-1.5Z"
        fill={color}
      />
      <rect x="7.8" y="6.8" width="8.4" height="7.6" rx="1.2" fill="#FFFFFF" fillOpacity="0.92" />
      <path d="M9.5 17.5h5" stroke="#FFFFFF" strokeOpacity="0.85" strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );
}

/** UI Kit Column 1 & 2: Nintendo Switch Online logo (Switch Joy-Con glyph + ONLINE) */
export function UiKitNsoIcon({
  size,
  highlighted,
  mutedColor = '#B0B4BC',
}: {
  size: number;
  highlighted: boolean;
  mutedColor?: string;
}) {
  if (highlighted) {
    return (
      <span
        className="rounded-full flex flex-col items-center justify-center shrink-0"
        style={{
          width: `${Math.round(size * 1.38)}px`,
          height: `${Math.round(size * 1.38)}px`,
          backgroundColor: '#E60012',
          color: '#FFFFFF',
        }}
      >
        <svg
          width={Math.round(size * 0.66)}
          height={Math.round(size * 0.56)}
          viewBox="0 0 28 24"
          fill="none"
          aria-hidden="true"
        >
          {/* Left solid Joy-Con half */}
          <path
            d="M8.5 2C5.46 2 3 4.46 3 7.5v9C3 19.54 5.46 22 8.5 22h4V2h-4Zm.2 7.5a2 2 0 1 1 0-4 2 2 0 0 1 0 4Z"
            fill="#FFFFFF"
          />
          {/* Right outlined Joy-Con half */}
          <rect
            x="16"
            y="2.9"
            width="8.2"
            height="18.2"
            rx="4.1"
            stroke="#FFFFFF"
            strokeWidth="1.9"
          />
          <circle cx="20.1" cy="14.5" r="2.1" fill="#FFFFFF" />
        </svg>
        <span
          className="font-ud-bold leading-none tracking-wider"
          style={{ fontSize: `${Math.max(7, Math.round(size * 0.24))}px`, marginTop: '1px' }}
        >
          ONLINE
        </span>
      </span>
    );
  }

  return (
    <span className="flex flex-col items-center justify-center shrink-0">
      <svg
        width={Math.round(size * 0.96)}
        height={Math.round(size * 0.80)}
        viewBox="0 0 28 24"
        fill="none"
        aria-hidden="true"
      >
        <path
          d="M8.5 2C5.46 2 3 4.46 3 7.5v9C3 19.54 5.46 22 8.5 22h4V2h-4Zm.2 7.5a2 2 0 1 1 0-4 2 2 0 0 1 0 4Z"
          fill={mutedColor}
        />
        <rect
          x="16"
          y="2.9"
          width="8.2"
          height="18.2"
          rx="4.1"
          stroke={mutedColor}
          strokeWidth="1.9"
        />
        <circle cx="20.1" cy="14.5" r="2.1" fill={mutedColor} />
      </svg>
      <span
        className="font-ud-bold leading-none tracking-wider"
        style={{
          color: mutedColor,
          fontSize: `${Math.max(6, Math.round(size * 0.22))}px`,
          marginTop: '2px',
        }}
      >
        ONLINE
      </span>
    </span>
  );
}

/** UI Kit Column 2 #2: GameChat orange rounded C bubble (#EE8600) */
export function UiKitGameChatIcon({ size }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <path
        d="M8.5 5h15A3.5 3.5 0 0 1 27 8.5v13a3.5 3.5 0 0 1-3.5 3.5H11.2L6 28.5V8.5A3.5 3.5 0 0 1 8.5 5Z"
        stroke="#EE8600"
        strokeWidth="2.4"
        strokeLinejoin="round"
        fill="none"
      />
      <path
        d="M19.8 12.1a4.8 4.8 0 1 0 0 5.8"
        stroke="#EE8600"
        strokeWidth="2.6"
        strokeLinecap="round"
      />
    </svg>
  );
}

/** UI Kit Column 2 #3: News green folded newspaper (#2BAB23) */
export function UiKitNewsIcon({ size }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <rect
        x="4.5"
        y="6.5"
        width="18.5"
        height="19"
        rx="2.6"
        stroke="#2BAB23"
        strokeWidth="2.3"
      />
      <path
        d="M23 11.5h2.7a2 2 0 0 1 2 2v9.8a2.2 2.2 0 0 1-2.2 2.2H21"
        stroke="#2BAB23"
        strokeWidth="2.3"
        strokeLinecap="round"
      />
      <rect x="8" y="10.2" width="11.5" height="3.2" rx="1" fill="#2BAB23" />
      <path
        d="M8.2 16.8h11M8.2 20.6h8"
        stroke="#2BAB23"
        strokeWidth="2.2"
        strokeLinecap="round"
      />
    </svg>
  );
}

/** UI Kit Column 1 & 2 #4: Nintendo eShop red shopping bag (#F11615) */
export function UiKitEshopIcon({ size, badgeBg }: { size: number; badgeBg?: string }) {
  const icon = (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <path
        d="M11.5 11V8.8a4.5 4.5 0 0 1 9 0V11"
        stroke="#F11615"
        strokeWidth="2.3"
        strokeLinecap="round"
      />
      <path
        d="M6.6 11.5h18.8l1.2 13.3a2.2 2.2 0 0 1-2.2 2.4H7.6a2.2 2.2 0 0 1-2.2-2.4l1.2-13.3Z"
        stroke="#F11615"
        strokeWidth="2.3"
        strokeLinejoin="round"
      />
      <path
        d="M12.2 15.2a3.8 3.8 0 0 0 7.6 0"
        stroke="#F11615"
        strokeWidth="2.1"
        strokeLinecap="round"
      />
    </svg>
  );

  if (!badgeBg) return icon;

  return (
    <span
      className="rounded-full flex items-center justify-center"
      style={{
        width: `${Math.round(size * 1.35)}px`,
        height: `${Math.round(size * 1.35)}px`,
        backgroundColor: badgeBg,
      }}
    >
      {icon}
    </span>
  );
}

/** UI Kit Column 2 #5: Album blue rounded landscape (#215FE5) */
export function UiKitAlbumIcon({ size }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <rect
        x="4.5"
        y="6.5"
        width="23"
        height="19"
        rx="4"
        stroke="#215FE5"
        strokeWidth="2.3"
      />
      <path
        d="M6.5 22l5.2-6.2a1.4 1.4 0 0 1 2.2.1l3.6 4.4 2.8-3a1.4 1.4 0 0 1 2.1.1L26 22"
        stroke="#215FE5"
        strokeWidth="2.2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="19.5" cy="12" r="1.8" fill="#215FE5" />
    </svg>
  );
}

/** UI Kit Column 2 #6: GameShare teal tray & wireless waves (#2CADBF) */
export function UiKitGameShareIcon({ size }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <path
        d="M6 19.5v4a2.5 2.5 0 0 0 2.5 2.5h15a2.5 2.5 0 0 0 2.5-2.5v-4"
        stroke="#2CADBF"
        strokeWidth="2.4"
        strokeLinecap="round"
      />
      <path
        d="M10.5 16.8a7.8 7.8 0 0 1 11 0"
        stroke="#2CADBF"
        strokeWidth="2.3"
        strokeLinecap="round"
      />
      <path
        d="M7.8 12.6a11.8 11.8 0 0 1 16.4 0"
        stroke="#2CADBF"
        strokeWidth="2.3"
        strokeLinecap="round"
      />
      <path
        d="M13.5 20.5a3.5 3.5 0 0 1 5 0"
        stroke="#2CADBF"
        strokeWidth="2.3"
        strokeLinecap="round"
      />
    </svg>
  );
}

/** UI Kit Column 2 #7: Controllers tilted Joy-Con 2 outline */
export function UiKitControllersIcon({ size, color = '#767676' }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <g transform="rotate(32 16 16)">
        <rect
          x="10.2"
          y="3.5"
          width="11.6"
          height="25"
          rx="5.8"
          stroke={color}
          strokeWidth="2.2"
        />
        <circle cx="16" cy="10.2" r="2.2" fill={color} />
        <circle cx="16" cy="16.5" r="1.2" fill={color} />
        <circle cx="13.5" cy="19" r="1.2" fill={color} />
        <circle cx="18.5" cy="19" r="1.2" fill={color} />
        <circle cx="16" cy="21.5" r="1.2" fill={color} />
      </g>
    </svg>
  );
}

/** UI Kit Column 2 #8: Virtual Game Card / Handheld Screen upright badge */
export function UiKitVirtualCardIcon({ size, color = '#767676' }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <rect
        x="7.5"
        y="4.5"
        width="17"
        height="23"
        rx="2.6"
        stroke={color}
        strokeWidth="2.2"
      />
      <rect x="13" y="18.5" width="6" height="5" rx="1" fill={color} />
      <path d="M11 9.5h10" stroke={color} strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

/** UI Kit Column 2 #9: System Settings 8-spoke gear */
export function UiKitSettingsIcon({ size, color = '#767676' }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <circle cx="16" cy="16" r="4.6" stroke={color} strokeWidth="2.3" />
      <path
        d="M16 4.5v3M16 24.5v3M4.5 16h3M24.5 16h3M7.9 7.9l2.2 2.2M21.9 21.9l2.2 2.2M24.1 7.9l-2.2 2.2M10.1 21.9l-2.2 2.2"
        stroke={color}
        strokeWidth="2.5"
        strokeLinecap="round"
      />
      <circle cx="16" cy="16" r="9.2" stroke={color} strokeWidth="2.2" />
    </svg>
  );
}

/** UI Kit Column 2 #10: Sleep Mode power button */
export function UiKitPowerIcon({ size, color = '#767676' }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <path
        d="M10.8 8.3a9.5 9.5 0 1 0 10.4 0"
        stroke={color}
        strokeWidth="2.4"
        strokeLinecap="round"
      />
      <path d="M16 5.5v10" stroke={color} strokeWidth="2.4" strokeLinecap="round" />
    </svg>
  );
}

/** Netflix-style folded red ribbon N icon matching Switch 2 dock sizing */
export function UiKitBrowserIcon({ size }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <rect x="6.5" y="4" width="5.4" height="24" rx="0.8" fill="#B20710" />
      <rect x="20.1" y="4" width="5.4" height="24" rx="0.8" fill="#B20710" />
      <path d="M6.5 4h5.4l13.6 24h-5.4L6.5 4z" fill="#E50914" />
    </svg>
  );
}
