const THEMES = ["light", "dark"];

function getPreferredTheme() {
    const storedTheme = localStorage.getItem("theme");
    if (storedTheme !== null && THEMES.includes(storedTheme)) return storedTheme;
    if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
        return "dark";
    }
    return "light";
}

function setPreferredTheme(theme) {
    document.documentElement.className = theme;
    localStorage.setItem("theme", theme);
}

setPreferredTheme(getPreferredTheme());
window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", event => {
    const newTheme = event.matches ? "dark" : "light";
    setPreferredTheme(newTheme);
});
document.addEventListener("DOMContentLoaded", event => {
    const themeToggleButton = document.getElementById("themeToggleButton");
    themeToggleButton.onclick = clickEvent => {
        const currentTheme = getPreferredTheme();
        const idx = THEMES.indexOf(currentTheme);
        const nextIdx = idx === THEMES.length - 1 ? 0 : idx + 1;
        setPreferredTheme(THEMES[nextIdx]);
    };
});