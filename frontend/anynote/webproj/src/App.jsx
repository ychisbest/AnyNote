import { useEffect, useMemo, useRef, useState } from "react";
import { List, useDynamicRowHeight } from "react-window";
import ReactMarkdown from "react-markdown";
import remarkBreaks from "remark-breaks";
import remarkGfm from "remark-gfm";

import { request } from "./api";
import InstallAppButton from "./InstallAppButton";

const NOTES_CACHE_KEY = "anynote.notesCache";
const emptyForm = {
  content: "",
  isArchived: false,
  pinned: false,
};

const weekdayLabels = ["日", "一", "二", "三", "四", "五", "六"];
const tagPalette = [
  { dot: "bg-indigo-500", pill: "bg-indigo-50 text-indigo-700" },
  { dot: "bg-emerald-500", pill: "bg-emerald-50 text-emerald-700" },
  { dot: "bg-amber-400", pill: "bg-amber-50 text-amber-700" },
  { dot: "bg-rose-400", pill: "bg-rose-50 text-rose-700" },
  { dot: "bg-sky-500", pill: "bg-sky-50 text-sky-700" },
  { dot: "bg-violet-500", pill: "bg-violet-50 text-violet-700" },
];

function formatDayTime(value) {
  if (!value) {
    return { day: "-", time: "-" };
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return { day: value, time: "-" };
  }

  return {
    day: new Intl.DateTimeFormat("zh-CN", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(date),
    time: new Intl.DateTimeFormat("zh-CN", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }).format(date),
  };
}

function getDateKey(value) {
  if (!value) {
    return "";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "";
  }

  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function shiftMonth(monthKey, offset) {
  const [year, month] = monthKey.split("-").map(Number);
  const next = new Date(year, month - 1 + offset, 1);
  return `${next.getFullYear()}-${`${next.getMonth() + 1}`.padStart(2, "0")}`;
}

function getMonthParts(monthKey) {
  const [year, month] = monthKey.split("-").map(Number);
  return {
    year,
    monthLabel: new Intl.DateTimeFormat("zh-CN", {
      month: "numeric",
    }).format(new Date(year, month - 1, 1)),
  };
}

function buildYearMonths(year) {
  return Array.from({ length: 12 }, (_, index) => {
    const month = `${index + 1}`.padStart(2, "0");
    return `${year}-${month}`;
  });
}

function buildCalendarDays(monthKey) {
  const [year, month] = monthKey.split("-").map(Number);
  const firstDay = new Date(year, month - 1, 1);
  const daysInMonth = new Date(year, month, 0).getDate();
  const leadingEmptyDays = firstDay.getDay();
  const cells = [];

  for (let index = 0; index < leadingEmptyDays; index += 1) {
    cells.push(null);
  }

  for (let day = 1; day <= daysInMonth; day += 1) {
    cells.push(
      `${year}-${`${month}`.padStart(2, "0")}-${`${day}`.padStart(2, "0")}`,
    );
  }

  return cells;
}

function extractTags(content) {
  const matches = content.match(/#[\p{L}\p{N}_/-]+/gu) || [];
  return [...new Set(matches.map((item) => item.slice(1)))];
}

function getTagColor(tag) {
  const hash = [...tag].reduce((total, char) => total + char.charCodeAt(0), 0);
  return tagPalette[hash % tagPalette.length];
}

function buildTagTreeRows(tagCounts) {
  const root = new Map();

  tagCounts.forEach((count, tag) => {
    const parts = tag.split("/").filter(Boolean);
    let level = root;
    let currentPath = "";

    parts.forEach((part) => {
      currentPath = currentPath ? `${currentPath}/${part}` : part;
      if (!level.has(part)) {
        level.set(part, {
          name: part,
          path: currentPath,
          count: 0,
          children: new Map(),
        });
      }

      const node = level.get(part);
      node.count += count;
      level = node.children;
    });
  });

  function flatten(nodes, depth = 0) {
    return [...nodes.values()]
      .sort((left, right) => right.count - left.count || left.name.localeCompare(right.name, "zh-CN"))
      .flatMap((node) => [
        {
          count: node.count,
          depth,
          hasChildren: node.children.size > 0,
          path: node.path,
        },
        ...flatten(node.children, depth + 1),
      ]);
  }

  return flatten(root);
}

function MarkdownCode({ className, children, ...props }) {
  const [copied, setCopied] = useState(false);
  const code = String(children).replace(/\n$/, "");
  const language = className?.replace(/^language-/, "");
  const isBlockCode = Boolean(language) || code.includes("\n");

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1500);
    } catch {
      setCopied(false);
    }
  }

  if (!isBlockCode) {
    return (
      <span
        className="rounded-md bg-slate-200 px-1.5 py-0.5 text-[0.92em] text-slate-700"
        {...props}
      >
        {children}
      </span>
    );
  }

  return (
    <div className="markdown-code-block">
      <div className="markdown-code-toolbar">
        <span className="markdown-code-language">{language || "code"}</span>
        <button
          className="markdown-code-copy"
          onClick={() => void handleCopy()}
          type="button"
        >
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
      <pre>
        <code className={className} {...props}>
          {code}
        </code>
      </pre>
    </div>
  );
}

function MarkdownContent({ content }) {
  return (
    <div className="markdown-body break-words text-[15px] leading-7 text-slate-700">
      <ReactMarkdown
        remarkPlugins={[remarkGfm, remarkBreaks]}
        components={{
          a: ({ ...props }) => <a {...props} rel="noreferrer" target="_blank" />,
          code: MarkdownCode,
          pre: ({ children }) => <>{children}</>,
        }}
      >
        {content || ""}
      </ReactMarkdown>
    </div>
  );
}

function useElementSize(targetRef) {
  const [size, setSize] = useState({ height: 0, width: 0 });

  useEffect(() => {
    const element = targetRef.current;
    if (!element) {
      return undefined;
    }

    const updateSize = () => {
      setSize({
        height: element.clientHeight,
        width: element.clientWidth,
      });
    };

    updateSize();

    if (typeof ResizeObserver === "undefined") {
      window.addEventListener("resize", updateSize);
      return () => window.removeEventListener("resize", updateSize);
    }

    const observer = new ResizeObserver(updateSize);
    observer.observe(element);

    return () => observer.disconnect();
  }, [targetRef]);

  return size;
}

function NoteCard({ note, onDelete, onEdit, onSelectTag }) {
  return (
    <article
      className={[
        "group relative rounded-[26px] border p-5 shadow-sm transition",
        note.pinned
          ? "border-amber-200 bg-amber-50/80 shadow-[0_10px_30px_rgba(245,158,11,0.10)] hover:border-amber-300"
          : "border-slate-200 bg-white hover:border-indigo-200",
      ].join(" ")}
    >
      <div className="min-w-0">
        <div className="mb-3 flex items-start justify-between gap-3">
          <div className="flex min-w-0 flex-wrap items-center gap-1.5 text-xs text-slate-400">
            <span>{note.meta.day}</span>
            <span>{note.meta.time}</span>
            {note.pinned ? <span>置顶</span> : null}
          </div>

          <div className="flex shrink-0 items-center gap-2 opacity-100 transition sm:opacity-0 sm:group-hover:opacity-100">
            <button
              className="rounded-xl px-3 py-2 text-xs text-slate-400 transition hover:bg-slate-50 hover:text-slate-700"
              onClick={() => onEdit(note)}
              type="button"
            >
              编辑
            </button>
            <button
              aria-label="Delete note"
              className="rounded-xl p-2 text-slate-300 transition hover:bg-rose-50 hover:text-rose-500"
              onClick={() => void onDelete(note.id)}
              type="button"
            >
              <IconTrash />
            </button>
          </div>
        </div>

        <MarkdownContent content={note.content} />

        {note.tags.length > 0 ? (
          <div className="mt-4 flex flex-wrap gap-2">
            {note.tags.map((tag) => {
              const color = getTagColor(tag);
              return (
                <button
                  className={[
                    "rounded-md px-2 py-1 text-[11px] font-medium transition",
                    color.pill,
                  ].join(" ")}
                  key={tag}
                  onClick={() => onSelectTag(tag)}
                  type="button"
                >
                  #{tag}
                </button>
              );
            })}
          </div>
        ) : null}
      </div>
    </article>
  );
}

function NoteRow({ ariaAttributes, index, notes, onDelete, onEdit, onSelectTag, style }) {
  const note = notes[index];

  return (
    <div
      {...ariaAttributes}
      className="box-border px-0 pb-5"
      style={style}
    >
      <NoteCard
        note={note}
        onDelete={onDelete}
        onEdit={onEdit}
        onSelectTag={onSelectTag}
      />
    </div>
  );
}

function VirtualizedNoteList({ notes, onDelete, onEdit, onSelectTag }) {
  const containerRef = useRef(null);
  const listRef = useRef(null);
  const { height, width } = useElementSize(containerRef);
  const rowHeight = useDynamicRowHeight({
    defaultRowHeight: 280,
    key: notes
      .map(
        (note) =>
          `${note.id}:${note.update_time || ""}:${note.content}:${note.pinned}:${note.is_archived}`,
      )
      .join("|"),
  });

  useEffect(() => {
    listRef.current?.scrollToRow({ align: "start", index: 0 });
  }, [notes]);

  return (
    <div className="min-h-[24rem] flex-1" ref={containerRef}>
      {height > 0 && width > 0 ? (
        <List
          className="custom-scrollbar"
          defaultHeight={Math.max(height, 384)}
          listRef={listRef}
          overscanCount={4}
          rowComponent={NoteRow}
          rowCount={notes.length}
          rowHeight={rowHeight}
          rowProps={{ notes, onDelete, onEdit, onSelectTag }}
          style={{ height, width }}
        />
      ) : null}
    </div>
  );
}

function IconSearch() {
  return (
    <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 20 20" fill="none">
      <path
        d="M14.166 14.167 17.5 17.5M15.833 8.75a7.083 7.083 0 1 1-14.166 0 7.083 7.083 0 0 1 14.166 0Z"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.7"
      />
    </svg>
  );
}

function IconMenu() {
  return (
    <svg aria-hidden="true" className="h-5 w-5" viewBox="0 0 20 20" fill="none">
      <path
        d="M3.333 5.833h13.334M3.333 10h13.334M3.333 14.167h13.334"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.8"
      />
    </svg>
  );
}

function IconPlus() {
  return (
    <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 20 20" fill="none">
      <path
        d="M10 4.167v11.666M4.167 10h11.666"
        stroke="currentColor"
        strokeLinecap="round"
        strokeWidth="1.7"
      />
    </svg>
  );
}

function IconTrash() {
  return (
    <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 20 20" fill="none">
      <path
        d="M7.5 5V3.75c0-.46.373-.833.833-.833h3.334c.46 0 .833.373.833.833V5m-7.5 0h10m-9.167 1.667.625 8.125c.03.4.364.708.766.708h4.552c.402 0 .736-.308.767-.708l.624-8.125M8.75 8.333v4.584m2.5-4.584v4.584"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.4"
      />
    </svg>
  );
}

function IconExpand() {
  return (
    <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 20 20" fill="none">
      <path
        d="M7.5 2.917H4.583a1.666 1.666 0 0 0-1.666 1.666V7.5M12.5 2.917h2.917a1.666 1.666 0 0 1 1.666 1.666V7.5M7.5 17.083H4.583a1.666 1.666 0 0 1-1.666-1.666V12.5M12.5 17.083h2.917a1.666 1.666 0 0 0 1.666-1.666V12.5"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.5"
      />
    </svg>
  );
}

function readCachedNotes() {
  try {
    const raw = window.localStorage.getItem(NOTES_CACHE_KEY);
    if (!raw) {
      return [];
    }

    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function writeCachedNotes(notes) {
  window.localStorage.setItem(NOTES_CACHE_KEY, JSON.stringify(notes));
}

function App({ onLogout }) {
  const todayKey = getDateKey(new Date());
  const [notes, setNotes] = useState(() => readCachedNotes());
  const [form, setForm] = useState(emptyForm);
  const [editingId, setEditingId] = useState(null);
  const [loading, setLoading] = useState(() => readCachedNotes().length === 0);
  const [refreshing, setRefreshing] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [networkStatus, setNetworkStatus] = useState("");
  const [selectedDate, setSelectedDate] = useState(todayKey);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTag, setSelectedTag] = useState("all");
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const [composerFocused, setComposerFocused] = useState(false);
  const [calendarMonth, setCalendarMonth] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${`${now.getMonth() + 1}`.padStart(2, "0")}`;
  });
  const [yearPickerOpen, setYearPickerOpen] = useState(false);
  const [yearPickerYear, setYearPickerYear] = useState(() => new Date().getFullYear());
  const composerRef = useRef(null);
  const composerHistoryOpenRef = useRef(false);
  const suppressComposerPopRef = useRef(false);
  const isExpandedComposerRef = useRef(false);

  async function loadNotes({ showLoading = false } = {}) {
    if (showLoading) {
      setLoading(true);
    } else {
      setRefreshing(true);
    }
    setError("");

    try {
      const data = await request("/notes");
      const nextNotes = Array.isArray(data) ? data : [];
      setNotes(nextNotes);
      writeCachedNotes(nextNotes);
      setNetworkStatus("在线");
    } catch (err) {
      setError(err.message);
      setNetworkStatus("离线");
    } finally {
      if (showLoading) {
        setLoading(false);
      } else {
        setRefreshing(false);
      }
    }
  }

  useEffect(() => {
    void loadNotes({ showLoading: true });
  }, []);

  const notesWithMeta = useMemo(() => {
    return notes.map((note) => {
      const tags = extractTags(note.content);

      return {
        ...note,
        dateKey: getDateKey(note.create_time),
        meta: formatDayTime(note.create_time),
        searchableText: [
          note.content,
          note.pinned ? "pinned" : "",
          note.is_archived ? "archived" : "",
          ...tags,
        ]
          .join(" ")
          .toLowerCase(),
        tags,
      };
    });
  }, [notes]);

  const sortedNotes = useMemo(() => {
    return [...notesWithMeta].sort((left, right) => {
      if (left.pinned !== right.pinned) {
        return left.pinned ? -1 : 1;
      }

      return (
        new Date(right.create_time).getTime() -
        new Date(left.create_time).getTime()
      );
    });
  }, [notesWithMeta]);

  const tagCounts = useMemo(() => {
    const counts = new Map();

    notesWithMeta.forEach((note) => {
      note.tags.forEach((tag) => {
        counts.set(tag, (counts.get(tag) || 0) + 1);
      });
    });

    return counts;
  }, [notesWithMeta]);

  const tagTreeRows = useMemo(() => buildTagTreeRows(tagCounts), [tagCounts]);

  const noteDates = useMemo(() => {
    const counts = new Map();

    notesWithMeta.forEach((note) => {
      const key = note.dateKey;
      if (!key) {
        return;
      }

      counts.set(key, (counts.get(key) || 0) + 1);
    });

    return counts;
  }, [notesWithMeta]);

  const noteMonthCounts = useMemo(() => {
    const counts = new Map();

    notesWithMeta.forEach((note) => {
      if (!note.dateKey) {
        return;
      }

      const monthKey = note.dateKey.slice(0, 7);
      counts.set(monthKey, (counts.get(monthKey) || 0) + 1);
    });

    return counts;
  }, [notesWithMeta]);

  const filteredNotes = useMemo(() => {
    const searchTerms = searchQuery
      .trim()
      .toLowerCase()
      .split(/\s+/)
      .filter(Boolean);

    return sortedNotes.filter((note) => {
      const matchesSelectedDate = !selectedDate || note.dateKey === selectedDate;
      const bypassDateFilter = note.pinned && !note.is_archived;

      if (!matchesSelectedDate && !bypassDateFilter) {
        return false;
      }

      if (selectedTag === "pinned" && (!note.pinned || note.is_archived)) {
        return false;
      }

      if (
        selectedTag !== "all" &&
        selectedTag !== "pinned" &&
        !note.tags.includes(selectedTag)
      ) {
        return false;
      }

      if (searchTerms.length === 0) {
        return true;
      }

      return searchTerms.every((term) => note.searchableText.includes(term));
    });
  }, [searchQuery, selectedDate, selectedTag, sortedNotes]);

  const calendarDays = useMemo(() => buildCalendarDays(calendarMonth), [calendarMonth]);
  const calendarMonthParts = useMemo(() => getMonthParts(calendarMonth), [calendarMonth]);
  const yearPickerMonths = useMemo(
    () => buildYearMonths(yearPickerYear),
    [yearPickerYear],
  );

  useEffect(() => {
    if (!(composerFocused || editingId || yearPickerOpen)) {
      document.body.style.overflow = "";
      return undefined;
    }

    document.body.style.overflow = "hidden";
    const frame = window.requestAnimationFrame(() => {
      const textarea = composerRef.current?.querySelector("textarea");
      textarea?.focus();
    });

    return () => {
      window.cancelAnimationFrame(frame);
      document.body.style.overflow = "";
    };
  }, [composerFocused, editingId, yearPickerOpen]);

  useEffect(() => {
    isExpandedComposerRef.current = composerFocused || Boolean(editingId);
  }, [composerFocused, editingId]);

  useEffect(() => {
    function handlePopState() {
      if (suppressComposerPopRef.current) {
        suppressComposerPopRef.current = false;
        return;
      }

      if (!isExpandedComposerRef.current) {
        return;
      }

      composerHistoryOpenRef.current = false;
      setComposerFocused(false);
      setEditingId(null);
      setForm(emptyForm);
    }

    window.addEventListener("popstate", handlePopState);
    return () => window.removeEventListener("popstate", handlePopState);
  }, []);

  useEffect(() => {
    if (selectedDate) {
      setCalendarMonth(selectedDate.slice(0, 7));
    }
  }, [selectedDate]);

  useEffect(() => {
    setYearPickerYear(getMonthParts(calendarMonth).year);
  }, [calendarMonth]);

  useEffect(() => {
    if (!yearPickerOpen) {
      return undefined;
    }

    function handleKeyDown(event) {
      if (event.key === "Escape") {
        setYearPickerOpen(false);
      }
    }

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [yearPickerOpen]);

  function resetForm() {
    setForm(emptyForm);
    setEditingId(null);
  }

  function cancelEditing() {
    resetForm();
    closeFocusedComposer();
  }

  function handleChange(event) {
    const { name, value, checked, type } = event.target;
    setForm((current) => ({
      ...current,
      [name]: type === "checkbox" ? checked : value,
    }));
  }

  function handleComposerKeyDown(event) {
    if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
      event.preventDefault();
      if (!submitting) {
        event.currentTarget.form?.requestSubmit();
      }
    }
  }

  async function handleSubmit(event) {
    event.preventDefault();
    if (!form.content.trim()) {
      return;
    }

    setSubmitting(true);
    setError("");

    try {
      const payload = {
        content: form.content.trim(),
        is_archived: form.isArchived,
        pinned: form.pinned,
      };

      if (editingId) {
        const updatedNote = await request(`/notes/${editingId}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });

        setNotes((current) => {
          const nextNotes = current.map((note) => (note.id === editingId ? updatedNote : note));
          writeCachedNotes(nextNotes);
          return nextNotes;
        });
      } else {
        const createdNote = await request("/notes", {
          method: "POST",
          body: JSON.stringify(payload),
        });

        setNotes((current) => {
          const nextNotes = [createdNote, ...current];
          writeCachedNotes(nextNotes);
          return nextNotes;
        });
      }

      cancelEditing();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  function handleEdit(note) {
    setComposerFocused(true);
    setEditingId(note.id);
    setForm({
      content: note.content,
      isArchived: note.is_archived,
      pinned: note.pinned,
    });
  }

  async function handleDelete(id) {
    const confirmed = window.confirm("确认删除这条笔记？");
    if (!confirmed) {
      return;
    }

    setError("");
    try {
      await request(`/notes/${id}`, { method: "DELETE" });
      setNotes((current) => {
        const nextNotes = current.filter((note) => note.id !== id);
        writeCachedNotes(nextNotes);
        return nextNotes;
      });
      if (editingId === id) {
        cancelEditing();
      }
    } catch (err) {
      setError(err.message);
    }
  }

  function focusComposer() {
    setComposerFocused(true);
  }

  function closeFocusedComposer() {
    setComposerFocused(false);
  }

  function handleSelectTag(tag) {
    setSelectedDate("");
    setSelectedTag("all");
    setSearchQuery(`#${tag} `);
    setMobileSidebarOpen(false);
  }

  const isExpandedComposer = composerFocused || Boolean(editingId);

  useEffect(() => {
    if (isExpandedComposer && !composerHistoryOpenRef.current) {
      window.history.pushState({ anynoteComposer: true }, "", window.location.href);
      composerHistoryOpenRef.current = true;
      return;
    }

    if (!isExpandedComposer && composerHistoryOpenRef.current) {
      suppressComposerPopRef.current = true;
      composerHistoryOpenRef.current = false;
      window.history.back();
    }
  }, [isExpandedComposer]);

  const activeFilters = [];

  if (selectedDate) {
    activeFilters.push({
      key: "date",
      label: selectedDate,
      onClear: () => setSelectedDate(""),
    });
  }

  if (selectedTag !== "all") {
    activeFilters.push({
      key: "tag",
      label:
        selectedTag === "all"
          ? "全部笔记"
          : `#${selectedTag}`,
      onClear: () => setSelectedTag("all"),
    });
  }

  if (searchQuery.trim()) {
    activeFilters.push({
      key: "search",
      label: `搜索: ${searchQuery.trim()}`,
      onClear: () => setSearchQuery(""),
    });
  }

  const sidebarItems = [
    {
      key: "all",
      label: "全部笔记",
      count: notes.length,
    },
    {
      key: "today",
      label: "今日",
      count: notes.filter((note) => !note.is_archived && (note.pinned || getDateKey(note.create_time) === todayKey)).length,
    },
  ];

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800">
      <div className="flex min-h-screen">
        {mobileSidebarOpen ? (
          <button
            aria-label="关闭侧栏"
            className="fixed inset-0 z-30 bg-slate-900/20 md:hidden"
            onClick={() => setMobileSidebarOpen(false)}
            type="button"
          />
        ) : null}

        <aside
          className={[
            "fixed inset-y-0 left-0 z-40 flex w-72 flex-col border-r border-slate-200 bg-white transition-transform duration-200 md:sticky md:top-0 md:h-screen md:translate-x-0",
            mobileSidebarOpen ? "translate-x-0" : "-translate-x-full",
          ].join(" ")}
        >
          <div className="px-6 pb-5 pt-7">
            <div className="text-xl font-semibold tracking-tight text-indigo-600">
              AnyNote
            </div>
          </div>

          <nav className="custom-scrollbar flex-1 space-y-6 overflow-y-auto px-4 pb-6">
            <div className="sticky top-0 z-10 -mx-4 bg-white px-4 pb-4 pt-1">

              <div className="space-y-1">
                {sidebarItems.map((item) => {
                  const active =
                    item.key === "all"
                      ? !selectedDate && selectedTag === "all" && !searchQuery.trim()
                      : item.key === "today"
                        ? selectedDate === todayKey
                        : false;

                  return (
                    <button
                      className={[
                        "flex w-full items-center justify-between rounded-xl px-3 py-2 text-left text-sm font-medium transition",
                        active
                          ? "bg-indigo-50 text-indigo-700"
                          : "text-slate-600 hover:bg-slate-100",
                      ].join(" ")}
                      key={item.key}
                      onClick={() => {
                        if (item.key === "all") {
                          setSelectedTag("all");
                          setSelectedDate("");
                          setSearchQuery("");
                        } else if (item.key === "today") {
                          setSelectedTag("all");
                          setSearchQuery("");
                          setSelectedDate((current) => {
                            const nextValue = current === todayKey ? "" : todayKey;
                            if (nextValue) {
                              setCalendarMonth(todayKey.slice(0, 7));
                            }
                            return nextValue;
                          });
                        }
                        if (item.key === "today") {
                          setCalendarMonth(todayKey.slice(0, 7));
                        }
                        setMobileSidebarOpen(false);
                      }}
                      type="button"
                    >
                      <span>{item.label}</span>
                      <span className="text-xs text-slate-400">{item.count}</span>
                    </button>
                  );
                })}
              </div>

<hr className="my-4"></hr>
              {tagTreeRows.length ? (
                <div className="mt-4 space-y-1 px-2">
                  {tagTreeRows.map((tag) => {
                    const active = searchQuery.trim() === `#${tag.path}`;

                    return (
                      <button
                        className={[
                          "flex w-full items-center justify-between rounded-xl py-2 pl-3 pr-2 text-left text-xs transition",
                          active
                            ? "bg-indigo-50 text-indigo-700"
                            : "text-slate-600 hover:bg-slate-100 hover:text-slate-800",
                        ].join(" ")}
                        key={tag.path}
                        onClick={() => handleSelectTag(tag.path)}
                        style={{ paddingLeft: `${12 + tag.depth * 18}px` }}
                        type="button"
                      >
                        <span className="flex min-w-0 items-center gap-2">
                          <span className={tag.depth > 0 ? "text-slate-300" : "text-slate-400"}>
                            {tag.depth > 0 ? "└" : "#"}
                          </span>
                          <span className="truncate">
                            {tag.depth > 0 ? tag.path.split("/").at(-1) : tag.path}
                          </span>
                        </span>
                        <span className="shrink-0 text-[11px] text-slate-400">{tag.count}</span>
                      </button>
                    );
                  })}
                </div>
              ) : null}
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <button
                    className="rounded-md px-2 py-1 text-xs font-bold text-slate-700 transition hover:bg-white hover:text-indigo-600"
                    onClick={() => {
                      setYearPickerYear(calendarMonthParts.year);
                      setYearPickerOpen(true);
                    }}
                    type="button"
                  >
                    {calendarMonthParts.year}年{calendarMonthParts.monthLabel}
                  </button>
                </div>
                <div className="flex items-center gap-1 text-slate-400">
                  <button
                    className="rounded-md px-2 py-1 text-xs transition hover:bg-white hover:text-slate-600"
                    onClick={() => setCalendarMonth((current) => shiftMonth(current, -1))}
                    type="button"
                  >
                    ←
                  </button>
                  <button
                    className="rounded-md px-2 py-1 text-xs transition hover:bg-white hover:text-slate-600"
                    onClick={() => setCalendarMonth((current) => shiftMonth(current, 1))}
                    type="button"
                  >
                    →
                  </button>
                </div>
              </div>

              <div className="mb-2 grid grid-cols-7 gap-1 text-center text-[10px] text-slate-400">
                {weekdayLabels.map((day) => (
                  <span key={day}>{day}</span>
                ))}
              </div>

              <div className="grid grid-cols-7 gap-1 text-center text-[11px]">
                {calendarDays.map((dateKey, index) => {
                  if (!dateKey) {
                    return <span className="h-7" key={`empty-${index}`} />;
                  }

                  const dayNumber = Number(dateKey.slice(8, 10));
                  const noteCount = noteDates.get(dateKey) || 0;
                  const isSelected = selectedDate === dateKey;
                  const isToday = todayKey === dateKey;
                  const hasNotes = noteCount > 0;

                  return (
                    <button
                      className={[
                        "relative h-7 rounded-md transition",
                        isSelected
                          ? "bg-indigo-600 font-semibold text-white"
                          : hasNotes
                            ? "bg-indigo-50 font-medium text-indigo-700 hover:bg-indigo-100"
                            : "text-slate-500 hover:bg-white",
                        isToday && !isSelected ? "ring-1 ring-inset ring-indigo-200" : "",
                      ].join(" ")}
                      key={dateKey}
                      onClick={() =>
                        setSelectedDate((current) => (current === dateKey ? "" : dateKey))
                      }
                      title={
                        hasNotes
                          ? `${dateKey}，${noteCount} 条笔记`
                          : `${dateKey}，没有笔记`
                      }
                      type="button"
                    >
                      {dayNumber}
                      {hasNotes && !isSelected ? (
                        <span className="absolute bottom-1 left-1/2 h-1 w-1 -translate-x-1/2 rounded-full bg-indigo-400" />
                      ) : null}
                    </button>
                  );
                })}
              </div>

              <div className="mt-3 flex items-center justify-between text-[11px] text-slate-400">
                <button
                  className="transition hover:text-slate-600"
                  onClick={() => {
                    const now = new Date();
                    setCalendarMonth(
                      `${now.getFullYear()}-${`${now.getMonth() + 1}`.padStart(2, "0")}`,
                    );
                    setYearPickerYear(now.getFullYear());
                    setYearPickerOpen(false);
                  }}
                  type="button"
                >
                  回到本月
                </button>
                {selectedDate ? (
                  <button
                    className="transition hover:text-indigo-600"
                    onClick={() => setSelectedDate("")}
                    type="button"
                  >
                    清除日期
                  </button>
                ) : null}
              </div>
            </div>

          </nav>
        </aside>

        <main className="flex min-w-0 flex-1 flex-col">
          <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/90 px-4 py-4 backdrop-blur md:px-8">
            <div className="mx-auto flex max-w-5xl items-center gap-4">
              <button
                aria-label="打开标签菜单"
                className="inline-flex h-11 w-11 items-center justify-center rounded-xl border border-slate-200 text-slate-500 transition hover:bg-slate-50 md:hidden"
                onClick={() => setMobileSidebarOpen(true)}
                type="button"
              >
                <IconMenu />
              </button>

              <label className="group relative flex-1">
                <span className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-slate-400 transition group-focus-within:text-indigo-500">
                  <IconSearch />
                </span>
                <input
                  className="h-11 w-full rounded-2xl border border-slate-200 bg-slate-50 pl-11 pr-4 text-sm text-slate-700 outline-none transition placeholder:text-slate-400 focus:border-indigo-200 focus:bg-white focus:ring-4 focus:ring-indigo-100"
                  onChange={(event) => setSearchQuery(event.target.value)}
                  placeholder="搜索笔记或 #标签..."
                  value={searchQuery}
                />
              </label>

              <button
                className="hidden items-center gap-2 rounded-2xl bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition hover:bg-indigo-700 md:inline-flex"
                onClick={focusComposer}
                type="button"
              >
                <IconPlus />
                新建
              </button>

              <button
                className="hidden rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 md:inline-flex"
                onClick={onLogout}
                type="button"
              >
                退出
              </button>
            </div>
          </header>

          <section className="flex flex-1 flex-col overflow-hidden px-4 py-6 md:px-8 md:py-8">
            <div className="mx-auto flex min-h-0 w-full max-w-5xl flex-1 flex-col">
              {isExpandedComposer ? (
                <>
                  <button
                    aria-label={editingId ? "取消编辑" : "关闭新建笔记"}
                    className="fixed inset-0 z-40 bg-slate-950/35 backdrop-blur-[2px]"
                    onClick={editingId ? cancelEditing : closeFocusedComposer}
                    type="button"
                  />

                  <div
                    className="fixed inset-4 z-50 flex flex-col rounded-[32px] border border-slate-200 bg-white p-5 shadow-[0_24px_80px_rgba(15,23,42,0.18)] md:inset-8 md:p-6"
                    ref={composerRef}
                  >
                    <form className="flex h-full flex-col" onSubmit={handleSubmit}>
                      <div className="mb-3 flex items-center justify-between gap-3">
                        <div className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">
                          {editingId ? "编辑笔记" : "新建笔记"}
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            className="inline-flex items-center gap-2 rounded-full bg-slate-100 px-3 py-1.5 text-xs text-slate-600 transition hover:bg-slate-200"
                            onClick={editingId ? cancelEditing : closeFocusedComposer}
                            type="button"
                          >
                            <IconExpand />
                            {editingId ? "取消编辑" : "关闭"}
                          </button>
                        </div>
                      </div>
                      <textarea
                        className="min-h-[calc(100vh-16rem)] flex-1 resize-y border-none bg-transparent text-[15px] leading-7 text-slate-700 outline-none placeholder:text-slate-400"
                        name="content"
                        onChange={handleChange}
                        onKeyDown={handleComposerKeyDown}
                        placeholder="有什么新鲜事？试试写下 #工作 或 #灵感"
                        required
                        value={form.content}
                      />

                      <div className="mt-3 flex flex-col gap-3 border-t border-slate-100 pt-3 md:flex-row md:items-center md:justify-between">
                        <div className="flex flex-wrap items-center gap-3 text-sm text-slate-400">
                          <label className="inline-flex items-center gap-2 rounded-full bg-slate-50 px-3 py-1.5 text-slate-500">
                            <input
                              checked={form.pinned}
                              className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                              name="pinned"
                              onChange={handleChange}
                              type="checkbox"
                            />
                            置顶
                          </label>
                          <label className="inline-flex items-center gap-2 rounded-full bg-slate-50 px-3 py-1.5 text-slate-500">
                            <input
                              checked={form.isArchived}
                              className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                              name="isArchived"
                              onChange={handleChange}
                              type="checkbox"
                            />
                            归档
                          </label>
                          {editingId ? (
                            <button
                              className="text-sm text-slate-400 transition hover:text-slate-700"
                              onClick={cancelEditing}
                              type="button"
                            >
                              取消编辑
                            </button>
                          ) : null}
                        </div>

                        <button
                          className="inline-flex items-center justify-center rounded-xl bg-indigo-600 px-5 py-2 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
                          disabled={submitting}
                          type="submit"
                          title="Ctrl+Enter 快速提交"
                        >
                          {submitting ? "保存中..." : editingId ? "保存修改" : "保存"}
                        </button>
                      </div>
                    </form>
                  </div>
                </>
              ) : null}

              <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
                <div>
                  <div className="mt-2 flex flex-col gap-2">
                    <p className="text-sm text-slate-500">
                      {`${filteredNotes.length} 条结果`}
                    </p>
                    {activeFilters.length ? (
                      <div className="flex flex-wrap gap-2">
                        {activeFilters.map((filter) => (
                          <button
                            className="rounded-full bg-indigo-50 px-3 py-1.5 text-xs font-medium text-indigo-700 transition hover:bg-rose-50 hover:text-rose-600 hover:line-through"
                            key={filter.key}
                            onClick={filter.onClear}
                            type="button"
                          >
                            {filter.label}
                          </button>
                        ))}
                      </div>
                    ) : null}
                  </div>
                </div>

                <div className="flex flex-wrap items-center gap-2 text-xs text-slate-400">
                  {networkStatus ? (
                    <span
                      className={[
                        "rounded-full px-3 py-1.5 font-medium",
                        networkStatus === "在线"
                          ? "bg-emerald-50 text-emerald-600"
                          : "bg-slate-100 text-slate-500",
                      ].join(" ")}
                    >
                      {networkStatus}
                    </span>
                  ) : null}
                  <button
                    className="rounded-full bg-white px-3 py-1.5 transition hover:text-slate-600"
                    onClick={() => void loadNotes()}
                    type="button"
                  >
                    {refreshing ? "刷新中..." : "刷新"}
                  </button>
                </div>
              </div>

              {error ? (
                <div className="mb-6 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
                  {error}
                </div>
              ) : null}

              {loading ? (
                <div className="rounded-3xl border border-dashed border-slate-200 bg-white px-4 py-16 text-center text-sm text-slate-500">
                  正在加载笔记...
                </div>
              ) : null}

              {!loading && filteredNotes.length === 0 ? (
                <div className="rounded-3xl border border-dashed border-slate-200 bg-white px-4 py-16 text-center text-sm text-slate-500">
                  {notes.length === 0
                    ? "还没有笔记，先写下第一条。"
                    : selectedDate || selectedTag !== "all" || searchQuery
                      ? "当前筛选条件下没有笔记。"
                      : "还没有笔记，先写下第一条。"}
                </div>
              ) : null}

              {!loading && filteredNotes.length > 0 ? (
                <VirtualizedNoteList
                  notes={filteredNotes}
                  onDelete={handleDelete}
                  onEdit={handleEdit}
                  onSelectTag={handleSelectTag}
                />
              ) : null}
            </div>
          </section>
        </main>
      </div>

      {yearPickerOpen ? (
        <div className="fixed inset-0 z-[120] bg-slate-950/35 backdrop-blur-sm">
          <div className="flex h-full w-full items-stretch justify-center p-3 sm:p-5">
            <div className="flex h-full w-full max-w-7xl flex-col overflow-hidden rounded-[2rem] bg-white shadow-2xl shadow-slate-900/10">
              <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4 sm:px-7">
                <div>
                  <div className="text-lg font-semibold text-slate-900">
                    {yearPickerYear} 年全年日历
                  </div>
                  <div className="text-sm text-slate-500">
                    选择月份或具体日期，查看当天是否有笔记
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    className="rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-500 transition hover:bg-slate-50 hover:text-slate-700"
                    onClick={() => setYearPickerYear((current) => current - 1)}
                    type="button"
                  >
                    ←
                  </button>
                  <button
                    className="rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-500 transition hover:bg-slate-50 hover:text-slate-700"
                    onClick={() => setYearPickerYear((current) => current + 1)}
                    type="button"
                  >
                    →
                  </button>
                  <button
                    className="rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-500 transition hover:bg-slate-50 hover:text-slate-700"
                    onClick={() => setYearPickerOpen(false)}
                    type="button"
                  >
                    关闭
                  </button>
                </div>
              </div>

              <div className="flex-1 overflow-y-auto px-4 py-4 sm:px-6 sm:py-6">
                <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                  {yearPickerMonths.map((monthKey) => {
                    const { monthLabel } = getMonthParts(monthKey);
                    const monthDays = buildCalendarDays(monthKey);
                    const isActiveMonth = calendarMonth === monthKey;
                    const monthNoteCount = noteMonthCounts.get(monthKey) || 0;

                    return (
                      <div
                        className={[
                          "rounded-2xl border p-4",
                          isActiveMonth
                            ? "border-indigo-200 bg-indigo-50/60"
                            : "border-slate-200 bg-slate-50/70",
                        ].join(" ")}
                        key={monthKey}
                      >
                        <div className="mb-3 flex items-center justify-between">
                          <button
                            className={[
                              "text-left text-sm font-semibold transition",
                              isActiveMonth
                                ? "text-indigo-700"
                                : "text-slate-700 hover:text-slate-900",
                            ].join(" ")}
                            onClick={() => setCalendarMonth(monthKey)}
                            type="button"
                          >
                            {monthLabel}
                          </button>
                          <span className="text-[11px] text-slate-400">
                            {monthNoteCount > 0 ? `${monthNoteCount} 条笔记` : "无笔记"}
                          </span>
                        </div>

                        <div className="mb-2 grid grid-cols-7 gap-1 text-center text-[10px] text-slate-400">
                          {weekdayLabels.map((day) => (
                            <span key={`${monthKey}-${day}`}>{day}</span>
                          ))}
                        </div>

                        <div className="grid grid-cols-7 gap-1 text-center text-[11px]">
                          {monthDays.map((dateKey, index) => {
                            if (!dateKey) {
                              return <span className="h-8" key={`${monthKey}-empty-${index}`} />;
                            }

                            const dayNumber = Number(dateKey.slice(8, 10));
                            const noteCount = noteDates.get(dateKey) || 0;
                            const hasNotes = noteCount > 0;
                            const isSelected = selectedDate === dateKey;
                            const isToday = todayKey === dateKey;

                            return (
                              <button
                                className={[
                                  "relative h-8 rounded-lg transition",
                                  isSelected
                                    ? "bg-indigo-600 font-semibold text-white"
                                    : hasNotes
                                      ? "bg-indigo-100 font-medium text-indigo-700 hover:bg-indigo-200"
                                      : "text-slate-500 hover:bg-white",
                                  isToday && !isSelected ? "ring-1 ring-inset ring-indigo-300" : "",
                                ].join(" ")}
                                key={dateKey}
                                onClick={() => {
                                  setCalendarMonth(monthKey);
                                  setSelectedDate(dateKey);
                                  setYearPickerOpen(false);
                                }}
                                title={
                                  hasNotes
                                    ? `${dateKey}，${noteCount} 条笔记`
                                    : `${dateKey}，没有笔记`
                                }
                                type="button"
                              >
                                {dayNumber}
                                {hasNotes && !isSelected ? (
                                  <span className="absolute bottom-1 left-1/2 h-1 w-1 -translate-x-1/2 rounded-full bg-indigo-500" />
                                ) : null}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      <button
        className="fixed bottom-6 right-6 inline-flex h-14 w-14 items-center justify-center rounded-full bg-indigo-600 text-white shadow-lg transition hover:bg-indigo-700 md:hidden"
        onClick={focusComposer}
        type="button"
      >
        <IconPlus />
      </button>

    </div>
  );
}

export default App;
