import React from "react";
import ReactDOM from "react-dom/client";
import AuthApp from "./AuthApp";
import { registerServiceWorker, setupPwaInstallEvents } from "./pwa";
import "./index.css";

registerServiceWorker();
setupPwaInstallEvents();

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <AuthApp />
  </React.StrictMode>,
);
