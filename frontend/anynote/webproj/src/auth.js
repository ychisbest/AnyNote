const AUTH_TOKEN_KEY = "anynote.authToken";
const NOTES_CACHE_KEY = "anynote.notesCache";
const AUTH_CHANGE_EVENT = "anynote:auth-token-changed";

function emitAuthChange() {
  window.dispatchEvent(new Event(AUTH_CHANGE_EVENT));
}

export function getAuthToken() {
  return window.localStorage.getItem(AUTH_TOKEN_KEY) || "";
}

export function setAuthToken(token) {
  window.localStorage.setItem(AUTH_TOKEN_KEY, token);
  emitAuthChange();
}

export function clearAuthToken() {
  window.localStorage.removeItem(AUTH_TOKEN_KEY);
  window.localStorage.removeItem(NOTES_CACHE_KEY);
  emitAuthChange();
}

export function subscribeToAuthTokenChange(callback) {
  window.addEventListener(AUTH_CHANGE_EVENT, callback);
  window.addEventListener("storage", callback);

  return () => {
    window.removeEventListener(AUTH_CHANGE_EVENT, callback);
    window.removeEventListener("storage", callback);
  };
}
