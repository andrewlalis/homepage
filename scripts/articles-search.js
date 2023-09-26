const searchInput = document.getElementsByTagName("input")[0];
const articlesContainer = document.getElementById("articles-container");
const resetSearchButton = document.getElementById("reset-search-button");

function setAllArticlesVisible() {
    for (let i = 0; i < articlesContainer.children.length; i++) {
        articlesContainer.children[i].style.display = "block";
    }
}

function articleCardMatches(card, s) {
    const title = card.getElementsByTagName("h3")[0].innerText.trim().toUpperCase();
    const topicSpans = [].slice.call(card.getElementsByTagName("span"));
    const topics = topicSpans.map(span => span.innerText.trim().toUpperCase());
    for (let i = 0; i < topics.length; i++) {
        if (topics[i].includes(s)) return true;
    }
    return title.includes(s);
}

function doArticleSearch() {
    let searchValue = searchInput.value;
    if (searchValue === null || searchValue.length < 1 || searchValue.trim().length < 1) {
        setAllArticlesVisible();
        resetSearchButton.style.display = "none";
        return;
    }
    searchValue = searchValue.trim().toUpperCase();
    for (let i = 0; i < articlesContainer.children.length; i++) {
        const card = articlesContainer.children[i];
        const displayStyle = articleCardMatches(card, searchValue) ? "block" : "none";
        card.style.display = displayStyle;
    }
    resetSearchButton.style.display = "inline-block";
}

function resetArticleSearch() {
    searchInput.value = "";
    setAllArticlesVisible();
    resetSearchButton.style.display = "none";
}

searchInput.addEventListener("keyup", doArticleSearch);
resetSearchButton.addEventListener("click", resetArticleSearch);
