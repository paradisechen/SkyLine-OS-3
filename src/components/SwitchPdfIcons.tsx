import React from 'react';

export type SwitchPdfButtonKey =
  | 'A'
  | 'B'
  | 'X'
  | 'Y'
  | 'L'
  | 'L1'
  | 'R'
  | 'R1'
  | 'ZL'
  | 'L2'
  | 'ZR'
  | 'R2'
  | 'SL'
  | 'SR'
  | 'PLUS'
  | 'MINUS'
  | 'HOME'
  | 'CAPTURE'
  | 'DPAD'
  | 'STICK_L'
  | 'STICK_R';

interface SwitchPdfIconProps {
  button: SwitchPdfButtonKey;
  size?: number;
  fillColor?: string;
  cutoutColor?: string;
}

/**
 * Exact Solid / Duo button glyph set matching Icon_sheets_1d0a2f81.pdf
 */
export function SwitchPdfIcon({
  button,
  size = 22,
  fillColor = '#FFFFFF',
  cutoutColor = '#191A1D',
}: SwitchPdfIconProps) {
  // Face Buttons: Solid circle with crisp punched label (A, B, X, Y)
  if (button === 'A' || button === 'B' || button === 'X' || button === 'Y') {
    return (
      <svg width={size} height={size} viewBox="0 0 28 28" fill="none" aria-hidden="true" className="shrink-0">
        <circle cx="14" cy="14" r="12.5" fill={fillColor} />
        <text
          x="14"
          y="14.8"
          textAnchor="middle"
          dominantBaseline="central"
          fill={cutoutColor}
          fontSize="14.5"
          fontWeight="800"
          fontFamily="var(--font-display)"
        >
          {button}
        </text>
      </svg>
    );
  }

  // Left Shoulder L / L1: Left-sloped pill matching Icon_sheets_1d0a2f81.pdf row 2
  if (button === 'L' || button === 'L1') {
    return (
      <svg
        width={Math.round(size * 1.48)}
        height={size}
        viewBox="0 0 42 28"
        fill="none"
        aria-hidden="true"
        className="shrink-0"
      >
        <path
          d="M5 17C5 9.2 11.4 4 21 4h12.5a3.5 3.5 0 0 1 3.5 3.5v13A3.5 3.5 0 0 1 33.5 24H8.5A3.5 3.5 0 0 1 5 20.5V17Z"
          fill={fillColor}
        />
        <text
          x="21.5"
          y="14.8"
          textAnchor="middle"
          dominantBaseline="central"
          fill={cutoutColor}
          fontSize="12"
          fontWeight="800"
          fontFamily="var(--font-display)"
        >
          {button}
        </text>
      </svg>
    );
  }

  // Right Shoulder R / R1: Right-sloped pill matching Icon_sheets_1d0a2f81.pdf row 2
  if (button === 'R' || button === 'R1') {
    return (
      <svg
        width={Math.round(size * 1.48)}
        height={size}
        viewBox="0 0 42 28"
        fill="none"
        aria-hidden="true"
        className="shrink-0"
      >
        <path
          d="M37 17C37 9.2 30.6 4 21 4H8.5A3.5 3.5 0 0 0 5 7.5v13A3.5 3.5 0 0 0 8.5 24h25a3.5 3.5 0 0 0 3.5-3.5V17Z"
          fill={fillColor}
        />
        <text
          x="20.5"
          y="14.8"
          textAnchor="middle"
          dominantBaseline="central"
          fill={cutoutColor}
          fontSize="12"
          fontWeight="800"
          fontFamily="var(--font-display)"
        >
          {button}
        </text>
      </svg>
    );
  }

  // Left Trigger ZL / L2
  if (button === 'ZL' || button === 'L2') {
    return (
      <svg
        width={Math.round(size * 1.38)}
        height={size}
        viewBox="0 0 38 28"
        fill="none"
        aria-hidden="true"
        className="shrink-0"
      >
        <path
          d="M5 10.5C5 6.8 8 4 11.8 4h16.7A4.5 4.5 0 0 1 33 8.5V21a3.5 3.5 0 0 1-3.5 3.5h-21A3.5 3.5 0 0 1 5 21V10.5Z"
          fill={fillColor}
        />
        <text
          x="19"
          y="14.8"
          textAnchor="middle"
          dominantBaseline="central"
          fill={cutoutColor}
          fontSize="12"
          fontWeight="800"
          fontFamily="var(--font-display)"
        >
          {button}
        </text>
      </svg>
    );
  }

  // Right Trigger ZR / R2
  if (button === 'ZR' || button === 'R2') {
    return (
      <svg
        width={Math.round(size * 1.38)}
        height={size}
        viewBox="0 0 38 28"
        fill="none"
        aria-hidden="true"
        className="shrink-0"
      >
        <path
          d="M33 10.5C33 6.8 30 4 26.2 4H9.5A4.5 4.5 0 0 0 5 8.5V21a3.5 3.5 0 0 0 3.5 3.5h21A3.5 3.5 0 0 0 33 21V10.5Z"
          fill={fillColor}
        />
        <text
          x="19"
          y="14.8"
          textAnchor="middle"
          dominantBaseline="central"
          fill={cutoutColor}
          fontSize="12"
          fontWeight="800"
          fontFamily="var(--font-display)"
        >
          {button}
        </text>
      </svg>
    );
  }

  // SL / SR Rail Buttons
  if (button === 'SL' || button === 'SR') {
    return (
      <svg
        width={Math.round(size * 1.55)}
        height={size}
        viewBox="0 0 44 28"
        fill="none"
        aria-hidden="true"
        className="shrink-0"
      >
        <rect x="4" y="6" width="36" height="16" rx="8" fill={fillColor} />
        <text
          x="22"
          y="14.5"
          textAnchor="middle"
          dominantBaseline="central"
          fill={cutoutColor}
          fontSize="11.5"
          fontWeight="800"
          fontFamily="var(--font-display)"
        >
          {button}
        </text>
      </svg>
    );
  }

  // Plus (+) button: Solid circle + thick rounded cross matching Icon_sheets_1d0a2f81.pdf row 3
  if (button === 'PLUS') {
    return (
      <svg width={size} height={size} viewBox="0 0 28 28" fill="none" aria-hidden="true" className="shrink-0">
        <circle cx="14" cy="14" r="12.5" fill={fillColor} />
        <path
          d="M14 8.5v11M8.5 14h11"
          stroke={cutoutColor}
          strokeWidth="3.2"
          strokeLinecap="round"
        />
      </svg>
    );
  }

  // Minus (-) button
  if (button === 'MINUS') {
    return (
      <svg width={size} height={size} viewBox="0 0 28 28" fill="none" aria-hidden="true" className="shrink-0">
        <circle cx="14" cy="14" r="12.5" fill={fillColor} />
        <path d="M8.5 14h11" stroke={cutoutColor} strokeWidth="3.2" strokeLinecap="round" />
      </svg>
    );
  }

  // Home House Icon (row 4 left in PDF)
  if (button === 'HOME') {
    return (
      <svg width={size} height={size} viewBox="0 0 28 28" fill="none" aria-hidden="true" className="shrink-0">
        <circle cx="14" cy="14" r="12.5" fill={fillColor} />
        <path
          d="M8.5 14.2 14 9l5.5 5.2V19a1 1 0 0 1-1 1h-3v-3.5h-3V20h-3a1 1 0 0 1-1-1v-4.8Z"
          fill={cutoutColor}
        />
      </svg>
    );
  }

  // Capture Square Button (row 4 right in PDF)
  if (button === 'CAPTURE') {
    return (
      <svg width={size} height={size} viewBox="0 0 28 28" fill="none" aria-hidden="true" className="shrink-0">
        <rect x="3" y="3" width="22" height="22" rx="4.5" fill={fillColor} />
        <circle cx="14" cy="14" r="5.2" fill={cutoutColor} />
      </svg>
    );
  }

  // Solid 4-Direction Cross D-Pad (row 7 in PDF)
  if (button === 'DPAD') {
    return (
      <svg width={size} height={size} viewBox="0 0 28 28" fill="none" aria-hidden="true" className="shrink-0">
        <path
          d="M11 4.5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2V11h6.5a2 2 0 0 1 2 2v2a2 2 0 0 1-2 2H17v6.5a2 2 0 0 1-2 2h-2a2 2 0 0 1-2-2V17H4.5a2 2 0 0 1-2-2v-2a2 2 0 0 1 2-2H11V4.5Z"
          fill={fillColor}
        />
      </svg>
    );
  }

  // Left / Right Analog Stick with Directional Ring (rows 8-10 in PDF)
  const stickLetter = button === 'STICK_R' ? 'R' : 'L';
  return (
    <svg width={size} height={size} viewBox="0 0 28 28" fill="none" aria-hidden="true" className="shrink-0">
      <circle cx="14" cy="14" r="9.5" fill={fillColor} />
      <circle cx="14" cy="2.2" r="1.5" fill={fillColor} />
      <circle cx="14" cy="25.8" r="1.5" fill={fillColor} />
      <circle cx="2.2" cy="14" r="1.5" fill={fillColor} />
      <circle cx="25.8" cy="14" r="1.5" fill={fillColor} />
      <text
        x="14"
        y="14.6"
        textAnchor="middle"
        dominantBaseline="central"
        fill={cutoutColor}
        fontSize="11.5"
        fontWeight="800"
        fontFamily="var(--font-display)"
      >
        {stickLetter}
      </text>
    </svg>
  );
}
