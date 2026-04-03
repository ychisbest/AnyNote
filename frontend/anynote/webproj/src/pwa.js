import { useEffect, useState } from "react";

let deferredInstallPrompt = null;
const listeners = new Set();
const INSTALL_STATE_KEY = "anynote-pwa-installed";

function readInstalledFlag() {
  if (typeof window === "undefined") {
    return false;
  }

  try {
    return window.localStorage.getItem(INSTALL_STATE_KEY) === "true";
  } catch {
    return false;
  }
}

function writeInstalledFlag(value) {
  if (typeof window === "undefined") {
    return;
  }

  try {
    if (value) {
      window.localStorage.setItem(INSTALL_STATE_KEY, "true");
    } else {
      window.localStorage.removeItem(INSTALL_STATE_KEY);
    }
  } catch {
    // Ignore storage failures and keep runtime state functional.
  }
}

function isStandaloneMode() {
  return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true;
}

function emitInstallState() {
  const isInstalled = isStandaloneMode() || readInstalledFlag();

  if (isInstalled) {
    writeInstalledFlag(true);
  }

  const state = {
    canInstall: Boolean(deferredInstallPrompt) && !isInstalled,
    isInstalled,
  };
  listeners.forEach((listener) => listener(state));
}

export function registerServiceWorker() {
  if (!("serviceWorker" in navigator) || import.meta.env.DEV) {
    return;
  }

  window.addEventListener("load", () => {
    void navigator.serviceWorker.register("/sw.js");
  });
}

export function setupPwaInstallEvents() {
  if (typeof window === "undefined") {
    return () => {};
  }

  const handleBeforeInstallPrompt = (event) => {
    event.preventDefault();
    deferredInstallPrompt = event;
    emitInstallState();
  };

  const handleInstalled = () => {
    deferredInstallPrompt = null;
    writeInstalledFlag(true);
    emitInstallState();
  };

  const handleDisplayModeChange = () => {
    emitInstallState();
  };

  window.addEventListener("beforeinstallprompt", handleBeforeInstallPrompt);
  window.addEventListener("appinstalled", handleInstalled);
  window.matchMedia("(display-mode: standalone)").addEventListener("change", handleDisplayModeChange);
  emitInstallState();

  return () => {
    window.removeEventListener("beforeinstallprompt", handleBeforeInstallPrompt);
    window.removeEventListener("appinstalled", handleInstalled);
    window.matchMedia("(display-mode: standalone)").removeEventListener("change", handleDisplayModeChange);
  };
}

export async function promptInstallApp() {
  if (!deferredInstallPrompt) {
    return false;
  }

  deferredInstallPrompt.prompt();
  const outcome = await deferredInstallPrompt.userChoice;
  deferredInstallPrompt = null;

  if (outcome?.outcome === "accepted") {
    writeInstalledFlag(true);
  }

  emitInstallState();
  return outcome?.outcome === "accepted";
}

export function usePwaInstallState() {
  const [state, setState] = useState(() => ({
    canInstall: Boolean(deferredInstallPrompt),
    isInstalled:
      typeof window !== "undefined"
        ? isStandaloneMode() || readInstalledFlag()
        : false,
  }));

  useEffect(() => {
    listeners.add(setState);
    emitInstallState();
    return () => listeners.delete(setState);
  }, []);

  return state;
}
