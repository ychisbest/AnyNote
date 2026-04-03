import { useEffect, useState } from "react";

import App from "./App";
import { clearAuthToken, getAuthToken, subscribeToAuthTokenChange } from "./auth";
import LoginPage from "./LoginPage";

function getCurrentPath() {
  return window.location.pathname || "/";
}

function navigate(path, replace = false) {
  const method = replace ? "replaceState" : "pushState";
  window.history[method](null, "", path);
  window.dispatchEvent(new PopStateEvent("popstate"));
}

function AuthApp() {
  const [pathname, setPathname] = useState(getCurrentPath);
  const [token, setToken] = useState(getAuthToken);

  useEffect(() => {
    function syncState() {
      setPathname(getCurrentPath());
      setToken(getAuthToken());
    }

    window.addEventListener("popstate", syncState);
    const unsubscribe = subscribeToAuthTokenChange(syncState);

    return () => {
      window.removeEventListener("popstate", syncState);
      unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (!token && pathname !== "/login") {
      navigate("/login", true);
      return;
    }

    if (token && pathname === "/login") {
      navigate("/", true);
    }
  }, [pathname, token]);

  if (!token) {
    return <LoginPage onAuthenticated={() => navigate("/", true)} />;
  }

  return <App onLogout={() => clearAuthToken()} />;
}

export default AuthApp;
