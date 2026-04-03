import { clearAuthToken, getAuthToken } from "./auth";

const API_BASE_URL = (
  import.meta.env.DEV
    ? "https://memos.ych.show/api"
    : import.meta.env.VITE_API_BASE_URL || "/api"
).replace(/\/+$/, "");

export async function request(path, options = {}) {
  const { authToken, headers, ...fetchOptions } = options;
  const resolvedToken = authToken ?? getAuthToken();

  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      "Content-Type": "application/json",
      ...(resolvedToken ? { "X-Auth-Token": resolvedToken } : {}),
      ...(headers || {}),
    },
    ...fetchOptions,
  });

  if (response.status === 401 && resolvedToken && resolvedToken === getAuthToken()) {
    clearAuthToken();
  }

  if (response.status === 204) {
    return null;
  }

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.error || "Request failed");
  }

  return data;
}
