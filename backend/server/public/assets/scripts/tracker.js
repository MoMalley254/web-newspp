// === Init Fingerprint ===
function getOrCreateFingerprint() {
  let fp = localStorage.getItem('deviceFingerprint');
  if (!fp) {
    fp = crypto.randomUUID();
    localStorage.setItem('deviceFingerprint', fp);
  }
  return fp;
}

// === Device Info ===
function getDeviceType() {
  const ua = navigator.userAgent;
  if (/mobile/i.test(ua)) return 'mobile';
  if (/tablet|ipad/i.test(ua)) return 'tablet';
  return 'desktop';
}

function getLanguage() {
  return navigator.language || 'unknown';
}

function idDevice() {
    const deviceFingerprint = getOrCreateFingerprint();
    const deviceType = getDeviceType();
    const language = getLanguage();

    console.log(`Device ${deviceFingerprint}, ${deviceType}, ${language}`);
}

idDevice();