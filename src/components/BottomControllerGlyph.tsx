interface BottomControllerGlyphProps {
  size: number;
  color: string;
}

/**
 * Nintendo Switch dual Joy-Con controller glyph rendered inline as SVG,
 * tinted cleanly to the active Switch 2 foreground palette.
 */
export function BottomControllerGlyph({ size, color }: BottomControllerGlyphProps) {
  const height = Math.max(16, Math.round(size * 0.72));
  return (
    <svg
      aria-hidden="true"
      data-testid="bottom-controller-glyph"
      width={size}
      height={height}
      viewBox="0 0 64 46"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className="inline-block shrink-0 transition-colors duration-200"
    >
      {/* Left Joy-Con with outer cutouts (evenodd) */}
      <path
        fill={color}
        fillRule="evenodd"
        clipRule="evenodd"
        d="M17 3C9.268 3 3 9.268 3 17v12c0 7.732 6.268 14 14 14h9.5a2.5 2.5 0 0 0 2.5-2.5V5.5A2.5 2.5 0 0 0 26.5 3H17Zm-1 14.5a4.5 4.5 0 1 0 0-9 4.5 4.5 0 0 0 0 9Zm0 7.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4Zm0 10a2 2 0 1 0 0-4 2 2 0 0 0 0 4Zm-5-5a2 2 0 1 0 0-4 2 2 0 0 0 0 4Zm10 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z"
      />
      {/* Right Joy-Con with outer cutouts (evenodd) */}
      <path
        fill={color}
        fillRule="evenodd"
        clipRule="evenodd"
        d="M37.5 3A2.5 2.5 0 0 0 35 5.5v35a2.5 2.5 0 0 0 2.5 2.5H47c7.732 0 14-6.268 14-14V17c0-7.732-6.268-14-14-14h-9.5Zm10.5 32.5a4.5 4.5 0 1 0 0-9 4.5 4.5 0 0 0 0 9Zm0-24a2 2 0 1 0 0-4 2 2 0 0 0 0 4Zm0 10a2 2 0 1 0 0-4 2 2 0 0 0 0 4Zm-5-5a2 2 0 1 0 0-4 2 2 0 0 0 0 4Zm10 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z"
      />
    </svg>
  );
}
