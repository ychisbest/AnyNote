import { useState } from "react";

import { request } from "./api";
import { setAuthToken } from "./auth";
import InstallAppButton from "./InstallAppButton";

function LoginPage({ onAuthenticated }) {
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(event) {
    event.preventDefault();
    const token = password.trim();
    if (!token) {
      setError("请输入访问密码");
      return;
    }

    setSubmitting(true);
    setError("");

    try {
      await request("/healthz", { authToken: token });
      setAuthToken(token);
      onAuthenticated();
    } catch (err) {
      setError(err.message || "登录失败");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-4 py-10">
      <div className="w-full max-w-md rounded-[28px] border border-slate-200 bg-white p-8 shadow-[0_24px_80px_rgba(15,23,42,0.10)]">
        <div className="mb-8">
          <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-indigo-500">
            AnyNote Access
          </p>
          <h1 className="m-0 text-3xl font-semibold tracking-tight text-slate-900">
            登录笔记空间
          </h1>
          <p className="mt-3 text-sm leading-6 text-slate-500">
            输入服务端配置的访问密码。验证成功后，Token 会保存在当前浏览器的
            localStorage 中。
          </p>
          <div className="mt-4">
            <InstallAppButton className="w-full" />
          </div>
        </div>

        <form className="space-y-4" onSubmit={handleSubmit}>
          <label className="block">
            <span className="mb-2 block text-sm font-medium text-slate-700">访问密码</span>
            <input
              autoComplete="current-password"
              className="h-12 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 text-sm text-slate-700 outline-none transition placeholder:text-slate-400 focus:border-indigo-200 focus:bg-white focus:ring-4 focus:ring-indigo-100"
              onChange={(event) => setPassword(event.target.value)}
              placeholder="请输入密码"
              type="password"
              value={password}
            />
          </label>

          {error ? (
            <div className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-600">
              {error}
            </div>
          ) : null}

          <button
            className="inline-flex h-12 w-full items-center justify-center rounded-2xl bg-indigo-600 px-4 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-indigo-300"
            disabled={submitting}
            type="submit"
          >
            {submitting ? "验证中..." : "登录"}
          </button>
        </form>
      </div>
    </div>
  );
}

export default LoginPage;
