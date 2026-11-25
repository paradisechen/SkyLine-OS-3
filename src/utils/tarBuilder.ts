export interface TarEntry {
  path: string;
  content: string | Uint8Array;
}

function writeAscii(buf: Uint8Array, offset: number, str: string, length: number): void {
  for (let i = 0; i < length; i++) {
    buf[offset + i] = i < str.length ? str.charCodeAt(i) & 0x7f : 0;
  }
}

function writeOctal(buf: Uint8Array, offset: number, value: number, length: number): void {
  const oct = value.toString(8).padStart(length - 1, '0');
  writeAscii(buf, offset, oct, length - 1);
  buf[offset + length - 1] = 0;
}

/**
 * Builds a valid POSIX USTAR `.tar` byte buffer in memory (zero dependencies).
 */
export function buildTarArchive(entries: TarEntry[]): Uint8Array {
  const encoder = new TextEncoder();
  const blocks: Uint8Array[] = [];
  const nowSec = Math.floor(Date.now() / 1000);

  for (const entry of entries) {
    const cleanPath = entry.path.replace(/^\/+/, '');
    const data = typeof entry.content === 'string' ? encoder.encode(entry.content) : entry.content;

    const header = new Uint8Array(512);
    writeAscii(header, 0, cleanPath.slice(0, 100), 100); // name
    writeOctal(header, 100, 0o644, 8); // mode
    writeOctal(header, 108, 0, 8); // uid
    writeOctal(header, 116, 0, 8); // gid
    writeOctal(header, 124, data.length, 12); // size
    writeOctal(header, 136, nowSec, 12); // mtime
    for (let i = 148; i < 156; i++) header[i] = 32; // checksum spaces
    header[156] = '0'.charCodeAt(0); // regular file
    writeAscii(header, 257, 'ustar', 6); // magic
    writeAscii(header, 263, '00', 2); // version

    let sum = 0;
    for (let i = 0; i < 512; i++) sum += header[i];
    const chk = sum.toString(8).padStart(6, '0');
    writeAscii(header, 148, chk, 6);
    header[154] = 0;
    header[155] = 32;

    blocks.push(header);

    if (data.length > 0) {
      const paddedLen = Math.ceil(data.length / 512) * 512;
      const body = new Uint8Array(paddedLen);
      body.set(data, 0);
      blocks.push(body);
    }
  }

  // Two 512-byte zero blocks mark EOF
  blocks.push(new Uint8Array(1024));

  const totalSize = blocks.reduce((acc, b) => acc + b.length, 0);
  const out = new Uint8Array(totalSize);
  let cursor = 0;
  for (const b of blocks) {
    out.set(b, cursor);
    cursor += b.length;
  }
  return out;
}
