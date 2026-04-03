import { useState } from "react";

import { promptInstallApp, usePwaInstallState } from "./pwa";

function InstallAppButton({ className = "" }) {
  const { canInstall, isInstalled } = usePwaInstallState();
  const [submitting, setSubmitting] = useState(false);

  if (isInstalled) {
    return (
      <span
        className={`inline-flex items-center justify-center rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-2.5 text-sm font-medium text-emerald-700 ${className}`.trim()}
      >
        已安装
      </span>
    );
  }

  if (!canInstall) {
    return null;
  }

  async function handleInstall() {
    setSubmitting(true);
    try {
      await promptInstallApp();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <button
      className={`inline-flex items-center justify-center rounded-2xl border border-indigo-200 bg-indigo-50 px-4 py-2.5 text-sm font-medium text-indigo-700 transition hover:bg-indigo-100 disabled:cursor-not-allowed disabled:opacity-60 ${className}`.trim()}
      disabled={submitting}
      onClick={() => void handleInstall()}
      type="button"
    >
      {submitting ? "安装中..." : "安装应用"}
    </button>
  );
}

export default InstallAppButton;
