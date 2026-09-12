#!/usr/bin/env python3
"""
Markdown Reader — a small GTK4 / libadwaita Markdown viewer.

Renders a Markdown file's *structure* (headings, paragraphs, lists,
code blocks, block quotes, tables, ...) as native GTK widgets, with a
clickable outline sidebar. No colors are hard-coded anywhere: every
widget just inherits its palette from the active GTK4 theme, so the
app follows whatever theme/accent colors your desktop provides (e.g.
a matugen/Noctalia-generated ~/.config/gtk-4.0/gtk.css).
"""

from __future__ import annotations

import sys
from pathlib import Path

try:
    import gi

    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    from gi.repository import Adw, Gdk, Gio, GLib, Gtk, Pango
except (ImportError, ValueError) as exc:  # pragma: no cover
    sys.stderr.write(
        "This app needs GTK4 + libadwaita and their Python bindings.\n"
        "  Arch/Manjaro:    sudo pacman -S python-gobject gtk4 libadwaita\n"
        "  Fedora:          sudo dnf install python3-gobject gtk4 libadwaita\n"
        "  Debian/Ubuntu:   sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1\n"
        f"\nDetails: {exc}\n"
    )
    sys.exit(1)

try:
    import mistune
except ImportError:  # pragma: no cover
    mistune = None


APP_ID = "com.example.mdreader"

# libadwaita ships these as ready-made typography style classes.
HEADING_STYLE_CLASSES = {
    1: "title-1",
    2: "title-2",
    3: "title-3",
    4: "title-4",
}

# The only custom CSS in the whole app. It intentionally references the
# theme's own "@borders" color instead of a literal color, so it still
# adapts to whatever GTK4 theme (Adwaita, a Noctalia/matugen-generated
# palette, etc.) is active.
CUSTOM_CSS = """
.blockquote {
  border-left: 3px solid @borders;
  padding-left: 12px;
  margin-left: 2px;
}
"""


# --------------------------------------------------------------------------
# Markdown parsing helpers
# --------------------------------------------------------------------------

def build_markdown_parser() -> "mistune.Markdown":
    """Create a mistune parser that returns a block-level AST (list of dicts)."""
    return mistune.create_markdown(
        renderer=None,
        plugins=["table", "strikethrough", "task_lists", "url"],
    )


def escape(text: str) -> str:
    """Escape text for safe use inside Pango markup."""
    return GLib.markup_escape_text(text)


def inline_markup(tokens: list[dict]) -> str:
    """Convert a list of mistune inline tokens into Pango markup."""
    parts: list[str] = []
    for tok in tokens or []:
        kind = tok.get("type")
        if kind == "text":
            parts.append(escape(tok.get("raw", "")))
        elif kind == "emphasis":
            parts.append(f"<i>{inline_markup(tok.get('children', []))}</i>")
        elif kind == "strong":
            parts.append(f"<b>{inline_markup(tok.get('children', []))}</b>")
        elif kind == "strikethrough":
            parts.append(f"<s>{inline_markup(tok.get('children', []))}</s>")
        elif kind == "codespan":
            parts.append(f"<tt>{escape(tok.get('raw', ''))}</tt>")
        elif kind in ("linebreak", "softbreak"):
            parts.append("\n")
        elif kind == "link":
            url = escape((tok.get("attrs") or {}).get("url", ""))
            label = inline_markup(tok.get("children", [])) or url
            parts.append(f'<a href="{url}">{label}</a>')
        elif kind == "image":
            alt = inline_markup(tok.get("children", [])) or escape(
                (tok.get("attrs") or {}).get("url", "image")
            )
            parts.append(f"[{alt}]")
        elif tok.get("children"):
            parts.append(inline_markup(tok["children"]))
        elif "raw" in tok:
            parts.append(escape(tok["raw"]))
    return "".join(parts)


def plain_text(tokens: list[dict]) -> str:
    """Flatten inline tokens down to plain text (used for outline labels)."""
    parts: list[str] = []
    for tok in tokens or []:
        if tok.get("type") in ("text", "codespan"):
            parts.append(tok.get("raw", ""))
        elif tok.get("children"):
            parts.append(plain_text(tok["children"]))
    return "".join(parts).strip()


class MarkdownRenderer:
    """Turns a mistune AST into a tree of GTK widgets, plus a heading outline.

    Unrecognised block types degrade gracefully to a plain label (or are
    skipped) instead of raising, since exact AST shapes can vary slightly
    across mistune versions/plugins.
    """

    def __init__(self) -> None:
        self.outline: list[tuple[int, str, Gtk.Widget]] = []

    def render_document(self, tokens: list[dict]) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(24)
        box.set_margin_bottom(24)
        box.set_margin_start(24)
        box.set_margin_end(24)
        for token in tokens:
            widget = self.render_block(token)
            if widget is not None:
                box.append(widget)
        return box

    def render_block(self, token: dict) -> Gtk.Widget | None:
        kind = token.get("type", "")
        method = getattr(self, f"_render_{kind}", None)
        if method is not None:
            return method(token)
        raw = token.get("raw")
        if raw:
            return Gtk.Label(label=raw, wrap=True, xalign=0)
        return None

    # -- block renderers ---------------------------------------------------

    def _render_heading(self, token: dict) -> Gtk.Widget:
        level = (token.get("attrs") or {}).get("level", 1)
        children = token.get("children", [])
        label = Gtk.Label(xalign=0, wrap=True)
        label.set_markup(inline_markup(children))
        label.add_css_class(HEADING_STYLE_CLASSES.get(level, "heading"))
        label.set_margin_top(10 if level == 1 else 6)
        self.outline.append((level, plain_text(children), label))
        return label

    def _render_paragraph(self, token: dict) -> Gtk.Widget:
        label = Gtk.Label(xalign=0, wrap=True)
        label.set_wrap_mode(Pango.WrapMode.WORD_CHAR)
        label.set_markup(inline_markup(token.get("children", [])))
        return label

    # Tight list items use "block_text" instead of "paragraph" — same shape.
    _render_block_text = _render_paragraph

    def _render_block_code(self, token: dict) -> Gtk.Widget:
        code = token.get("raw", "").rstrip("\n")
        info = (token.get("attrs") or {}).get("info", "") or ""

        text_view = Gtk.TextView()
        text_view.set_editable(False)
        text_view.set_cursor_visible(False)
        text_view.set_monospace(True)
        text_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        text_view.set_top_margin(8)
        text_view.set_bottom_margin(8)
        text_view.set_left_margin(10)
        text_view.set_right_margin(10)
        text_view.get_buffer().set_text(code)

        frame = Gtk.Frame()
        frame.add_css_class("card")
        frame.set_child(text_view)

        if not info:
            return frame

        wrapper = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        lang_label = Gtk.Label(label=info, xalign=0)
        lang_label.add_css_class("dim-label")
        lang_label.add_css_class("caption")
        wrapper.append(lang_label)
        wrapper.append(frame)
        return wrapper

    def _render_block_quote(self, token: dict) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.add_css_class("blockquote")
        for child in token.get("children", []):
            widget = self.render_block(child)
            if widget is not None:
                box.append(widget)
        return box

    def _render_list(self, token: dict) -> Gtk.Widget:
        attrs = token.get("attrs") or {}
        ordered = bool(attrs.get("ordered"))
        start = attrs.get("start") or 1

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        for index, item in enumerate(token.get("children", [])):
            item_attrs = item.get("attrs") or {}
            if "checked" in item_attrs:
                marker_text = "\u2611" if item_attrs["checked"] else "\u2610"
            elif ordered:
                marker_text = f"{start + index}."
            else:
                marker_text = "\u2022"

            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            marker = Gtk.Label(label=marker_text, xalign=0, valign=Gtk.Align.START)
            marker.add_css_class("dim-label")

            content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            content.set_hexpand(True)
            for child in item.get("children", []):
                widget = self.render_block(child)
                if widget is not None:
                    content.append(widget)

            row.append(marker)
            row.append(content)
            box.append(row)
        return box

    def _render_thematic_break(self, _token: dict) -> Gtk.Widget:
        sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        sep.set_margin_top(6)
        sep.set_margin_bottom(6)
        return sep

    def _render_block_html(self, token: dict) -> Gtk.Widget | None:
        raw = (token.get("raw") or "").strip()
        if not raw:
            return None
        label = Gtk.Label(label=raw, xalign=0, wrap=True)
        label.add_css_class("dim-label")
        label.add_css_class("monospace")
        return label

    def _render_table(self, token: dict) -> Gtk.Widget:
        grid = Gtk.Grid(column_spacing=16, row_spacing=6)
        grid.add_css_class("card")
        grid.set_margin_top(4)
        grid.set_margin_bottom(8)
        grid.set_margin_start(4)
        grid.set_margin_end(4)

        row_index = 0
        for section in token.get("children", []):
            if section.get("type") == "table_head":
                for col_index, cell in enumerate(section.get("children", [])):
                    grid.attach(self._table_cell(cell, header=True), col_index, row_index, 1, 1)
                row_index += 1
            elif section.get("type") == "table_body":
                for row in section.get("children", []):
                    for col_index, cell in enumerate(row.get("children", [])):
                        grid.attach(self._table_cell(cell, header=False), col_index, row_index, 1, 1)
                    row_index += 1
        return grid

    def _table_cell(self, cell: dict, header: bool) -> Gtk.Widget:
        markup = inline_markup(cell.get("children", []))
        label = Gtk.Label(xalign=0)
        label.set_markup(f"<b>{markup}</b>" if header else markup)
        align = (cell.get("attrs") or {}).get("align")
        if align == "center":
            label.set_xalign(0.5)
        elif align == "right":
            label.set_xalign(1.0)
        return label


# --------------------------------------------------------------------------
# UI
# --------------------------------------------------------------------------

def _install_css() -> None:
    provider = Gtk.CssProvider()
    provider.load_from_data(CUSTOM_CSS.encode("utf-8"))
    display = Gdk.Display.get_default()
    if display is not None:
        Gtk.StyleContext.add_provider_for_display(
            display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )


class MarkdownReaderWindow(Adw.ApplicationWindow):
    """The single window of the app: an empty state, or the document view."""

    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self.set_title("Markdown Reader")
        self.set_default_size(880, 640)

        self._parser = build_markdown_parser()
        self._current_path: Path | None = None

        self._build_ui()

    # -- UI construction -----------------------------------------------

    def _build_ui(self) -> None:
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        root.append(self._build_header())

        self._toast_overlay = Adw.ToastOverlay()
        self._toast_overlay.set_vexpand(True)

        self._stack = Gtk.Stack()
        self._stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self._stack.add_named(self._build_empty_page(), "empty")
        self._stack.add_named(self._build_document_page(), "document")
        self._toast_overlay.set_child(self._stack)

        root.append(self._toast_overlay)
        self.set_content(root)

    def _build_header(self) -> Adw.HeaderBar:
        header = Adw.HeaderBar()

        self._title_widget = Adw.WindowTitle(title="Markdown Reader", subtitle="")
        header.set_title_widget(self._title_widget)

        open_button = Gtk.Button(icon_name="document-open-symbolic")
        open_button.set_tooltip_text("Open File (Ctrl+O)")
        open_button.connect("clicked", lambda *_: self.open_file_dialog())
        header.pack_start(open_button)

        self._sidebar_toggle = Gtk.ToggleButton(icon_name="view-sidebar-symbolic")
        self._sidebar_toggle.set_tooltip_text("Toggle Outline")
        self._sidebar_toggle.set_active(True)
        self._sidebar_toggle.set_sensitive(False)
        self._sidebar_toggle.connect("toggled", self._on_toggle_sidebar)
        header.pack_end(self._sidebar_toggle)

        return header

    def _build_empty_page(self) -> Gtk.Widget:
        status_page = Adw.StatusPage()
        status_page.set_icon_name("text-x-generic-symbolic")
        status_page.set_title("No Document Open")
        status_page.set_description("Choose a Markdown (.md) file to view its contents.")

        open_button = Gtk.Button(label="Open File\u2026")
        open_button.add_css_class("suggested-action")
        open_button.add_css_class("pill")
        open_button.set_halign(Gtk.Align.CENTER)
        open_button.connect("clicked", lambda *_: self.open_file_dialog())
        status_page.set_child(open_button)

        return status_page

    def _build_document_page(self) -> Gtk.Widget:
        paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        paned.set_position(240)
        paned.set_resize_start_child(False)
        paned.set_shrink_start_child(False)

        self._outline_scroller = Gtk.ScrolledWindow()
        self._outline_scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self._outline_scroller.set_size_request(200, -1)
        self._outline_listbox = Gtk.ListBox()
        self._outline_listbox.add_css_class("navigation-sidebar")
        self._outline_listbox.connect("row-activated", self._on_outline_row_activated)
        self._outline_scroller.set_child(self._outline_listbox)
        paned.set_start_child(self._outline_scroller)

        self._content_scroller = Gtk.ScrolledWindow()
        self._content_scroller.set_hexpand(True)
        self._content_scroller.set_vexpand(True)
        self._content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self._content_scroller.set_child(self._content_box)
        paned.set_end_child(self._content_scroller)

        return paned

    # -- actions ----------------------------------------------------------

    def open_file_dialog(self) -> None:
        dialog = Gtk.FileDialog(title="Open Markdown File")

        md_filter = Gtk.FileFilter(name="Markdown files")
        md_filter.add_pattern("*.md")
        md_filter.add_pattern("*.markdown")
        md_filter.add_mime_type("text/markdown")

        all_filter = Gtk.FileFilter(name="All files")
        all_filter.add_pattern("*")

        filters = Gio.ListStore.new(Gtk.FileFilter)
        filters.append(md_filter)
        filters.append(all_filter)
        dialog.set_filters(filters)
        dialog.set_default_filter(md_filter)

        dialog.open(self, None, self._on_file_dialog_done)

    def _on_file_dialog_done(self, dialog: Gtk.FileDialog, result: Gio.AsyncResult) -> None:
        try:
            gfile = dialog.open_finish(result)
        except GLib.Error:
            # Most commonly just means the user cancelled the dialog.
            return
        if gfile is None:
            return
        path = gfile.get_path()
        if path:
            self.load_file(Path(path))

    def load_file(self, path: Path) -> None:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as err:
            self._notify_error(f"Couldn't read {path.name}: {err}")
            return

        try:
            tokens = self._parser(text)
            renderer = MarkdownRenderer()
            content_widget = renderer.render_document(tokens)
        except Exception as err:  # noqa: BLE001 - never let a parsing quirk crash the app
            self._notify_error(f"Couldn't parse {path.name}: {err}")
            return

        self._replace_child(self._content_box, content_widget)

        while (row := self._outline_listbox.get_first_child()) is not None:
            self._outline_listbox.remove(row)
        for level, heading_text, widget in renderer.outline:
            self._outline_listbox.append(self._make_outline_row(level, heading_text, widget))

        has_outline = bool(renderer.outline)
        self._outline_scroller.set_visible(has_outline)
        self._sidebar_toggle.set_sensitive(has_outline)
        self._sidebar_toggle.set_active(has_outline)

        self._title_widget.set_title(path.name)
        self._title_widget.set_subtitle(str(path.parent))
        self._current_path = path

        self._stack.set_visible_child_name("document")
        self._content_scroller.get_vadjustment().set_value(0)

    # -- small helpers ------------------------------------------------------

    @staticmethod
    def _replace_child(container: Gtk.Box, new_child: Gtk.Widget) -> None:
        while (child := container.get_first_child()) is not None:
            container.remove(child)
        container.append(new_child)

    def _make_outline_row(self, level: int, text: str, widget: Gtk.Widget) -> Gtk.ListBoxRow:
        row = Gtk.ListBoxRow()
        label = Gtk.Label(label=text or "Untitled", xalign=0, wrap=True)
        label.set_margin_top(6)
        label.set_margin_bottom(6)
        label.set_margin_start(12 + max(level - 1, 0) * 14)
        label.set_margin_end(12)
        label.add_css_class("heading" if level <= 2 else "dim-label")
        row.set_child(label)
        row.target_widget = widget  # plain Python attribute, fine on a GObject wrapper
        return row

    def _on_outline_row_activated(self, _listbox: Gtk.ListBox, row: Gtk.ListBoxRow) -> None:
        widget = getattr(row, "target_widget", None)
        if widget is not None:
            self._scroll_to_widget(widget)

    def _scroll_to_widget(self, widget: Gtk.Widget) -> None:
        ok, bounds = widget.compute_bounds(self._content_box)
        if ok:
            self._content_scroller.get_vadjustment().set_value(bounds.get_y())

    def _on_toggle_sidebar(self, button: Gtk.ToggleButton) -> None:
        self._outline_scroller.set_visible(button.get_active())

    def _notify_error(self, message: str) -> None:
        self._toast_overlay.add_toast(Adw.Toast(title=message, timeout=5))


class MarkdownReaderApp(Adw.Application):
    def __init__(self) -> None:
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.HANDLES_OPEN)

    def do_startup(self) -> None:
        Adw.Application.do_startup(self)
        _install_css()
        self._add_actions()

    def _add_actions(self) -> None:
        open_action = Gio.SimpleAction.new("open", None)
        open_action.connect("activate", lambda *_: self._trigger_open())
        self.add_action(open_action)
        self.set_accels_for_action("app.open", ["<primary>o"])

        quit_action = Gio.SimpleAction.new("quit", None)
        quit_action.connect("activate", lambda *_: self.quit())
        self.add_action(quit_action)
        self.set_accels_for_action("app.quit", ["<primary>q"])

    def _trigger_open(self) -> None:
        win = self.props.active_window
        if win is not None:
            win.open_file_dialog()

    def do_activate(self) -> None:
        win = self.props.active_window
        if win is None:
            win = MarkdownReaderWindow(application=self)
        win.present()

    def do_open(self, files, _n_files: int, _hint: str) -> None:
        win = self.props.active_window
        if win is None:
            win = MarkdownReaderWindow(application=self)
        win.present()
        if files:
            path = files[0].get_path()
            if path:
                win.load_file(Path(path))


def main() -> int:
    if mistune is None:
        print("Missing dependency: install it with `pip install mistune`", file=sys.stderr)
        return 1
    app = MarkdownReaderApp()
    return app.run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
